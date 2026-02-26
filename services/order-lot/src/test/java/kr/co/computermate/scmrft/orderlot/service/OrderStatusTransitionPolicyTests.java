package kr.co.computermate.scmrft.orderlot.service;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class OrderStatusTransitionPolicyTests {
  private final OrderStatusTransitionPolicy policy = new OrderStatusTransitionPolicy();

  @Test
  void allowsValidTransition() {
    assertThatCode(() -> policy.assertAllowed("PENDING", "CONFIRMED"))
        .doesNotThrowAnyException();
  }

  @Test
  void rejectsInvalidTransition() {
    assertThatThrownBy(() -> policy.assertAllowed("COMPLETED", "IN_PROGRESS"))
        .isInstanceOf(OrderLotApiException.class)
        .hasMessageContaining("not allowed");
  }
}
