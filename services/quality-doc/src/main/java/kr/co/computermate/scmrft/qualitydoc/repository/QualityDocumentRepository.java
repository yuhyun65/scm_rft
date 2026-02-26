package kr.co.computermate.scmrft.qualitydoc.repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class QualityDocumentRepository {
  private final JdbcClient jdbcClient;

  public QualityDocumentRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public QualityDocumentSearchResult search(String statusFilter, String keywordPrefix, int offset, int size) {
    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.quality_documents
            WHERE (:statusFilter IS NULL OR status = :statusFilter)
              AND (:keywordPrefix IS NULL OR title LIKE :keywordPrefix)
        """)
        .param("statusFilter", statusFilter)
        .param("keywordPrefix", keywordPrefix)
        .query(Long.class)
        .single();

    List<QualityDocumentEntity> items = jdbcClient.sql("""
            SELECT document_id, title, document_type, status, issued_at
            FROM dbo.quality_documents
            WHERE (:statusFilter IS NULL OR status = :statusFilter)
              AND (:keywordPrefix IS NULL OR title LIKE :keywordPrefix)
            ORDER BY issued_at DESC, document_id DESC
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("statusFilter", statusFilter)
        .param("keywordPrefix", keywordPrefix)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new QualityDocumentEntity(
            toUuid(rs.getObject("document_id")),
            rs.getString("title"),
            rs.getString("document_type"),
            rs.getString("status"),
            toInstant(rs.getTimestamp("issued_at"))
        ))
        .list();

    return new QualityDocumentSearchResult(items, total == null ? 0L : total);
  }

  public Optional<QualityDocumentEntity> findById(UUID documentId) {
    List<QualityDocumentEntity> rows = jdbcClient.sql("""
            SELECT document_id, title, document_type, status, issued_at
            FROM dbo.quality_documents
            WHERE document_id = :documentId
        """)
        .param("documentId", documentId)
        .query((rs, rowNum) -> new QualityDocumentEntity(
            toUuid(rs.getObject("document_id")),
            rs.getString("title"),
            rs.getString("document_type"),
            rs.getString("status"),
            toInstant(rs.getTimestamp("issued_at"))
        ))
        .list();
    return rows.stream().findFirst();
  }

  private Instant toInstant(Timestamp value) {
    return value == null ? null : value.toInstant();
  }

  private UUID toUuid(Object value) {
    if (value instanceof UUID uuid) {
      return uuid;
    }
    return UUID.fromString(String.valueOf(value));
  }
}
