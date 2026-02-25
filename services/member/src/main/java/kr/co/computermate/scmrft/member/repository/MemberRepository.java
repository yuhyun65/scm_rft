package kr.co.computermate.scmrft.member.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class MemberRepository {
  private final JdbcClient jdbcClient;

  public MemberRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public Optional<MemberEntity> findById(String memberId) {
    List<MemberEntity> rows = jdbcClient.sql("""
            SELECT member_id, member_name, status
            FROM dbo.members
            WHERE member_id = :memberId
        """)
        .param("memberId", memberId)
        .query((rs, rowNum) -> new MemberEntity(
            rs.getString("member_id"),
            rs.getString("member_name"),
            rs.getString("status")
        ))
        .list();

    return rows.stream().findFirst();
  }

  public MemberSearchResult search(String keyword, String status, int page, int size) {
    int offset = page * size;
    if (keyword == null || keyword.isBlank()) {
      return searchWithoutKeyword(status, offset, size);
    }
    return searchWithKeyword(keyword.trim() + "%", status, offset, size);
  }

  private MemberSearchResult searchWithoutKeyword(String status, int offset, int size) {
    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.members
            WHERE (:status IS NULL OR status = :status)
        """)
        .param("status", status)
        .query(Long.class)
        .single();

    List<MemberEntity> items = jdbcClient.sql("""
            SELECT member_id, member_name, status
            FROM dbo.members
            WHERE (:status IS NULL OR status = :status)
            ORDER BY member_id
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("status", status)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new MemberEntity(
            rs.getString("member_id"),
            rs.getString("member_name"),
            rs.getString("status")
        ))
        .list();

    return new MemberSearchResult(items, total == null ? 0L : total);
  }

  private MemberSearchResult searchWithKeyword(String keywordPrefix, String status, int offset, int size) {
    Long total = jdbcClient.sql("""
            WITH merged AS (
                SELECT member_id, member_name, status
                FROM dbo.members
                WHERE member_id LIKE :keywordPrefix
                  AND (:status IS NULL OR status = :status)
                UNION
                SELECT member_id, member_name, status
                FROM dbo.members
                WHERE member_name LIKE :keywordPrefix
                  AND (:status IS NULL OR status = :status)
            )
            SELECT COUNT(*) AS total
            FROM merged
        """)
        .param("keywordPrefix", keywordPrefix)
        .param("status", status)
        .query(Long.class)
        .single();

    List<MemberEntity> items = jdbcClient.sql("""
            WITH merged AS (
                SELECT member_id, member_name, status
                FROM dbo.members
                WHERE member_id LIKE :keywordPrefix
                  AND (:status IS NULL OR status = :status)
                UNION
                SELECT member_id, member_name, status
                FROM dbo.members
                WHERE member_name LIKE :keywordPrefix
                  AND (:status IS NULL OR status = :status)
            )
            SELECT member_id, member_name, status
            FROM merged
            ORDER BY member_id
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("keywordPrefix", keywordPrefix)
        .param("status", status)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new MemberEntity(
            rs.getString("member_id"),
            rs.getString("member_name"),
            rs.getString("status")
        ))
        .list();

    return new MemberSearchResult(items, total == null ? 0L : total);
  }
}
