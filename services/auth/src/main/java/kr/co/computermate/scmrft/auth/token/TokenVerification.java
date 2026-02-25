package kr.co.computermate.scmrft.auth.token;

import java.time.Instant;
import java.util.List;

public record TokenVerification(
    boolean active,
    String subject,
    List<String> roles,
    Instant issuedAt,
    Instant expiresAt
) {
  public static TokenVerification inactive() {
    return new TokenVerification(false, null, List.of(), null, null);
  }

  public static TokenVerification active(
      String subject,
      List<String> roles,
      Instant issuedAt,
      Instant expiresAt
  ) {
    return new TokenVerification(true, subject, roles, issuedAt, expiresAt);
  }
}

