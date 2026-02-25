package kr.co.computermate.scmrft.inventory.service;

import java.util.List;
import java.util.Locale;
import kr.co.computermate.scmrft.inventory.api.InventoryBalanceResponse;
import kr.co.computermate.scmrft.inventory.api.InventoryMovementResponse;
import kr.co.computermate.scmrft.inventory.api.SearchInventoryBalancesResponse;
import kr.co.computermate.scmrft.inventory.api.SearchInventoryMovementsResponse;
import kr.co.computermate.scmrft.inventory.repository.InventoryBalanceEntity;
import kr.co.computermate.scmrft.inventory.repository.InventoryMovementEntity;
import kr.co.computermate.scmrft.inventory.repository.InventoryRepository;
import kr.co.computermate.scmrft.inventory.repository.InventorySearchResult;
import org.springframework.stereotype.Service;

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
}
