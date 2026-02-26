package kr.co.computermate.scmrft.board.repository;

import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class BoardAttachmentRepository {
  private final JdbcClient jdbcClient;

  public BoardAttachmentRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public void saveAttachments(UUID postId, List<UUID> fileIds) {
    if (fileIds == null || fileIds.isEmpty()) {
      return;
    }

    for (UUID fileId : fileIds) {
      jdbcClient.sql("""
              INSERT INTO dbo.board_post_attachments(post_id, file_id, created_at)
              VALUES (:postId, :fileId, CURRENT_TIMESTAMP)
          """)
          .param("postId", postId)
          .param("fileId", fileId)
          .update();
    }
  }

  public List<UUID> findFileIdsByPostId(UUID postId) {
    return jdbcClient.sql("""
            SELECT file_id
            FROM dbo.board_post_attachments
            WHERE post_id = :postId
            ORDER BY file_id
        """)
        .param("postId", postId)
        .query((rs, rowNum) -> {
          Object value = rs.getObject("file_id");
          if (value instanceof UUID uuid) {
            return uuid;
          }
          return UUID.fromString(String.valueOf(value));
        })
        .list();
  }
}
