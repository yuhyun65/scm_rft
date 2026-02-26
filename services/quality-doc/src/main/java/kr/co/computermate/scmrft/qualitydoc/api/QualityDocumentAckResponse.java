package kr.co.computermate.scmrft.qualitydoc.api;

import java.time.Instant;

public record QualityDocumentAckResponse(
    String documentId,
    String memberId,
    String ackType,
    boolean acknowledged,
    Instant acknowledgedAt,
    boolean duplicateRequest
) {
}
