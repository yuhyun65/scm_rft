package kr.co.computermate.scmrft.file.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class FileRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private FileRepository fileRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.upload_files (
                file_id UUID PRIMARY KEY,
                domain_key VARCHAR(100) NOT NULL,
                storage_path VARCHAR(500) NOT NULL,
                original_name VARCHAR(255) NOT NULL,
                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.upload_files").update();
  }

  @Test
  void insertAndFindByIdWorkWithUploadFilesTable() {
    UUID fileId = UUID.randomUUID();
    FileMetadataEntity entity = new FileMetadataEntity(
        fileId,
        "ORDER-LOT:LOT-100",
        "lot100.pdf",
        "uploadData/2026/02/lot100.pdf"
    );

    fileRepository.insert(entity);
    Optional<FileMetadataEntity> loaded = fileRepository.findById(fileId);

    assertThat(loaded).isPresent();
    assertThat(loaded.get().fileId()).isEqualTo(fileId);
    assertThat(loaded.get().domainKey()).isEqualTo("ORDER-LOT:LOT-100");
    assertThat(loaded.get().originalName()).isEqualTo("lot100.pdf");
    assertThat(loaded.get().storagePath()).isEqualTo("uploadData/2026/02/lot100.pdf");
  }

  @Test
  void findByIdReturnsEmptyWhenFileDoesNotExist() {
    Optional<FileMetadataEntity> loaded = fileRepository.findById(UUID.randomUUID());
    assertThat(loaded).isEmpty();
  }
}
