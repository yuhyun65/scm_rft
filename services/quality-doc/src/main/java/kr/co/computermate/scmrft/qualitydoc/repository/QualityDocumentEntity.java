package kr.co.computermate.scmrft.qualitydoc.repository;

import java.time.Instant;
import java.util.UUID;

public record QualityDocumentEntity(
    UUID documentId,
    String title,
    String documentType,
    String status,
    Instant issuedAt
) {
}
