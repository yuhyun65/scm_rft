package kr.co.computermate.scmrft.auth.repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class AuthCredentialRepository {
  private final JdbcClient jdbcClient;

  public AuthCredentialRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public Optional<AuthCredentialEntity> findByLoginId(String loginId) {
    List<AuthCredentialEntity> rows = jdbcClient.sql("""
            SELECT login_id, member_id, password_hash, password_algo, failed_count, locked_until
            FROM dbo.auth_credentials
            WHERE login_id = :loginId
        """)
        .param("loginId", loginId)
        .query((rs, rowNum) -> new AuthCredentialEntity(
            rs.getString("login_id"),
            rs.getString("member_id"),
            rs.getString("password_hash"),
            rs.getString("password_algo"),
            rs.getInt("failed_count"),
            toInstant(rs.getTimestamp("locked_until"))
        ))
        .list();

    return rows.stream().findFirst();
  }

  public int incrementFailedCount(String loginId) {
    jdbcClient.sql("""
            UPDATE dbo.auth_credentials
            SET failed_count = failed_count + 1,
                updated_at = SYSUTCDATETIME()
            WHERE login_id = :loginId
        """)
        .param("loginId", loginId)
        .update();

    Integer failedCount = jdbcClient.sql("""
            SELECT failed_count
            FROM dbo.auth_credentials
            WHERE login_id = :loginId
        """)
        .param("loginId", loginId)
        .query(Integer.class)
        .single();

    return failedCount == null ? 0 : failedCount;
  }

  public void lockUntil(String loginId, Instant lockedUntil) {
    jdbcClient.sql("""
            UPDATE dbo.auth_credentials
            SET locked_until = :lockedUntil,
                updated_at = SYSUTCDATETIME()
            WHERE login_id = :loginId
        """)
        .param("lockedUntil", Timestamp.from(lockedUntil))
        .param("loginId", loginId)
        .update();
  }

  public void resetFailureState(String loginId) {
    jdbcClient.sql("""
            UPDATE dbo.auth_credentials
            SET failed_count = 0,
                locked_until = NULL,
                updated_at = SYSUTCDATETIME()
            WHERE login_id = :loginId
        """)
        .param("loginId", loginId)
        .update();
  }

  private Instant toInstant(Timestamp ts) {
    return ts == null ? null : ts.toInstant();
  }
}

