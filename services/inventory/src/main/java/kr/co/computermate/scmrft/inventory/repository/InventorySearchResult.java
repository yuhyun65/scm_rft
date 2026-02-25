package kr.co.computermate.scmrft.inventory.repository;

import java.util.List;

public record InventorySearchResult<T>(
    List<T> items,
    long total
) {}
