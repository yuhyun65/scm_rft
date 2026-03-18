package kr.co.computermate.scmrft.orderlot.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.format.DateTimeParseException;
import java.util.Locale;
import java.util.Set;
import kr.co.computermate.scmrft.orderlot.api.AddLotRequest;
import kr.co.computermate.scmrft.orderlot.api.CreateOrderRequest;
import kr.co.computermate.scmrft.orderlot.api.LotDetailResponse;
import kr.co.computermate.scmrft.orderlot.api.OrderDetailResponse;
import kr.co.computermate.scmrft.orderlot.api.OrderStatusChangeRequest;
import kr.co.computermate.scmrft.orderlot.api.OrderStatusChangeResponse;
import kr.co.computermate.scmrft.orderlot.api.UpdateOrderRequest;
import kr.co.computermate.scmrft.orderlot.repository.LotRepository;
import kr.co.computermate.scmrft.orderlot.repository.OrderEntity;
import kr.co.computermate.scmrft.orderlot.repository.OrderRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderLotCommandService {
  private static final Set<String> LOT_STATUSES = Set.of("READY", "IN_PROGRESS", "COMPLETED", "CANCELED");

  private final OrderRepository orderRepository;
  private final LotRepository lotRepository;
  private final OrderStatusTransitionPolicy transitionPolicy;

  public OrderLotCommandService(
      OrderRepository orderRepository,
      LotRepository lotRepository,
      OrderStatusTransitionPolicy transitionPolicy
  ) {
    this.orderRepository = orderRepository;
    this.lotRepository = lotRepository;
    this.transitionPolicy = transitionPolicy;
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public OrderStatusChangeResponse changeOrderStatus(String orderId, OrderStatusChangeRequest request) {
    String normalizedOrderId = requireValue(orderId, "orderId is required.");
    String targetStatus = OrderStatus.normalize(request.targetStatus());
    requireValue(request.changedBy(), "changedBy is required.");

    OrderEntity order = orderRepository.findById(normalizedOrderId)
        .orElseThrow(() -> OrderLotApiException.notFound("Order not found."));

    String currentStatus = OrderStatus.normalize(order.status());
    transitionPolicy.assertAllowed(currentStatus, targetStatus);

    int updated = orderRepository.updateStatus(order.orderId(), currentStatus, targetStatus);
    if (updated == 0) {
      throw OrderLotApiException.conflict("Order status changed by another transaction.");
    }

    Instant changedAt = Instant.now();
    return new OrderStatusChangeResponse(order.orderId(), currentStatus, targetStatus, changedAt);
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public OrderDetailResponse createOrder(CreateOrderRequest request) {
    String orderId = requireValue(request.orderId(), "orderId is required.");
    String supplierId = requireValue(request.supplierId(), "supplierId is required.");
    LocalDate orderDate = parseDate(request.orderDate(), "orderDate is invalid. Use yyyy-MM-dd.");
    String status = OrderStatus.normalize(request.status());
    if (status == null) {
      status = OrderStatus.PENDING.name();
    }

    Instant orderedAt = orderDate.atStartOfDay().toInstant(ZoneOffset.UTC);
    try {
      orderRepository.insert(orderId, supplierId, orderDate, status, orderedAt);
    } catch (DataIntegrityViolationException ex) {
      throw OrderLotApiException.conflict("Order already exists.");
    }

    return new OrderDetailResponse(orderId, supplierId, status, orderedAt, null, 0);
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public OrderDetailResponse updateOrder(String orderId, UpdateOrderRequest request) {
    String normalizedOrderId = requireValue(orderId, "orderId is required.");
    String supplierId = requireValue(request.supplierId(), "supplierId is required.");
    LocalDate orderDate = parseDate(request.orderDate(), "orderDate is invalid. Use yyyy-MM-dd.");

    OrderEntity existing = orderRepository.findById(normalizedOrderId)
        .orElseThrow(() -> OrderLotApiException.notFound("Order not found."));
    String currentStatus = OrderStatus.normalize(existing.status());
    if (OrderStatus.COMPLETED.name().equals(currentStatus) || OrderStatus.CANCELED.name().equals(currentStatus)) {
      throw OrderLotApiException.conflict("Completed or canceled order cannot be updated.");
    }

    int updated = orderRepository.updateOrder(normalizedOrderId, supplierId, orderDate);
    if (updated == 0) {
      throw OrderLotApiException.conflict("Order update failed.");
    }

    Instant orderedAt = orderDate.atStartOfDay().toInstant(ZoneOffset.UTC);
    return new OrderDetailResponse(
        normalizedOrderId,
        supplierId,
        existing.status(),
        orderedAt,
        null,
        lotRepository.countByOrderId(normalizedOrderId)
    );
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public LotDetailResponse addLot(String orderId, AddLotRequest request) {
    String normalizedOrderId = requireValue(orderId, "orderId is required.");
    String lotId = requireValue(request.lotId(), "lotId is required.");
    BigDecimal quantity = normalizeLotQuantity(request.quantity());
    String status = normalizeLotStatus(request.status());

    OrderEntity order = orderRepository.findById(normalizedOrderId)
        .orElseThrow(() -> OrderLotApiException.notFound("Order not found."));
    String orderStatus = OrderStatus.normalize(order.status());
    if (OrderStatus.COMPLETED.name().equals(orderStatus) || OrderStatus.CANCELED.name().equals(orderStatus)) {
      throw OrderLotApiException.conflict("Lot cannot be added to completed or canceled order.");
    }
    if (lotRepository.findById(lotId).isPresent()) {
      throw OrderLotApiException.conflict("Lot already exists.");
    }

    try {
      lotRepository.insert(lotId, normalizedOrderId, quantity, status, Instant.now());
    } catch (DataIntegrityViolationException ex) {
      throw OrderLotApiException.conflict("Lot already exists.");
    }
    return new LotDetailResponse(lotId, normalizedOrderId, quantity, status);
  }

  private String requireValue(String value, String message) {
    if (value == null || value.trim().isEmpty()) {
      throw OrderLotApiException.badRequest(message);
    }
    return value.trim();
  }

  private LocalDate parseDate(String value, String message) {
    try {
      return LocalDate.parse(requireValue(value, message));
    } catch (DateTimeParseException ex) {
      throw OrderLotApiException.badRequest(message);
    }
  }

  private BigDecimal normalizeLotQuantity(BigDecimal value) {
    if (value == null || value.compareTo(BigDecimal.ZERO) <= 0) {
      throw OrderLotApiException.badRequest("quantity must be greater than 0.");
    }
    return value.setScale(3, RoundingMode.HALF_UP);
  }

  private String normalizeLotStatus(String value) {
    if (value == null || value.isBlank()) {
      return "READY";
    }
    String normalized = value.trim().toUpperCase(Locale.ROOT);
    if (!LOT_STATUSES.contains(normalized)) {
      throw OrderLotApiException.badRequest("lot status must be READY, IN_PROGRESS, COMPLETED, or CANCELED.");
    }
    return normalized;
  }
}
