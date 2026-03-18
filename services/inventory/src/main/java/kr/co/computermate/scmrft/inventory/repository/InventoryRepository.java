package kr.co.computermate.scmrft.inventory.repository;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class InventoryRepository {
  private final JdbcClient jdbcClient;

  public InventoryRepository(JdbcClient jdbcClient) {
    this.jdbcClient = jdbcClient;
  }

  public InventorySearchResult<InventoryBalanceEntity> searchBalances(
      String itemCode,
      String warehouseCode,
      int offset,
      int size
  ) {
    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.inventory_balances
            WHERE (:itemCode IS NULL OR item_code = :itemCode)
              AND (:warehouseCode IS NULL OR warehouse_code = :warehouseCode)
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .query(Long.class)
        .single();

    List<InventoryBalanceEntity> items = jdbcClient.sql("""
            SELECT item_code, warehouse_code, quantity, updated_at
            FROM dbo.inventory_balances
            WHERE (:itemCode IS NULL OR item_code = :itemCode)
              AND (:warehouseCode IS NULL OR warehouse_code = :warehouseCode)
            ORDER BY item_code, warehouse_code
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new InventoryBalanceEntity(
            rs.getString("item_code"),
            rs.getString("warehouse_code"),
            rs.getBigDecimal("quantity"),
            toInstant(rs.getTimestamp("updated_at"))
        ))
        .list();

    return new InventorySearchResult<>(items, total == null ? 0L : total);
  }

  public InventorySearchResult<InventoryMovementEntity> searchMovements(
      String itemCode,
      String warehouseCode,
      String movementType,
      int offset,
      int size
  ) {
    Long total = jdbcClient.sql("""
            SELECT COUNT(*) AS total
            FROM dbo.inventory_movements
            WHERE (:itemCode IS NULL OR item_code = :itemCode)
              AND (:warehouseCode IS NULL OR warehouse_code = :warehouseCode)
              AND (:movementType IS NULL OR movement_type = :movementType)
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .param("movementType", movementType)
        .query(Long.class)
        .single();

    List<InventoryMovementEntity> items = jdbcClient.sql("""
            SELECT movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at
            FROM dbo.inventory_movements
            WHERE (:itemCode IS NULL OR item_code = :itemCode)
              AND (:warehouseCode IS NULL OR warehouse_code = :warehouseCode)
              AND (:movementType IS NULL OR movement_type = :movementType)
            ORDER BY moved_at DESC, movement_id DESC
            OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .param("movementType", movementType)
        .param("offset", offset)
        .param("size", size)
        .query((rs, rowNum) -> new InventoryMovementEntity(
            toUuid(rs.getObject("movement_id")),
            rs.getString("item_code"),
            rs.getString("warehouse_code"),
            rs.getString("movement_type"),
            rs.getBigDecimal("quantity"),
            rs.getString("reference_no"),
            toInstant(rs.getTimestamp("moved_at"))
        ))
        .list();

    return new InventorySearchResult<>(items, total == null ? 0L : total);
  }

  public Optional<InventoryBalanceEntity> findBalance(String itemCode, String warehouseCode) {
    List<InventoryBalanceEntity> rows = jdbcClient.sql("""
            SELECT item_code, warehouse_code, quantity, updated_at
            FROM dbo.inventory_balances
            WHERE item_code = :itemCode
              AND warehouse_code = :warehouseCode
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .query((rs, rowNum) -> new InventoryBalanceEntity(
            rs.getString("item_code"),
            rs.getString("warehouse_code"),
            rs.getBigDecimal("quantity"),
            toInstant(rs.getTimestamp("updated_at"))
        ))
        .list();
    return rows.stream().findFirst();
  }

  public int updateBalance(String itemCode, String warehouseCode, java.math.BigDecimal quantity, Instant updatedAt) {
    return jdbcClient.sql("""
            UPDATE dbo.inventory_balances
            SET quantity = :quantity,
                updated_at = :updatedAt
            WHERE item_code = :itemCode
              AND warehouse_code = :warehouseCode
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .param("quantity", quantity)
        .param("updatedAt", Timestamp.from(updatedAt))
        .update();
  }

  public void insertBalance(String itemCode, String warehouseCode, java.math.BigDecimal quantity, Instant updatedAt) {
    jdbcClient.sql("""
            INSERT INTO dbo.inventory_balances (item_code, warehouse_code, quantity, updated_at)
            VALUES (:itemCode, :warehouseCode, :quantity, :updatedAt)
        """)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .param("quantity", quantity)
        .param("updatedAt", Timestamp.from(updatedAt))
        .update();
  }

  public void insertMovement(
      UUID movementId,
      String itemCode,
      String warehouseCode,
      String movementType,
      java.math.BigDecimal quantity,
      String referenceNo,
      Instant movedAt
  ) {
    Timestamp movedTimestamp = Timestamp.from(movedAt);
    jdbcClient.sql("""
            INSERT INTO dbo.inventory_movements (
                movement_id, item_code, warehouse_code, movement_type, quantity, reference_no, moved_at, created_at
            ) VALUES (
                :movementId, :itemCode, :warehouseCode, :movementType, :quantity, :referenceNo, :movedAt, :createdAt
            )
        """)
        .param("movementId", movementId)
        .param("itemCode", itemCode)
        .param("warehouseCode", warehouseCode)
        .param("movementType", movementType)
        .param("quantity", quantity)
        .param("referenceNo", referenceNo)
        .param("movedAt", movedTimestamp)
        .param("createdAt", movedTimestamp)
        .update();
  }

  private Instant toInstant(Timestamp value) {
    return value == null ? null : value.toInstant();
  }

  private UUID toUuid(Object value) {
    if (value instanceof UUID uuid) {
      return uuid;
    }
    return UUID.fromString(String.valueOf(value));
  }
}
