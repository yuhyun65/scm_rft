package kr.co.computermate.scmrft.qualitydoc.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class QualityDocumentAckRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private QualityDocumentAckRepository qualityDocumentAckRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.quality_document_acks (
                document_id UUID NOT NULL,
                member_id VARCHAR(50) NOT NULL,
                ack_type VARCHAR(20) NOT NULL,
                ack_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP NOT NULL,
                PRIMARY KEY (document_id, member_id)
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.quality_document_acks").update();
  }

  @Test
  void insertAndFindByDocumentIdAndMemberIdWorks() {
    UUID documentId = UUID.randomUUID();
    Instant now = Instant.now();
    qualityDocumentAckRepository.insert(documentId, "user01", "READ", now);

    QualityDocumentAckEntity entity = qualityDocumentAckRepository
        .findByDocumentIdAndMemberId(documentId, "user01")
        .orElseThrow();

    assertThat(entity.documentId()).isEqualTo(documentId);
    assertThat(entity.memberId()).isEqualTo("user01");
    assertThat(entity.ackType()).isEqualTo("READ");
  }
}
