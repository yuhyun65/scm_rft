package kr.co.computermate.scmrft.orderlot.service;

import java.time.Instant;
import kr.co.computermate.scmrft.orderlot.api.OrderStatusChangeRequest;
import kr.co.computermate.scmrft.orderlot.api.OrderStatusChangeResponse;
import kr.co.computermate.scmrft.orderlot.repository.OrderEntity;
import kr.co.computermate.scmrft.orderlot.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OrderLotCommandService {
  private final OrderRepository orderRepository;
  private final OrderStatusTransitionPolicy transitionPolicy;

  public OrderLotCommandService(
      OrderRepository orderRepository,
      OrderStatusTransitionPolicy transitionPolicy
  ) {
    this.orderRepository = orderRepository;
    this.transitionPolicy = transitionPolicy;
  }

  @Transactional(timeout = 3, isolation = Isolation.READ_COMMITTED)
  public OrderStatusChangeResponse changeOrderStatus(String orderId, OrderStatusChangeRequest request) {
    String normalizedOrderId = requireValue(orderId, "orderId is required.");
    String targetStatus = OrderStatus.normalize(request.targetStatus());
    String changedBy = requireValue(request.changedBy(), "changedBy is required.");

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

  private String requireValue(String value, String message) {
    if (value == null || value.trim().isEmpty()) {
      throw OrderLotApiException.badRequest(message);
    }
    return value.trim();
  }
}
