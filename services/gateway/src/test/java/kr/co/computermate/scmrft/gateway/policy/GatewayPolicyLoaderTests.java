package kr.co.computermate.scmrft.gateway.policy;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class GatewayPolicyLoaderTests {
  @Test
  void loadsPolicyFromClasspathWhenFilePathMissing() {
    GatewayPolicyLoader loader = new GatewayPolicyLoader("non-existing-policy.yaml");
    GatewayPolicyDocument document = loader.load();

    assertThat(document.getName()).isEqualTo("cutover-isolation");
    assertThat(document.getRoutes()).isNotEmpty();
    assertThat(document.getCutoverSwitches().getEmergencyStop().getHttpStatus()).isEqualTo(503);
  }
}
