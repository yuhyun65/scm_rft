package kr.co.computermate.scmrft.file.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class FileRepository {
  private final JdbcClient jdbcClient;

  public FileRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public void insert(FileMetadataEntity entity) {
    jdbcClient.sql("""
            INSERT INTO dbo.upload_files (file_id, domain_key, storage_path, original_name, created_at)
            VALUES (:fileId, :domainKey, :storagePath, :originalName, CURRENT_TIMESTAMP)
        """)
        .param("fileId", entity.fileId().toString())
        .param("domainKey", entity.domainKey())
        .param("storagePath", entity.storagePath())
        .param("originalName", entity.originalName())
        .update();
  }

  public Optional<FileMetadataEntity> findById(UUID fileId) {
    List<FileMetadataEntity> rows = jdbcClient.sql("""
            SELECT file_id, domain_key, original_name, storage_path
            FROM dbo.upload_files
            WHERE file_id = :fileId
        """)
        .param("fileId", fileId.toString())
        .query((rs, rowNum) -> new FileMetadataEntity(
            toUuid(rs.getObject("file_id")),
            rs.getString("domain_key"),
            rs.getString("original_name"),
            rs.getString("storage_path")
        ))
        .list();

    return rows.stream().findFirst();
  }

  private UUID toUuid(Object rawValue) {
    if (rawValue instanceof UUID uuid) {
      return uuid;
    }
    return UUID.fromString(String.valueOf(rawValue));
  }
}
