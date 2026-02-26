package kr.co.computermate.scmrft.gateway.policy;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;

@Component
public class GatewayRoutePolicyResolver {
  public List<ResolvedRoutePolicy> resolve(GatewayPolicyDocument document) {
    List<ResolvedRoutePolicy> policies = new ArrayList<>();
    GatewayPolicyDocument.Defaults defaults = document.getDefaults();
    int globalRateLimit = Math.max(1, document.getTrafficControl().getGlobalRateLimit().getRequestsPerSecond());

    for (GatewayPolicyDocument.RouteRule route : document.getRoutes()) {
      if (route.getMethodPolicies().isEmpty()) {
        policies.add(resolveRoute(defaults, route, null, globalRateLimit));
        continue;
      }

      for (GatewayPolicyDocument.MethodPolicy methodPolicy : route.getMethodPolicies()) {
        policies.add(resolveRoute(defaults, route, methodPolicy, globalRateLimit));
      }
    }

    return policies;
  }

  private ResolvedRoutePolicy resolveRoute(
      GatewayPolicyDocument.Defaults defaults,
      GatewayPolicyDocument.RouteRule route,
      GatewayPolicyDocument.MethodPolicy methodPolicy,
      int globalRateLimit
  ) {
    String resolvedId = route.getId();
    List<String> methods = List.of();
    if (methodPolicy != null) {
      methods = methodPolicy.getMethods().stream()
          .map(method -> method == null ? null : method.trim().toUpperCase(Locale.ROOT))
          .filter(method -> method != null && !method.isBlank())
          .distinct()
          .collect(Collectors.toList());
      String suffix = methodPolicy.getId() == null || methodPolicy.getId().isBlank()
          ? String.join("-", methods).toLowerCase(Locale.ROOT)
          : methodPolicy.getId().trim().toLowerCase(Locale.ROOT);
      resolvedId = route.getId() + "-" + suffix;
    }

    int connectTimeoutMs = pickInt(
        methodPolicy == null ? null : methodPolicy.getConnectTimeoutMs(),
        route.getConnectTimeoutMs(),
        defaults.getConnectTimeoutMs()
    );
    int requestTimeoutMs = pickInt(
        methodPolicy == null ? null : methodPolicy.getRequestTimeoutMs(),
        route.getRequestTimeoutMs(),
        defaults.getRequestTimeoutMs()
    );

    GatewayPolicyDocument.Retry retry = mergeRetry(defaults.getRetry(), route.getRetry(), methodPolicy == null ? null : methodPolicy.getRetry());
    GatewayPolicyDocument.CircuitBreaker circuitBreaker = mergeCircuitBreaker(
        defaults.getCircuitBreaker(),
        route.getCircuitBreaker(),
        methodPolicy == null ? null : methodPolicy.getCircuitBreaker()
    );

    int rateLimitRps = pickInt(
        methodPolicy == null ? null : methodPolicy.getRateLimitRps(),
        route.getRateLimitRps() > 0 ? route.getRateLimitRps() : null,
        globalRateLimit
    );

    boolean authRequired = route.getAuthRequired() != null ? route.getAuthRequired() : !"auth".equalsIgnoreCase(route.getId());

    return new ResolvedRoutePolicy(
        resolvedId,
        route.getPath(),
        route.getTarget(),
        methods,
        authRequired,
        connectTimeoutMs,
        requestTimeoutMs,
        retry,
        circuitBreaker,
        rateLimitRps,
        route.getWriteProtection()
    );
  }

  private int pickInt(Integer methodValue, Integer routeValue, int defaultValue) {
    if (methodValue != null && methodValue > 0) {
      return methodValue;
    }
    if (routeValue != null && routeValue > 0) {
      return routeValue;
    }
    return Math.max(1, defaultValue);
  }

  private GatewayPolicyDocument.Retry mergeRetry(
      GatewayPolicyDocument.Retry defaults,
      GatewayPolicyDocument.Retry routeRetry,
      GatewayPolicyDocument.Retry methodRetry
  ) {
    GatewayPolicyDocument.Retry merged = new GatewayPolicyDocument.Retry();
    merged.setEnabled(defaults.isEnabled());
    merged.setAttempts(Math.max(0, defaults.getAttempts()));
    merged.setBackoffMs(Math.max(0, defaults.getBackoffMs()));

    if (routeRetry != null) {
      merged.setEnabled(routeRetry.isEnabled());
      merged.setAttempts(Math.max(0, routeRetry.getAttempts()));
      merged.setBackoffMs(Math.max(0, routeRetry.getBackoffMs()));
    }
    if (methodRetry != null) {
      merged.setEnabled(methodRetry.isEnabled());
      merged.setAttempts(Math.max(0, methodRetry.getAttempts()));
      merged.setBackoffMs(Math.max(0, methodRetry.getBackoffMs()));
    }
    return merged;
  }

  private GatewayPolicyDocument.CircuitBreaker mergeCircuitBreaker(
      GatewayPolicyDocument.CircuitBreaker defaults,
      GatewayPolicyDocument.CircuitBreaker routeCb,
      GatewayPolicyDocument.CircuitBreaker methodCb
  ) {
    GatewayPolicyDocument.CircuitBreaker merged = new GatewayPolicyDocument.CircuitBreaker();
    merged.setEnabled(defaults.isEnabled());
    merged.setFailureRateThreshold(defaults.getFailureRateThreshold());
    merged.setSlowCallRateThreshold(defaults.getSlowCallRateThreshold());
    merged.setWaitDurationInOpenStateMs(defaults.getWaitDurationInOpenStateMs());

    if (routeCb != null) {
      merged.setEnabled(routeCb.isEnabled());
      merged.setFailureRateThreshold(routeCb.getFailureRateThreshold());
      merged.setSlowCallRateThreshold(routeCb.getSlowCallRateThreshold());
      merged.setWaitDurationInOpenStateMs(routeCb.getWaitDurationInOpenStateMs());
    }
    if (methodCb != null) {
      merged.setEnabled(methodCb.isEnabled());
      merged.setFailureRateThreshold(methodCb.getFailureRateThreshold());
      merged.setSlowCallRateThreshold(methodCb.getSlowCallRateThreshold());
      merged.setWaitDurationInOpenStateMs(methodCb.getWaitDurationInOpenStateMs());
    }
    return merged;
  }

  public record ResolvedRoutePolicy(
      String id,
      String path,
      String target,
      List<String> methods,
      boolean authRequired,
      int connectTimeoutMs,
      int requestTimeoutMs,
      GatewayPolicyDocument.Retry retry,
      GatewayPolicyDocument.CircuitBreaker circuitBreaker,
      int rateLimitRps,
      GatewayPolicyDocument.WriteProtection writeProtection
  ) {
  }
}
