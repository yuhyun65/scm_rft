package kr.co.computermate.scmrft.report.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class ReportJobRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private ReportJobRepository reportJobRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.report_jobs (
                job_id UUID NOT NULL PRIMARY KEY,
                report_type VARCHAR(50) NOT NULL,
                requested_by_member_id VARCHAR(50),
                status VARCHAR(20) NOT NULL,
                requested_at TIMESTAMP NOT NULL,
                completed_at TIMESTAMP,
                output_file_id UUID,
                error_message VARCHAR(1000)
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.report_jobs").update();
  }

  @Test
  void insertAndFindByIdReturnSameJob() {
    UUID jobId = UUID.randomUUID();
    ReportJobEntity entity = new ReportJobEntity(
        jobId,
        "LOT_LABEL",
        "QUEUED",
        "admin01",
        Instant.now(),
        null,
        null,
        null
    );

    reportJobRepository.insert(entity);
    Optional<ReportJobEntity> loaded = reportJobRepository.findById(jobId);

    assertThat(loaded).isPresent();
    assertThat(loaded.get().jobId()).isEqualTo(jobId);
    assertThat(loaded.get().reportType()).isEqualTo("LOT_LABEL");
    assertThat(loaded.get().status()).isEqualTo("QUEUED");
  }

  @Test
  void findByIdReturnsEmptyWhenMissing() {
    Optional<ReportJobEntity> loaded = reportJobRepository.findById(UUID.randomUUID());
    assertThat(loaded).isEmpty();
  }
}
