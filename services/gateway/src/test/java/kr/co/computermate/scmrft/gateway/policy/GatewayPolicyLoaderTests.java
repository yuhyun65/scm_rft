package kr.co.computermate.scmrft.gateway.policy;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class GatewayPolicyLoaderTests {
  @Test
  void loadsPolicyFromClasspathWhenFilePathMissing() {
    GatewayPolicyLoader loader = new GatewayPolicyLoader("non-existing-policy.yaml");
    GatewayPolicyDocument document = loader.load();

    assertThat(document.getName()).isEqualTo("cutover-isolation");
    assertThat(document.getRoutes()).isNotEmpty();
    assertThat(document.getCutoverSwitches().getEmergencyStop().getHttpStatus()).isEqualTo(503);
  }

  @Test
  void resolvesConfiguredRelativePathFromParentDirectories(@TempDir Path tempDir) throws IOException {
    Path repoRoot = tempDir.resolve("repo");
    Path nestedWorkingDir = repoRoot.resolve("services/gateway");
    Path policyFile = repoRoot.resolve("infra/gateway/policies/local-auth-member-e2e.yaml");
    Files.createDirectories(nestedWorkingDir);
    Files.createDirectories(policyFile.getParent());
    Files.writeString(policyFile, """
        policyVersion: 1
        name: local-auth-member-e2e
        routes:
          - id: auth
            path: /api/auth/**
            target: http://localhost:8081
            authRequired: false
        """);

    GatewayPolicyLoader loader =
        new GatewayPolicyLoader("infra/gateway/policies/local-auth-member-e2e.yaml", nestedWorkingDir);
    GatewayPolicyDocument document = loader.load();
    assertThat(document.getName()).isEqualTo("local-auth-member-e2e");
    assertThat(document.getRoutes()).hasSize(1);
  }
}
