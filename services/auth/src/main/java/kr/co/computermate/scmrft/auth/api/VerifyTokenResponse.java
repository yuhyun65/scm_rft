package kr.co.computermate.scmrft.auth.api;

import java.time.Instant;
import java.util.List;

public record VerifyTokenResponse(
    boolean active,
    String subject,
    List<String> roles,
    Instant issuedAt,
    Instant expiresAt
) {}

