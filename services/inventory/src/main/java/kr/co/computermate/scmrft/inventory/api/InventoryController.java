package kr.co.computermate.scmrft.inventory.api;

import kr.co.computermate.scmrft.inventory.service.InventoryService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/inventory/v1")
public class InventoryController {
  private final InventoryService inventoryService;

  public InventoryController(InventoryService inventoryService) {
    this.inventoryService = inventoryService;
  }

  @GetMapping("/balances")
  public SearchInventoryBalancesResponse searchBalances(
      @RequestParam(value = "itemCode", required = false) String itemCode,
      @RequestParam(value = "warehouseCode", required = false) String warehouseCode,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "50") int size
  ) {
    return inventoryService.searchBalances(itemCode, warehouseCode, page, size);
  }

  @GetMapping("/movements")
  public SearchInventoryMovementsResponse searchMovements(
      @RequestParam(value = "itemCode", required = false) String itemCode,
      @RequestParam(value = "warehouseCode", required = false) String warehouseCode,
      @RequestParam(value = "movementType", required = false) String movementType,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "50") int size
  ) {
    return inventoryService.searchMovements(itemCode, warehouseCode, movementType, page, size);
  }
}
