package kr.co.computermate.scmrft.orderlot.api;

import java.util.List;

public record SearchOrdersResponse(
    List<OrderSummaryResponse> items,
    PageMetaResponse page
) {
}
