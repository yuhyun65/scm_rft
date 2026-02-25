package kr.co.computermate.scmrft.auth.token;

import java.time.Instant;
import java.util.List;

public record IssuedAccessToken(
    String accessToken,
    String subject,
    List<String> roles,
    Instant issuedAt,
    Instant expiresAt,
    long expiresInSeconds
) {}

