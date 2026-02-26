package kr.co.computermate.scmrft.qualitydoc.api;

import java.time.Instant;

public record QualityDocumentSummaryResponse(
    String documentId,
    String title,
    String status,
    Instant issuedAt
) {
}
