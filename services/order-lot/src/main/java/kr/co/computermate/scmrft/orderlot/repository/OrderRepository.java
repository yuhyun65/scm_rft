package kr.co.computermate.scmrft.orderlot.repository;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class OrderRepository {
  private final JdbcClient jdbcClient;

  public OrderRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public Optional<OrderEntity> findById(String orderId) {
    List<OrderEntity> rows = jdbcClient.sql("""
            SELECT order_no, member_id, status, order_date, created_at
            FROM dbo.orders
            WHERE order_no = :orderId
        """)
        .param("orderId", orderId)
        .query((rs, rowNum) -> new OrderEntity(
            rs.getString("order_no"),
            rs.getString("member_id"),
            rs.getString("status"),
            toOrderedAt(rs.getTimestamp("created_at"), rs.getDate("order_date"))
        ))
        .list();

    return rows.stream().findFirst();
  }

  public OrderSearchResult search(
      String supplierId,
      String status,
      String keywordPrefix,
      int offset,
      int size
  ) {
    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.orders
            WHERE (:supplierId IS NULL OR member_id = :supplierId)
              AND (:status IS NULL OR status = :status)
              AND (:keywordPrefix IS NULL OR order_no LIKE :keywordPrefix)
        """)
        .param("supplierId", supplierId)
        .param("status", status)
        .param("keywordPrefix", keywordPrefix)
        .query(Long.class)
        .single();

    List<OrderEntity> items = jdbcClient.sql("""
            SELECT order_no, member_id, status, order_date, created_at
            FROM dbo.orders
            WHERE (:supplierId IS NULL OR member_id = :supplierId)
              AND (:status IS NULL OR status = :status)
              AND (:keywordPrefix IS NULL OR order_no LIKE :keywordPrefix)
            ORDER BY created_at DESC, order_no DESC
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("supplierId", supplierId)
        .param("status", status)
        .param("keywordPrefix", keywordPrefix)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new OrderEntity(
            rs.getString("order_no"),
            rs.getString("member_id"),
            rs.getString("status"),
            toOrderedAt(rs.getTimestamp("created_at"), rs.getDate("order_date"))
        ))
        .list();

    return new OrderSearchResult(items, total == null ? 0L : total);
  }

  public int updateStatus(String orderId, String beforeStatus, String afterStatus) {
    return jdbcClient.sql("""
            UPDATE dbo.orders
            SET status = :afterStatus
            WHERE order_no = :orderId
              AND status = :beforeStatus
        """)
        .param("orderId", orderId)
        .param("beforeStatus", beforeStatus)
        .param("afterStatus", afterStatus)
        .update();
  }

  private Instant toOrderedAt(Timestamp createdAt, Date orderDate) {
    if (createdAt != null) {
      return createdAt.toInstant();
    }
    if (orderDate != null) {
      return orderDate.toLocalDate().atStartOfDay().toInstant(ZoneOffset.UTC);
    }
    return null;
  }
}
