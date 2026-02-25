package kr.co.computermate.scmrft.report.repository;

import java.time.Instant;
import java.util.UUID;

public record ReportJobEntity(
    UUID jobId,
    String reportType,
    String status,
    String requestedByMemberId,
    Instant requestedAt,
    Instant completedAt,
    UUID outputFileId,
    String errorMessage
) {}
