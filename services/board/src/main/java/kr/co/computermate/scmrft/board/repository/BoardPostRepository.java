package kr.co.computermate.scmrft.board.repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class BoardPostRepository {
  private final JdbcClient jdbcClient;

  public BoardPostRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public BoardPostSearchResult search(String boardType, String keywordPrefix, int offset, int size) {
    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.board_posts
            WHERE (:boardType IS NULL OR category_code = :boardType)
              AND (:keywordPrefix IS NULL OR title LIKE :keywordPrefix)
        """)
        .param("boardType", boardType)
        .param("keywordPrefix", keywordPrefix)
        .query(Long.class)
        .single();

    List<BoardPostEntity> items = jdbcClient.sql("""
            SELECT post_id, category_code, title, content, status, writer_member_id, created_at
            FROM dbo.board_posts
            WHERE (:boardType IS NULL OR category_code = :boardType)
              AND (:keywordPrefix IS NULL OR title LIKE :keywordPrefix)
            ORDER BY created_at DESC, post_id DESC
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("boardType", boardType)
        .param("keywordPrefix", keywordPrefix)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new BoardPostEntity(
            toUuid(rs.getObject("post_id")),
            rs.getString("category_code"),
            rs.getString("title"),
            rs.getString("content"),
            rs.getString("status"),
            rs.getString("writer_member_id"),
            toInstant(rs.getTimestamp("created_at"))
        ))
        .list();

    return new BoardPostSearchResult(items, total == null ? 0L : total);
  }

  public Optional<BoardPostEntity> findById(UUID postId) {
    List<BoardPostEntity> rows = jdbcClient.sql("""
            SELECT post_id, category_code, title, content, status, writer_member_id, created_at
            FROM dbo.board_posts
            WHERE post_id = :postId
        """)
        .param("postId", postId)
        .query((rs, rowNum) -> new BoardPostEntity(
            toUuid(rs.getObject("post_id")),
            rs.getString("category_code"),
            rs.getString("title"),
            rs.getString("content"),
            rs.getString("status"),
            rs.getString("writer_member_id"),
            toInstant(rs.getTimestamp("created_at"))
        ))
        .list();

    return rows.stream().findFirst();
  }

  public BoardPostEntity create(String boardType, String title, String content, String createdBy, boolean isNotice) {
    UUID postId = UUID.randomUUID();
    Instant now = Instant.now();
    int inserted = jdbcClient.sql("""
            INSERT INTO dbo.board_posts (
                post_id, category_code, title, content, writer_member_id, is_notice, status, created_at, updated_at
            ) VALUES (
                :postId, :boardType, :title, :content, :createdBy, :isNotice, :status, :createdAt, :updatedAt
            )
        """)
        .param("postId", postId)
        .param("boardType", boardType)
        .param("title", title)
        .param("content", content)
        .param("createdBy", createdBy)
        .param("isNotice", isNotice ? 1 : 0)
        .param("status", "ACTIVE")
        .param("createdAt", Timestamp.from(now))
        .param("updatedAt", Timestamp.from(now))
        .update();

    if (inserted != 1) {
      throw new IllegalStateException("failed to create board post.");
    }

    return new BoardPostEntity(postId, boardType, title, content, "ACTIVE", createdBy, now);
  }

  private Instant toInstant(Timestamp timestamp) {
    return timestamp == null ? null : timestamp.toInstant();
  }

  private UUID toUuid(Object value) {
    if (value instanceof UUID uuid) {
      return uuid;
    }
    return UUID.fromString(String.valueOf(value));
  }
}
