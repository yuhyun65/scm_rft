package kr.co.computermate.scmrft.orderlot.service;

import java.util.List;
import kr.co.computermate.scmrft.orderlot.api.LotDetailResponse;
import kr.co.computermate.scmrft.orderlot.api.OrderDetailResponse;
import kr.co.computermate.scmrft.orderlot.api.OrderSummaryResponse;
import kr.co.computermate.scmrft.orderlot.api.PageMetaResponse;
import kr.co.computermate.scmrft.orderlot.api.SearchOrdersResponse;
import kr.co.computermate.scmrft.orderlot.repository.LotEntity;
import kr.co.computermate.scmrft.orderlot.repository.LotRepository;
import kr.co.computermate.scmrft.orderlot.repository.OrderEntity;
import kr.co.computermate.scmrft.orderlot.repository.OrderRepository;
import kr.co.computermate.scmrft.orderlot.repository.OrderSearchResult;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderLotQueryService {
  private static final int MAX_PAGE_SIZE = 200;

  private final OrderRepository orderRepository;
  private final LotRepository lotRepository;

  public OrderLotQueryService(OrderRepository orderRepository, LotRepository lotRepository) {
    this.orderRepository = orderRepository;
    this.lotRepository = lotRepository;
  }

  @Transactional(readOnly = true, timeout = 2)
  public SearchOrdersResponse searchOrders(
      String supplierId,
      String status,
      String keyword,
      int page,
      int size
  ) {
    validatePaging(page, size);
    String normalizedStatus = OrderStatus.normalize(status);
    String normalizedSupplierId = normalizeToNull(supplierId);
    String normalizedKeywordPrefix = normalizeKeywordPrefix(keyword);

    OrderSearchResult result = orderRepository.search(
        normalizedSupplierId,
        normalizedStatus,
        normalizedKeywordPrefix,
        page * size,
        size
    );

    List<OrderSummaryResponse> items = result.items().stream()
        .map(this::toOrderSummary)
        .toList();

    int totalPages = (int) Math.ceil(result.total() / (double) size);
    PageMetaResponse pageMeta = new PageMetaResponse(
        page,
        size,
        result.total(),
        totalPages,
        page + 1 < totalPages
    );

    return new SearchOrdersResponse(items, pageMeta);
  }

  @Transactional(readOnly = true, timeout = 2)
  public OrderDetailResponse getOrderById(String orderId) {
    String normalizedOrderId = requireValue(orderId, "orderId is required.");
    OrderEntity order = orderRepository.findById(normalizedOrderId)
        .orElseThrow(() -> OrderLotApiException.notFound("Order not found."));

    return new OrderDetailResponse(
        order.orderId(),
        order.supplierId(),
        order.status(),
        order.orderedAt(),
        null,
        lotRepository.countByOrderId(order.orderId())
    );
  }

  @Transactional(readOnly = true, timeout = 2)
  public LotDetailResponse getLotById(String lotId) {
    String normalizedLotId = requireValue(lotId, "lotId is required.");
    LotEntity lot = lotRepository.findById(normalizedLotId)
        .orElseThrow(() -> OrderLotApiException.notFound("Lot not found."));

    return new LotDetailResponse(
        lot.lotId(),
        lot.orderId(),
        lot.quantity(),
        lot.status()
    );
  }

  private OrderSummaryResponse toOrderSummary(OrderEntity entity) {
    return new OrderSummaryResponse(
        entity.orderId(),
        entity.supplierId(),
        entity.status(),
        entity.orderedAt()
    );
  }

  private void validatePaging(int page, int size) {
    if (page < 0) {
      throw OrderLotApiException.badRequest("page must be greater than or equal to 0.");
    }
    if (size < 1 || size > MAX_PAGE_SIZE) {
      throw OrderLotApiException.badRequest("size must be between 1 and 200.");
    }
  }

  private String normalizeKeywordPrefix(String keyword) {
    String normalized = normalizeToNull(keyword);
    if (normalized == null) {
      return null;
    }
    return normalized + "%";
  }

  private String requireValue(String value, String message) {
    String normalized = normalizeToNull(value);
    if (normalized == null) {
      throw OrderLotApiException.badRequest(message);
    }
    return normalized;
  }

  private String normalizeToNull(String value) {
    if (value == null) {
      return null;
    }
    String trimmed = value.trim();
    return trimmed.isEmpty() ? null : trimmed;
  }
}
