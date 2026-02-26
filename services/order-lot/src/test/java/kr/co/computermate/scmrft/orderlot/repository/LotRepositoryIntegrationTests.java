package kr.co.computermate.scmrft.orderlot.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class LotRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private LotRepository lotRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.order_lots (
                lot_no VARCHAR(50) NOT NULL PRIMARY KEY,
                order_no VARCHAR(50) NOT NULL,
                quantity DECIMAL(18,3) NOT NULL,
                status VARCHAR(20) NOT NULL,
                created_at TIMESTAMP NOT NULL
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.order_lots").update();
  }

  @Test
  void findByIdAndCountByOrderIdWorks() {
    jdbcClient.sql("""
            INSERT INTO dbo.order_lots(lot_no, order_no, quantity, status, created_at)
            VALUES ('LOT-1', 'ORD-1', 10.500, 'ALLOCATED', CURRENT_TIMESTAMP),
                   ('LOT-2', 'ORD-1', 20.500, 'ALLOCATED', CURRENT_TIMESTAMP)
        """).update();

    LotEntity lot = lotRepository.findById("LOT-1").orElseThrow();
    int count = lotRepository.countByOrderId("ORD-1");

    assertThat(lot.orderId()).isEqualTo("ORD-1");
    assertThat(lot.quantity()).isEqualByComparingTo(new BigDecimal("10.500"));
    assertThat(count).isEqualTo(2);
  }
}
