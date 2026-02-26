package kr.co.computermate.scmrft.qualitydoc.service;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import kr.co.computermate.scmrft.qualitydoc.api.PageMetaResponse;
import kr.co.computermate.scmrft.qualitydoc.api.QualityDocumentAckRequest;
import kr.co.computermate.scmrft.qualitydoc.api.QualityDocumentAckResponse;
import kr.co.computermate.scmrft.qualitydoc.api.QualityDocumentDetailResponse;
import kr.co.computermate.scmrft.qualitydoc.api.QualityDocumentSummaryResponse;
import kr.co.computermate.scmrft.qualitydoc.api.SearchQualityDocumentsResponse;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentAckEntity;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentAckRepository;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentEntity;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentRepository;
import kr.co.computermate.scmrft.qualitydoc.repository.QualityDocumentSearchResult;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class QualityDocService {
  private static final int MAX_PAGE_SIZE = 200;

  private final QualityDocumentRepository qualityDocumentRepository;
  private final QualityDocumentAckRepository qualityDocumentAckRepository;

  public QualityDocService(
      QualityDocumentRepository qualityDocumentRepository,
      QualityDocumentAckRepository qualityDocumentAckRepository
  ) {
    this.qualityDocumentRepository = qualityDocumentRepository;
    this.qualityDocumentAckRepository = qualityDocumentAckRepository;
  }

  @Transactional(readOnly = true, timeout = 2)
  public SearchQualityDocumentsResponse searchDocuments(String status, String keyword, int page, int size) {
    validatePaging(page, size);
    String dbStatusFilter = toDbStatusFilter(status);
    String keywordPrefix = normalizeKeywordPrefix(keyword);

    QualityDocumentSearchResult result = qualityDocumentRepository.search(dbStatusFilter, keywordPrefix, page * size, size);
    List<QualityDocumentSummaryResponse> items = result.items().stream()
        .map(this::toSummary)
        .toList();

    int totalPages = (int) Math.ceil(result.total() / (double) size);
    PageMetaResponse pageMeta = new PageMetaResponse(page, size, result.total(), totalPages, page + 1 < totalPages);

    return new SearchQualityDocumentsResponse(items, pageMeta);
  }

  @Transactional(readOnly = true, timeout = 2)
  public QualityDocumentDetailResponse getDocumentById(String documentId) {
    UUID normalizedDocumentId = parseUuid(documentId, "documentId is invalid.");
    QualityDocumentEntity entity = qualityDocumentRepository.findById(normalizedDocumentId)
        .orElseThrow(() -> QualityDocApiException.notFound("Document not found."));

    return new QualityDocumentDetailResponse(
        entity.documentId().toString(),
        entity.title(),
        toApiStatus(entity.status()),
        entity.issuedAt(),
        null,
        null,
        true
    );
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public QualityDocumentAckResponse acknowledge(String documentId, QualityDocumentAckRequest request) {
    UUID normalizedDocumentId = parseUuid(documentId, "documentId is invalid.");
    String memberId = requireValue(request.memberId(), "memberId is required.");
    String ackType = normalizeAckType(request.ackType());

    qualityDocumentRepository.findById(normalizedDocumentId)
        .orElseThrow(() -> QualityDocApiException.notFound("Document not found."));

    QualityDocumentAckEntity existing = qualityDocumentAckRepository
        .findByDocumentIdAndMemberId(normalizedDocumentId, memberId)
        .orElse(null);
    if (existing != null) {
      if (!ackType.equals(existing.ackType())) {
        throw QualityDocApiException.conflict("ACK already exists with different ackType.");
      }
      return toAckResponse(existing, true);
    }

    Instant now = Instant.now();
    try {
      QualityDocumentAckEntity inserted = qualityDocumentAckRepository.insert(normalizedDocumentId, memberId, ackType, now);
      return toAckResponse(inserted, false);
    }
    catch (DataIntegrityViolationException ex) {
      QualityDocumentAckEntity concurrent = qualityDocumentAckRepository
          .findByDocumentIdAndMemberId(normalizedDocumentId, memberId)
          .orElseThrow(() -> QualityDocApiException.conflict("ACK conflict detected."));
      if (!ackType.equals(concurrent.ackType())) {
        throw QualityDocApiException.conflict("ACK already exists with different ackType.");
      }
      return toAckResponse(concurrent, true);
    }
  }

  private QualityDocumentAckResponse toAckResponse(QualityDocumentAckEntity entity, boolean duplicate) {
    return new QualityDocumentAckResponse(
        entity.documentId().toString(),
        entity.memberId(),
        entity.ackType(),
        true,
        entity.ackAt(),
        duplicate
    );
  }

  private QualityDocumentSummaryResponse toSummary(QualityDocumentEntity entity) {
    return new QualityDocumentSummaryResponse(
        entity.documentId().toString(),
        entity.title(),
        toApiStatus(entity.status()),
        entity.issuedAt()
    );
  }

  private String toApiStatus(String dbStatus) {
    if (dbStatus == null) {
      return "ACTIVE";
    }
    return switch (dbStatus.toUpperCase(Locale.ROOT)) {
      case "ISSUED" -> "ACTIVE";
      case "RECEIVED" -> "EXPIRED";
      case "ARCHIVED" -> "ARCHIVED";
      default -> "ACTIVE";
    };
  }

  private String toDbStatusFilter(String apiStatus) {
    String normalized = normalizeToNull(apiStatus);
    if (normalized == null) {
      return null;
    }
    return switch (normalized.toUpperCase(Locale.ROOT)) {
      case "ACTIVE" -> "ISSUED";
      case "EXPIRED" -> "RECEIVED";
      case "ARCHIVED" -> "ARCHIVED";
      default -> throw QualityDocApiException.badRequest("status must be ACTIVE, EXPIRED, or ARCHIVED.");
    };
  }

  private String normalizeAckType(String ackType) {
    String normalized = normalizeToNull(ackType);
    if (normalized == null) {
      throw QualityDocApiException.badRequest("ackType is required.");
    }
    String upper = normalized.toUpperCase(Locale.ROOT);
    if (!"READ".equals(upper) && !"CONFIRMED".equals(upper)) {
      throw QualityDocApiException.badRequest("ackType must be READ or CONFIRMED.");
    }
    return upper;
  }

  private String normalizeKeywordPrefix(String keyword) {
    String normalized = normalizeToNull(keyword);
    return normalized == null ? null : normalized + "%";
  }

  private void validatePaging(int page, int size) {
    if (page < 0) {
      throw QualityDocApiException.badRequest("page must be greater than or equal to 0.");
    }
    if (size < 1 || size > MAX_PAGE_SIZE) {
      throw QualityDocApiException.badRequest("size must be between 1 and 200.");
    }
  }

  private UUID parseUuid(String value, String message) {
    try {
      return UUID.fromString(requireValue(value, message));
    }
    catch (IllegalArgumentException ex) {
      throw QualityDocApiException.badRequest(message);
    }
  }

  private String requireValue(String value, String message) {
    String normalized = normalizeToNull(value);
    if (normalized == null) {
      throw QualityDocApiException.badRequest(message);
    }
    return normalized;
  }

  private String normalizeToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }
}
