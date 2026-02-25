package kr.co.computermate.scmrft.inventory.api;

import java.util.List;

public record SearchInventoryMovementsResponse(
    List<InventoryMovementResponse> items,
    long total,
    int page,
    int size
) {}
