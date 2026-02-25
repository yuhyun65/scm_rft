package kr.co.computermate.scmrft.auth.api;

import java.time.Instant;
import java.util.List;

public record LoginResponse(
    String accessToken,
    String tokenType,
    long expiresIn,
    Instant expiresAt,
    String memberId,
    List<String> roles
) {}

