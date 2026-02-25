package kr.co.computermate.scmrft.inventory.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.simple.JdbcClient;

@SpringBootTest
class InventoryRepositoryIntegrationTests {
  @Autowired
  private JdbcClient jdbcClient;

  @Autowired
  private InventoryRepository inventoryRepository;

  @BeforeEach
  void setUpSchema() {
    jdbcClient.sql("CREATE SCHEMA IF NOT EXISTS dbo").update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.inventory_balances (
                item_code VARCHAR(100) NOT NULL,
                warehouse_code VARCHAR(50) NOT NULL,
                quantity DECIMAL(18,3) NOT NULL,
                updated_at TIMESTAMP NOT NULL
            )
        """).update();
    jdbcClient.sql("""
            CREATE TABLE IF NOT EXISTS dbo.inventory_movements (
                movement_id UUID NOT NULL PRIMARY KEY,
                item_code VARCHAR(100) NOT NULL,
                warehouse_code VARCHAR(50) NOT NULL,
                movement_type VARCHAR(20) NOT NULL,
                quantity DECIMAL(18,3) NOT NULL,
                reference_no VARCHAR(100),
                moved_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP NOT NULL
            )
        """).update();
    jdbcClient.sql("DELETE FROM dbo.inventory_movements").update();
    jdbcClient.sql("DELETE FROM dbo.inventory_balances").update();
  }

  @Test
  void searchBalancesFiltersByItemAndWarehouse() {
    jdbcClient.sql("""
            INSERT INTO dbo.inventory_balances (item_code, warehouse_code, quantity, updated_at)
            VALUES ('ITEM-1', 'WH-1', 10.000, CURRENT_TIMESTAMP),
                   ('ITEM-1', 'WH-2', 20.000, CURRENT_TIMESTAMP),
                   ('ITEM-2', 'WH-1', 30.000, CURRENT_TIMESTAMP)
        """).update();

    InventorySearchResult<InventoryBalanceEntity> result = inventoryRepository.searchBalances("ITEM-1", null, 0, 50);

    assertThat(result.total()).isEqualTo(2L);
    assertThat(result.items()).hasSize(2);
    assertThat(result.items()).allMatch(item -> "ITEM-1".equals(item.itemCode()));
  }

  @Test
  void searchMovementsFiltersByType() {
    jdbcClient.sql("""
            INSERT INTO dbo.inventory_movements (
                movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at, created_at
            ) VALUES (?, 'ITEM-1', 'WH-1', 'IN', 5.000, 'R1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        """)
        .param(UUID.randomUUID())
        .update();
    jdbcClient.sql("""
            INSERT INTO dbo.inventory_movements (
                movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at, created_at
            ) VALUES (?, 'ITEM-1', 'WH-1', 'OUT', 2.000, 'R2', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
        """)
        .param(UUID.randomUUID())
        .update();

    InventorySearchResult<InventoryMovementEntity> result = inventoryRepository.searchMovements(
        "ITEM-1",
        "WH-1",
        "IN",
        0,
        50
    );

    assertThat(result.total()).isEqualTo(1L);
    assertThat(result.items()).hasSize(1);
    assertThat(result.items().get(0).quantity()).isEqualByComparingTo(new BigDecimal("5.000"));
    assertThat(result.items().get(0).movementType()).isEqualTo("IN");
  }
}
