package kr.co.computermate.scmrft.orderlot.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.LocalDate;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class OrderRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private OrderRepository orderRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.orders (
                order_no VARCHAR(50) NOT NULL PRIMARY KEY,
                member_id VARCHAR(50) NOT NULL,
                order_date DATE NOT NULL,
                status VARCHAR(20) NOT NULL,
                created_at TIMESTAMP NOT NULL
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.orders").update();
  }

  @Test
  void searchFiltersByStatusAndKeyword() {
    jdbcClient.sql("""
            INSERT INTO dbo.orders(order_no, member_id, order_date, status, created_at)
            VALUES ('ORD-001', 'SUP-1', ?, 'PENDING', CURRENT_TIMESTAMP),
                   ('ORD-ABC', 'SUP-1', ?, 'CONFIRMED', CURRENT_TIMESTAMP),
                   ('X-001', 'SUP-2', ?, 'PENDING', CURRENT_TIMESTAMP)
        """)
        .param(LocalDate.now())
        .param(LocalDate.now())
        .param(LocalDate.now())
        .update();

    OrderSearchResult result = orderRepository.search("SUP-1", "PENDING", "ORD-%", 0, 20);

    assertThat(result.total()).isEqualTo(1L);
    assertThat(result.items()).hasSize(1);
    assertThat(result.items().get(0).orderId()).isEqualTo("ORD-001");
  }

  @Test
  void updateStatusUsesCurrentStatusGuard() {
    jdbcClient.sql("""
            INSERT INTO dbo.orders(order_no, member_id, order_date, status, created_at)
            VALUES ('ORD-001', 'SUP-1', ?, 'PENDING', CURRENT_TIMESTAMP)
        """)
        .param(LocalDate.now())
        .update();

    int changed = orderRepository.updateStatus("ORD-001", "PENDING", "CONFIRMED");
    int notChanged = orderRepository.updateStatus("ORD-001", "PENDING", "IN_PROGRESS");

    assertThat(changed).isEqualTo(1);
    assertThat(notChanged).isEqualTo(0);
  }
}
