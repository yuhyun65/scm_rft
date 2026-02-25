package kr.co.computermate.scmrft.auth.token;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;

class JwtAuthTokenProviderTests {
  private static final String SECRET = "scm-rft-default-jwt-secret-key-change-me-2026";

  @Test
  void issueAndVerifyToken() {
    JwtAuthTokenProvider provider = new JwtAuthTokenProvider(SECRET, "scm-auth", 1800);
    Instant now = Instant.now();

    IssuedAccessToken issued = provider.issueToken("admin-user", List.of("ADMIN", "USER"), now);
    TokenVerification verification = provider.verifyToken(issued.accessToken(), now.plusSeconds(1));

    assertThat(verification.active()).isTrue();
    assertThat(verification.subject()).isEqualTo("admin-user");
    assertThat(verification.roles()).containsExactly("ADMIN", "USER");
    assertThat(verification.expiresAt()).isAfter(now.plusSeconds(1700));
    assertThat(verification.expiresAt()).isBeforeOrEqualTo(now.plusSeconds(1801));
  }

  @Test
  void rejectInvalidToken() {
    JwtAuthTokenProvider provider = new JwtAuthTokenProvider(SECRET, "scm-auth", 1800);

    TokenVerification verification = provider.verifyToken("invalid-token", Instant.now());

    assertThat(verification.active()).isFalse();
    assertThat(verification.subject()).isNull();
  }
}
