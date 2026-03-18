package kr.co.computermate.scmrft.inventory.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import kr.co.computermate.scmrft.inventory.api.InventoryAdjustmentRequest;
import kr.co.computermate.scmrft.inventory.api.InventoryAdjustmentResponse;
import kr.co.computermate.scmrft.inventory.api.InventoryBalanceResponse;
import kr.co.computermate.scmrft.inventory.api.InventoryMovementResponse;
import kr.co.computermate.scmrft.inventory.api.SearchInventoryBalancesResponse;
import kr.co.computermate.scmrft.inventory.api.SearchInventoryMovementsResponse;
import kr.co.computermate.scmrft.inventory.repository.InventoryBalanceEntity;
import kr.co.computermate.scmrft.inventory.repository.InventoryMovementEntity;
import kr.co.computermate.scmrft.inventory.repository.InventoryRepository;
import kr.co.computermate.scmrft.inventory.repository.InventorySearchResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InventoryService {
  private static final int MAX_PAGE_SIZE = 200;

  private final InventoryRepository inventoryRepository;

  public InventoryService(InventoryRepository inventoryRepository) {
    this.inventoryRepository = inventoryRepository;
  }

  public SearchInventoryBalancesResponse searchBalances(
      String itemCode,
      String warehouseCode,
      int page,
      int size
  ) {
    validatePaging(page, size);

    InventorySearchResult<InventoryBalanceEntity> result = inventoryRepository.searchBalances(
        normalize(itemCode),
        normalize(warehouseCode),
        page * size,
        size
    );

    List<InventoryBalanceResponse> items = result.items().stream()
        .map(this::toBalanceResponse)
        .toList();

    return new SearchInventoryBalancesResponse(items, result.total(), page, size);
  }

  public SearchInventoryMovementsResponse searchMovements(
      String itemCode,
      String warehouseCode,
      String movementType,
      int page,
      int size
  ) {
    validatePaging(page, size);
    String normalizedMovementType = normalizeMovementType(movementType);

    InventorySearchResult<InventoryMovementEntity> result = inventoryRepository.searchMovements(
        normalize(itemCode),
        normalize(warehouseCode),
        normalizedMovementType,
        page * size,
        size
    );

    List<InventoryMovementResponse> items = result.items().stream()
        .map(this::toMovementResponse)
        .toList();

    return new SearchInventoryMovementsResponse(items, result.total(), page, size);
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public InventoryAdjustmentResponse adjustInventory(InventoryAdjustmentRequest request) {
    String itemCode = requireValue(request.itemCode(), "itemCode is required.");
    String warehouseCode = requireValue(request.warehouseCode(), "warehouseCode is required.");
    BigDecimal quantityDelta = normalizeDelta(request.quantityDelta());
    String referenceNo = normalize(request.referenceNo());

    InventoryBalanceEntity existing = inventoryRepository.findBalance(itemCode, warehouseCode).orElse(null);
    BigDecimal currentQuantity = existing == null ? BigDecimal.ZERO : existing.quantity();
    BigDecimal resultingQuantity = currentQuantity.add(quantityDelta).setScale(3, RoundingMode.HALF_UP);
    if (resultingQuantity.compareTo(BigDecimal.ZERO) < 0) {
      throw InventoryApiException.badRequest("resulting quantity must be greater than or equal to 0.");
    }

    UUID movementId = UUID.randomUUID();
    java.time.Instant adjustedAt = java.time.Instant.now();
    inventoryRepository.insertMovement(
        movementId,
        itemCode,
        warehouseCode,
        "ADJUST",
        quantityDelta,
        referenceNo,
        adjustedAt
    );

    if (existing == null) {
      inventoryRepository.insertBalance(itemCode, warehouseCode, resultingQuantity, adjustedAt);
    } else {
      inventoryRepository.updateBalance(itemCode, warehouseCode, resultingQuantity, adjustedAt);
    }

    return new InventoryAdjustmentResponse(
        movementId.toString(),
        itemCode,
        warehouseCode,
        quantityDelta,
        resultingQuantity,
        referenceNo,
        adjustedAt
    );
  }

  private void validatePaging(int page, int size) {
    if (page < 0) {
      throw InventoryApiException.badRequest("page must be greater than or equal to 0.");
    }
    if (size < 1 || size > MAX_PAGE_SIZE) {
      throw InventoryApiException.badRequest("size must be between 1 and 200.");
    }
  }

  private String normalizeMovementType(String movementType) {
    String normalized = normalize(movementType);
    if (normalized == null) {
      return null;
    }

    String upper = normalized.toUpperCase(Locale.ROOT);
    if (!"IN".equals(upper) && !"OUT".equals(upper) && !"ADJUST".equals(upper)) {
      throw InventoryApiException.badRequest("movementType must be IN, OUT, or ADJUST.");
    }
    return upper;
  }

  private BigDecimal normalizeDelta(BigDecimal value) {
    if (value == null) {
      throw InventoryApiException.badRequest("quantityDelta is required.");
    }
    if (value.compareTo(BigDecimal.ZERO) == 0) {
      throw InventoryApiException.badRequest("quantityDelta must not be 0.");
    }
    return value.setScale(3, RoundingMode.HALF_UP);
  }

  private InventoryBalanceResponse toBalanceResponse(InventoryBalanceEntity entity) {
    return new InventoryBalanceResponse(
        entity.itemCode(),
        entity.warehouseCode(),
        entity.quantity(),
        entity.updatedAt()
    );
  }

  private InventoryMovementResponse toMovementResponse(InventoryMovementEntity entity) {
    return new InventoryMovementResponse(
        entity.movementId(),
        entity.itemCode(),
        entity.warehouseCode(),
        entity.movementType(),
        entity.quantity(),
        entity.referenceNo(),
        entity.movedAt()
    );
  }

  private String normalize(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }

  private String requireValue(String value, String message) {
    String normalized = normalize(value);
    if (normalized == null) {
      throw InventoryApiException.badRequest(message);
    }
    return normalized;
  }
}
