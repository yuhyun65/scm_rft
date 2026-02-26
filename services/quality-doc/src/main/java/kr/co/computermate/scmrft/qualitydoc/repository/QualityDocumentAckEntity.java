package kr.co.computermate.scmrft.qualitydoc.repository;

import java.time.Instant;
import java.util.UUID;

public record QualityDocumentAckEntity(
    UUID documentId,
    String memberId,
    String ackType,
    Instant ackAt
) {
}
