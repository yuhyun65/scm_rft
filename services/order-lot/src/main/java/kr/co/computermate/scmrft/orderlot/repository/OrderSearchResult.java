package kr.co.computermate.scmrft.orderlot.repository;

import java.util.List;

public record OrderSearchResult(
    List<OrderEntity> items,
    long total
) {
}
