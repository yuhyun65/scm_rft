package kr.co.computermate.scmrft.gateway.policy;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;

class GatewayRoutePolicyResolverTests {
  private final GatewayRoutePolicyResolver resolver = new GatewayRoutePolicyResolver();

  @Test
  void resolvesRouteAndMethodOverrides() {
    GatewayPolicyDocument document = new GatewayPolicyDocument();
    GatewayPolicyDocument.Defaults defaults = new GatewayPolicyDocument.Defaults();
    defaults.getRetry().setEnabled(true);
    defaults.getRetry().setAttempts(2);
    defaults.getRetry().setBackoffMs(200);
    document.setDefaults(defaults);

    GatewayPolicyDocument.RouteRule route = new GatewayPolicyDocument.RouteRule();
    route.setId("order-lot");
    route.setPath("/api/order-lot/**");
    route.setTarget("http://order-lot:8085");
    route.setRateLimitRps(70);

    GatewayPolicyDocument.MethodPolicy read = new GatewayPolicyDocument.MethodPolicy();
    read.setId("read");
    read.setMethods(List.of("GET"));
    read.setRequestTimeoutMs(10000);
    GatewayPolicyDocument.Retry readRetry = new GatewayPolicyDocument.Retry();
    readRetry.setEnabled(true);
    readRetry.setAttempts(1);
    read.setRetry(readRetry);

    GatewayPolicyDocument.MethodPolicy write = new GatewayPolicyDocument.MethodPolicy();
    write.setId("write");
    write.setMethods(List.of("POST", "PUT"));
    GatewayPolicyDocument.Retry writeRetry = new GatewayPolicyDocument.Retry();
    writeRetry.setEnabled(false);
    writeRetry.setAttempts(0);
    write.setRetry(writeRetry);
    write.setRateLimitRps(30);

    route.setMethodPolicies(List.of(read, write));
    document.setRoutes(List.of(route));

    List<GatewayRoutePolicyResolver.ResolvedRoutePolicy> resolved = resolver.resolve(document);

    assertThat(resolved).hasSize(2);
    GatewayRoutePolicyResolver.ResolvedRoutePolicy writeRoute = resolved.stream()
        .filter(item -> item.id().equals("order-lot-write"))
        .findFirst()
        .orElseThrow();

    assertThat(writeRoute.retry().isEnabled()).isFalse();
    assertThat(writeRoute.retry().getAttempts()).isZero();
    assertThat(writeRoute.rateLimitRps()).isEqualTo(30);
  }

  @Test
  void defaultsAuthRequiredToFalseForAuthRouteOnly() {
    GatewayPolicyDocument document = new GatewayPolicyDocument();
    GatewayPolicyDocument.RouteRule authRoute = new GatewayPolicyDocument.RouteRule();
    authRoute.setId("auth");
    authRoute.setPath("/api/auth/**");
    authRoute.setTarget("http://auth:8081");
    authRoute.setRateLimitRps(100);

    GatewayPolicyDocument.RouteRule memberRoute = new GatewayPolicyDocument.RouteRule();
    memberRoute.setId("member");
    memberRoute.setPath("/api/member/**");
    memberRoute.setTarget("http://member:8082");
    memberRoute.setRateLimitRps(100);

    document.setRoutes(List.of(authRoute, memberRoute));

    List<GatewayRoutePolicyResolver.ResolvedRoutePolicy> resolved = resolver.resolve(document);

    assertThat(resolved).hasSize(2);
    assertThat(resolved.stream().filter(item -> item.id().equals("auth")).findFirst().orElseThrow().authRequired())
        .isFalse();
    assertThat(resolved.stream().filter(item -> item.id().equals("member")).findFirst().orElseThrow().authRequired())
        .isTrue();
  }
}
