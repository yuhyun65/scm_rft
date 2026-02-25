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
    String keywordLike = keyword == null ? null : "%" + keyword + "%";
    int offset = page * size;

    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.members
            WHERE (:keywordLike IS NULL OR member_id LIKE :keywordLike OR member_name LIKE :keywordLike)
              AND (:status IS NULL OR status = :status)
        """)
        .param("keywordLike", keywordLike)
        .param("status", status)
        .query(Long.class)
        .single();

    List<MemberEntity> items = jdbcClient.sql("""
            SELECT member_id, member_name, status
            FROM dbo.members
            WHERE (:keywordLike IS NULL OR member_id LIKE :keywordLike OR member_name LIKE :keywordLike)
              AND (:status IS NULL OR status = :status)
            ORDER BY member_id
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("keywordLike", keywordLike)
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

