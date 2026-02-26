package kr.co.computermate.scmrft.qualitydoc.api;

import java.time.Instant;

public record QualityDocumentDetailResponse(
    String documentId,
    String title,
    String status,
    Instant issuedAt,
    String contentUrl,
    String version,
    boolean requiresAck
) {
}
