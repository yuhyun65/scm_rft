package kr.co.computermate.scmrft.auth.repository;

import java.time.Instant;

public record AuthCredentialEntity(
    String loginId,
    String memberId,
    String passwordHash,
    String passwordAlgo,
    int failedCount,
    Instant lockedUntil
) {}

