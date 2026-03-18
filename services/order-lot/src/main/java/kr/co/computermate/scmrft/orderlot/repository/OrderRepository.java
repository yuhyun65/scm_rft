package kr.co.computermate.scmrft.orderlot.repository;

import java.sql.Date;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalDate;
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

  public void insert(String orderId, String supplierId, LocalDate orderDate, String status, Instant createdAt) {
    jdbcClient.sql("""
            INSERT INTO dbo.orders(order_no, member_id, order_date, status, created_at)
            VALUES (:orderId, :supplierId, :orderDate, :status, :createdAt)
        """)
        .param("orderId", orderId)
        .param("supplierId", supplierId)
        .param("orderDate", orderDate)
        .param("status", status)
        .param("createdAt", Timestamp.from(createdAt))
        .update();
  }

  public int updateOrder(String orderId, String supplierId, LocalDate orderDate) {
    return jdbcClient.sql("""
            UPDATE dbo.orders
            SET member_id = :supplierId,
                order_date = :orderDate
            WHERE order_no = :orderId
        """)
        .param("orderId", orderId)
        .param("supplierId", supplierId)
        .param("orderDate", orderDate)
        .update();
  }

  private Instant toOrderedAt(Timestamp createdAt, Date orderDate) {
    if (orderDate != null) {
      return orderDate.toLocalDate().atStartOfDay().toInstant(ZoneOffset.UTC);
    }
    if (createdAt != null) {
      return createdAt.toInstant();
    }
    return null;
  }
}
