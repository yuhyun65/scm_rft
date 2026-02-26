package kr.co.computermate.scmrft.orderlot.repository;

import java.util.List;
import java.util.Optional;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class LotRepository {
  private final JdbcClient jdbcClient;

  public LotRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public Optional<LotEntity> findById(String lotId) {
    List<LotEntity> rows = jdbcClient.sql("""
            SELECT lot_no, order_no, quantity, status
            FROM dbo.order_lots
            WHERE lot_no = :lotId
        """)
        .param("lotId", lotId)
        .query((rs, rowNum) -> new LotEntity(
            rs.getString("lot_no"),
            rs.getString("order_no"),
            rs.getBigDecimal("quantity"),
            rs.getString("status")
        ))
        .list();
    return rows.stream().findFirst();
  }

  public int countByOrderId(String orderId) {
    Integer count = jdbcClient.sql("""
            SELECT COUNT(*) AS lot_count
            FROM dbo.order_lots
            WHERE order_no = :orderId
        """)
        .param("orderId", orderId)
        .query(Integer.class)
        .single();
    return count == null ? 0 : count;
  }
}
