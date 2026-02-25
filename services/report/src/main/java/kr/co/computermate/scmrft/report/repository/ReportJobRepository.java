package kr.co.computermate.scmrft.report.repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class ReportJobRepository {
  private final JdbcClient jdbcClient;

  public ReportJobRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public void insert(ReportJobEntity entity) {
    jdbcClient.sql("""
            INSERT INTO dbo.report_jobs (
                job_id, report_type, requested_by_member_id, status,
                requested_at, completed_at, output_file_id, error_message
            ) VALUES (
                :jobId, :reportType, :requestedByMemberId, :status,
                :requestedAt, :completedAt, :outputFileId, :errorMessage
            )
        """)
        .param("jobId", entity.jobId().toString())
        .param("reportType", entity.reportType())
        .param("requestedByMemberId", entity.requestedByMemberId())
        .param("status", entity.status())
        .param("requestedAt", toTimestamp(entity.requestedAt()))
        .param("completedAt", toTimestamp(entity.completedAt()))
        .param("outputFileId", entity.outputFileId() == null ? null : entity.outputFileId().toString())
        .param("errorMessage", entity.errorMessage())
        .update();
  }

  public Optional<ReportJobEntity> findById(UUID jobId) {
    List<ReportJobEntity> rows = jdbcClient.sql("""
            SELECT job_id, report_type, status, requested_by_member_id, requested_at, completed_at, output_file_id, error_message
            FROM dbo.report_jobs
            WHERE job_id = :jobId
        """)
        .param("jobId", jobId.toString())
        .query((rs, rowNum) -> new ReportJobEntity(
            toUuid(rs.getObject("job_id")),
            rs.getString("report_type"),
            rs.getString("status"),
            rs.getString("requested_by_member_id"),
            toInstant(rs.getTimestamp("requested_at")),
            toInstant(rs.getTimestamp("completed_at")),
            toNullableUuid(rs.getObject("output_file_id")),
            rs.getString("error_message")
        ))
        .list();

    return rows.stream().findFirst();
  }

  private Instant toInstant(Timestamp value) {
    return value == null ? null : value.toInstant();
  }

  private Timestamp toTimestamp(Instant value) {
    return value == null ? null : Timestamp.from(value);
  }

  private UUID toUuid(Object value) {
    if (value instanceof UUID uuid) {
      return uuid;
    }
    return UUID.fromString(String.valueOf(value));
  }

  private UUID toNullableUuid(Object value) {
    if (value == null) {
      return null;
    }
    return toUuid(value);
  }
}
