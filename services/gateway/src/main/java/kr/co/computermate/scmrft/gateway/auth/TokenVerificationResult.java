package kr.co.computermate.scmrft.gateway.auth;

import java.util.List;

public record TokenVerificationResult(
    VerificationStatus status,
    String subject,
    List<String> roles
) {
  public static TokenVerificationResult active(String subject, List<String> roles) {
    return new TokenVerificationResult(VerificationStatus.ACTIVE, subject, roles == null ? List.of() : roles);
  }

  public static TokenVerificationResult inactive() {
    return new TokenVerificationResult(VerificationStatus.INACTIVE, null, List.of());
  }

  public static TokenVerificationResult unavailable() {
    return new TokenVerificationResult(VerificationStatus.UNAVAILABLE, null, List.of());
  }

  public enum VerificationStatus {
    ACTIVE,
    INACTIVE,
    UNAVAILABLE
  }
}

