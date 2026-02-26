package kr.co.computermate.scmrft.qualitydoc.repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class QualityDocumentAckRepository {
  private final JdbcClient jdbcClient;

  public QualityDocumentAckRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public Optional<QualityDocumentAckEntity> findByDocumentIdAndMemberId(UUID documentId, String memberId) {
    List<QualityDocumentAckEntity> rows = jdbcClient.sql("""
            SELECT document_id, member_id, ack_type, ack_at
            FROM dbo.quality_document_acks
            WHERE document_id = :documentId
              AND member_id = :memberId
        """)
        .param("documentId", documentId)
        .param("memberId", memberId)
        .query((rs, rowNum) -> new QualityDocumentAckEntity(
            toUuid(rs.getObject("document_id")),
            rs.getString("member_id"),
            rs.getString("ack_type"),
            toInstant(rs.getTimestamp("ack_at"))
        ))
        .list();

    return rows.stream().findFirst();
  }

  public QualityDocumentAckEntity insert(UUID documentId, String memberId, String ackType, Instant ackAt) {
    int inserted = jdbcClient.sql("""
            INSERT INTO dbo.quality_document_acks(
                document_id, member_id, ack_type, ack_at, created_at
            ) VALUES (
                :documentId, :memberId, :ackType, :ackAt, CURRENT_TIMESTAMP
            )
        """)
        .param("documentId", documentId)
        .param("memberId", memberId)
        .param("ackType", ackType)
        .param("ackAt", Timestamp.from(ackAt))
        .update();

    if (inserted != 1) {
      throw new IllegalStateException("failed to insert quality document ack.");
    }
    return new QualityDocumentAckEntity(documentId, memberId, ackType, ackAt);
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
