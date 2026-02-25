package kr.co.computermate.scmrft.inventory.api;

import java.util.List;

public record SearchInventoryBalancesResponse(
    List<InventoryBalanceResponse> items,
    long total,
    int page,
    int size
) {}
