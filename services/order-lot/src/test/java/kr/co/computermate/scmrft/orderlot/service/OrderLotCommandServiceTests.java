package kr.co.computermate.scmrft.orderlot.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.Optional;
import kr.co.computermate.scmrft.orderlot.api.OrderStatusChangeRequest;
import kr.co.computermate.scmrft.orderlot.api.OrderStatusChangeResponse;
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

  @Test
  void changesOrderStatusWhenTransitionIsValid() {
    OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, policy);
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
    OrderLotCommandService service = new OrderLotCommandService(orderRepository, policy);
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
}
