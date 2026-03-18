package kr.co.computermate.scmrft.orderlot.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
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
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class OrderLotCommandServiceTests {
  @Mock
  private OrderRepository orderRepository;
  @Mock
  private LotRepository lotRepository;

  @Test
  void changesOrderStatusWhenTransitionIsValid() {
    OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, lotRepository, policy);
    OrderEntity entity = new OrderEntity("ORD-001", "SUP-1", "PENDING", Instant.now());

    when(orderRepository.findById("ORD-001")).thenReturn(Optional.of(entity));
    when(orderRepository.updateStatus("ORD-001", "PENDING", "CONFIRMED")).thenReturn(1);

    OrderStatusChangeResponse response = service.changeOrderStatus(
        "ORD-001",
        new OrderStatusChangeRequest("CONFIRMED", "tester", "approve")
    );

    assertThat(response.orderId()).isEqualTo("ORD-001");
    assertThat(response.beforeStatus()).isEqualTo("PENDING");
    assertThat(response.afterStatus()).isEqualTo("CONFIRMED");
    verify(orderRepository).updateStatus("ORD-001", "PENDING", "CONFIRMED");
  }

  @Test
  void throwsConflictWhenConcurrentUpdateDetected() {
    OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, lotRepository, policy);
    OrderEntity entity = new OrderEntity("ORD-001", "SUP-1", "PENDING", Instant.now());

    when(orderRepository.findById("ORD-001")).thenReturn(Optional.of(entity));
    when(orderRepository.updateStatus("ORD-001", "PENDING", "CONFIRMED")).thenReturn(0);

    assertThatThrownBy(() -> service.changeOrderStatus(
        "ORD-001",
        new OrderStatusChangeRequest("CONFIRMED", "tester", null)
    ))
        .isInstanceOf(OrderLotApiException.class)
        .hasMessageContaining("another transaction");
  }

  @Test
  void createOrderReturnsCreatedDetail() {
    OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, lotRepository, policy);

    OrderDetailResponse response = service.createOrder(
        new CreateOrderRequest("ORD-NEW", "SUP-1", "2026-03-18", "PENDING")
    );

    assertThat(response.orderId()).isEqualTo("ORD-NEW");
    assertThat(response.supplierId()).isEqualTo("SUP-1");
    assertThat(response.status()).isEqualTo("PENDING");
    verify(orderRepository).insert(eq("ORD-NEW"), eq("SUP-1"), eq(java.time.LocalDate.parse("2026-03-18")), eq("PENDING"), any());
  }

  @Test
  void updateOrderReturnsUpdatedDetail() {
    OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, lotRepository, policy);
    when(orderRepository.findById("ORD-001"))
        .thenReturn(Optional.of(new OrderEntity("ORD-001", "SUP-OLD", "CONFIRMED", Instant.now())));
    when(orderRepository.updateOrder("ORD-001", "SUP-NEW", java.time.LocalDate.parse("2026-03-18"))).thenReturn(1);
    when(lotRepository.countByOrderId("ORD-001")).thenReturn(2);

    OrderDetailResponse response = service.updateOrder(
        "ORD-001",
        new UpdateOrderRequest("SUP-NEW", "2026-03-18")
    );

    assertThat(response.supplierId()).isEqualTo("SUP-NEW");
    assertThat(response.totalLotCount()).isEqualTo(2);
  }

  @Test
  void addLotReturnsCreatedLot() {
    OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, lotRepository, policy);
    when(orderRepository.findById("ORD-001"))
        .thenReturn(Optional.of(new OrderEntity("ORD-001", "SUP-1", "CONFIRMED", Instant.now())));
    when(lotRepository.findById("LOT-NEW")).thenReturn(Optional.empty());

    LotDetailResponse response = service.addLot(
        "ORD-001",
        new AddLotRequest("LOT-NEW", new BigDecimal("3.000"), "READY")
    );

    assertThat(response.lotId()).isEqualTo("LOT-NEW");
    assertThat(response.orderId()).isEqualTo("ORD-001");
    verify(lotRepository).insert(eq("LOT-NEW"), eq("ORD-001"), eq(new BigDecimal("3.000")), eq("READY"), any());
  }
}
