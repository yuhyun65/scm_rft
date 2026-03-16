package kr.co.computermate.scmrft.gateway;

import static org.springframework.cloud.gateway.support.RouteMetadataUtils.CONNECT_TIMEOUT_ATTR;
import static org.springframework.cloud.gateway.support.RouteMetadataUtils.RESPONSE_TIMEOUT_ATTR;

import java.time.Duration;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;
import kr.co.computermate.scmrft.gateway.auth.AuthVerificationClient;
import kr.co.computermate.scmrft.gateway.auth.TokenVerificationResult;
import kr.co.computermate.scmrft.gateway.policy.GatewayPolicyDocument;
import kr.co.computermate.scmrft.gateway.policy.GatewayPolicyLoader;
import kr.co.computermate.scmrft.gateway.policy.GatewayRoutePolicyResolver;
import kr.co.computermate.scmrft.gateway.policy.GatewayRoutePolicyResolver.ResolvedRoutePolicy;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.ApplicationContext;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpRequest;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import reactor.core.publisher.Mono;

@Configuration
public class GatewayRouteConfiguration {
  private static final Logger log = LoggerFactory.getLogger(GatewayRouteConfiguration.class);

  @Bean
  public GatewayPolicyDocument gatewayPolicy(GatewayPolicyLoader loader) {
    return loader.load();
  }

  @Bean
  public KeyResolver gatewayKeyResolver() {
    return exchange -> {
      String clientId = exchange.getRequest().getHeaders().getFirst("X-Client-Id");
      if (clientId == null || clientId.isBlank()) {
        clientId = "anonymous";
      }
      return Mono.just(clientId);
    };
  }

  @Bean
  public RouteLocator gatewayRouteLocator(
      RouteLocatorBuilder builder,
      GatewayPolicyDocument policy,
      GatewayRoutePolicyResolver resolver,
      KeyResolver keyResolver,
      AuthVerificationClient authVerificationClient,
      ApplicationContext applicationContext
  ) {
    var routes = builder.routes();

    for (ResolvedRoutePolicy route : resolver.resolve(policy)) {
      log.info("Resolved gateway route id={} path={} target={} authRequired={} rateLimitRps={}",
          route.id(), route.path(), route.target(), route.authRequired(), route.rateLimitRps());
      routes.route(route.id(), predicate -> {
        var routePredicate = predicate.path(route.path());
        if (!route.methods().isEmpty()) {
          routePredicate = routePredicate.and().method(route.methods().toArray(String[]::new));
        }

        return routePredicate
            .filters(filters -> {
              if (route.rateLimitRps() > 0) {
                filters.requestRateLimiter(config ->
                    config.setRateLimiter(buildRedisRateLimiter(route.rateLimitRps(), applicationContext))
                        .setKeyResolver(keyResolver)
                );
              }

              if (route.retry().isEnabled() && route.retry().getAttempts() > 0) {
                filters.retry(config -> config.setRetries(route.retry().getAttempts()));
              }

              if (route.circuitBreaker().isEnabled()) {
                filters.circuitBreaker(config -> config.setName("cb-" + route.id()));
              }

              filters.filter(authVerificationFilter(route.authRequired(), authVerificationClient));
              filters.filter(writeProtectionFilter(route.writeProtection(), policy.getCutoverSwitches().isBlockLegacyWrites()));
              filters.setResponseHeader("X-SCM-Gateway-Route", route.id());
              filters.setResponseHeader("X-SCM-Policy-Id", policy.getName());
              return filters;
            })
            .metadata(CONNECT_TIMEOUT_ATTR, route.connectTimeoutMs())
            .metadata(RESPONSE_TIMEOUT_ATTR, Duration.ofMillis(route.requestTimeoutMs()))
            .uri(route.target());
      });
    }

    return routes.build();
  }

  @Bean
  public GlobalFilter emergencyStopFilter(
      GatewayPolicyDocument policy,
      @Value("${gateway.cutover.emergency-stop.enabled:false}") boolean emergencyStopEnabled,
      @Value("${gateway.cutover.emergency-stop.http-status:0}") int configuredStatus
  ) {
    int statusCode = configuredStatus > 0
        ? configuredStatus
        : policy.getCutoverSwitches().getEmergencyStop().getHttpStatus();

    return (exchange, chain) -> {
      if (!emergencyStopEnabled) {
        return chain.filter(exchange);
      }
      HttpStatus status = HttpStatus.resolve(statusCode);
      if (status == null) {
        status = HttpStatus.SERVICE_UNAVAILABLE;
      }
      ServerHttpResponse response = exchange.getResponse();
      response.setStatusCode(status);
      return response.setComplete();
    };
  }

  static RedisRateLimiter buildRedisRateLimiter(int replenishRate, ApplicationContext applicationContext) {
    int burstCapacity = Math.max(replenishRate, replenishRate * 2);
    RedisRateLimiter rateLimiter = new RedisRateLimiter(replenishRate, burstCapacity);
    rateLimiter.setApplicationContext(applicationContext);
    return rateLimiter;
  }

  private GatewayFilter writeProtectionFilter(
      GatewayPolicyDocument.WriteProtection writeProtection,
      boolean blockLegacyWrites
  ) {
    if (writeProtection == null || !writeProtection.isEnabledDuringCutover()) {
      return (exchange, chain) -> chain.filter(exchange);
    }

    Set<HttpMethod> blockedMethods = writeProtection.getMethods().stream()
        .map(this::toHttpMethodOrNull)
        .filter(method -> method != null)
        .collect(Collectors.toSet());

    return (exchange, chain) -> {
      HttpMethod method = exchange.getRequest().getMethod();
      if (blockLegacyWrites && method != null && blockedMethods.contains(method)) {
        exchange.getResponse().setStatusCode(HttpStatus.SERVICE_UNAVAILABLE);
        return exchange.getResponse().setComplete();
      }
      return chain.filter(exchange);
    };
  }

  private GatewayFilter authVerificationFilter(
      boolean authRequired,
      AuthVerificationClient authVerificationClient
  ) {
    if (!authRequired) {
      return (exchange, chain) -> chain.filter(exchange);
    }

    return (exchange, chain) -> {
      if (HttpMethod.OPTIONS.equals(exchange.getRequest().getMethod())) {
        return chain.filter(exchange);
      }

      String bearerToken = extractBearerToken(exchange.getRequest().getHeaders().getFirst(HttpHeaders.AUTHORIZATION));
      if (bearerToken == null) {
        exchange.getResponse().setStatusCode(HttpStatus.UNAUTHORIZED);
        return exchange.getResponse().setComplete();
      }

      return authVerificationClient.verify(bearerToken)
          .flatMap(result -> {
            if (result.status() == TokenVerificationResult.VerificationStatus.ACTIVE) {
              ServerHttpRequest.Builder requestBuilder = exchange.getRequest().mutate();
              if (result.subject() != null && !result.subject().isBlank()) {
                requestBuilder.header("X-Auth-Subject", result.subject());
              }
              if (result.roles() != null && !result.roles().isEmpty()) {
                requestBuilder.header("X-Auth-Roles", String.join(",", result.roles()));
              }
              return chain.filter(exchange.mutate().request(requestBuilder.build()).build());
            }

            HttpStatus status = result.status() == TokenVerificationResult.VerificationStatus.UNAVAILABLE
                ? HttpStatus.SERVICE_UNAVAILABLE
                : HttpStatus.UNAUTHORIZED;
            exchange.getResponse().setStatusCode(status);
            return exchange.getResponse().setComplete();
          });
    };
  }

  private String extractBearerToken(String authorizationHeader) {
    if (authorizationHeader == null || authorizationHeader.isBlank()) {
      return null;
    }
    if (!authorizationHeader.toLowerCase(Locale.ROOT).startsWith("bearer ")) {
      return null;
    }
    String token = authorizationHeader.substring(7).trim();
    return token.isEmpty() ? null : token;
  }

  private HttpMethod toHttpMethodOrNull(String method) {
    if (method == null || method.isBlank()) {
      return null;
    }
    try {
      return HttpMethod.valueOf(method.toUpperCase(Locale.ROOT));
    }
    catch (IllegalArgumentException ignored) {
      return null;
    }
  }
}
