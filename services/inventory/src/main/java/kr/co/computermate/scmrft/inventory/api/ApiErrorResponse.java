package kr.co.computermate.scmrft.inventory.api;

import java.time.Instant;

public record ApiErrorResponse(
    String code,
    String message,
    String path,
    Instant timestamp
) {}
