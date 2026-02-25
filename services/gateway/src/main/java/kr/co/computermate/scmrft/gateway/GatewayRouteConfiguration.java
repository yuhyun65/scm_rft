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
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.gateway.filter.GatewayFilter;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.cloud.gateway.filter.ratelimit.RedisRateLimiter;
import org.springframework.cloud.gateway.route.RouteLocator;
import org.springframework.cloud.gateway.route.builder.RouteLocatorBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.server.reactive.ServerHttpResponse;
import org.springframework.http.server.reactive.ServerHttpRequest;
import reactor.core.publisher.Mono;

@Configuration
public class GatewayRouteConfiguration {
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
  public RedisRateLimiter globalRedisRateLimiter(GatewayPolicyDocument policy) {
    int replenishRate = policy.getTrafficControl().getGlobalRateLimit().getRequestsPerSecond();
    int burstCapacity = policy.getTrafficControl().getGlobalRateLimit().getBurstCapacity();
    if (replenishRate <= 0) {
      replenishRate = 1;
    }
    if (burstCapacity <= 0) {
      burstCapacity = replenishRate;
    }
    return new RedisRateLimiter(replenishRate, burstCapacity);
  }

  @Bean
  public RouteLocator gatewayRouteLocator(
      RouteLocatorBuilder builder,
      GatewayPolicyDocument policy,
      RedisRateLimiter rateLimiter,
      KeyResolver keyResolver,
      AuthVerificationClient authVerificationClient
  ) {
    var routes = builder.routes();
    int connectTimeout = policy.getDefaults().getConnectTimeoutMs();
    Duration responseTimeout = Duration.ofMillis(policy.getDefaults().getRequestTimeoutMs());
    int retries = Math.max(0, policy.getDefaults().getRetry().getAttempts());

    for (GatewayPolicyDocument.RouteRule route : policy.getRoutes()) {
      routes.route(route.getId(), predicate ->
          predicate.path(route.getPath())
              .filters(filters -> {
                filters.requestRateLimiter(config ->
                    config.setRateLimiter(rateLimiter).setKeyResolver(keyResolver)
                );

                if (policy.getDefaults().getRetry().isEnabled() && retries > 0) {
                  filters.retry(config -> config.setRetries(retries));
                }

                filters.filter(authVerificationFilter(route.getId(), authVerificationClient));
                filters.filter(writeProtectionFilter(route, policy.getCutoverSwitches().isBlockLegacyWrites()));
                filters.setResponseHeader("X-SCM-Gateway-Route", route.getId());
                return filters;
              })
              .metadata(CONNECT_TIMEOUT_ATTR, connectTimeout)
              .metadata(RESPONSE_TIMEOUT_ATTR, responseTimeout)
              .uri(route.getTarget())
      );
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

  private GatewayFilter writeProtectionFilter(GatewayPolicyDocument.RouteRule route, boolean blockLegacyWrites) {
    if (route.getWriteProtection() == null || !route.getWriteProtection().isEnabledDuringCutover()) {
      return (exchange, chain) -> chain.filter(exchange);
    }

    Set<HttpMethod> blockedMethods = route.getWriteProtection().getMethods().stream()
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
      String routeId,
      AuthVerificationClient authVerificationClient
  ) {
    if (!requiresAuthentication(routeId)) {
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

  private boolean requiresAuthentication(String routeId) {
    return routeId == null || !routeId.equalsIgnoreCase("auth");
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
