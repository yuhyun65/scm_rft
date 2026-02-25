package kr.co.computermate.scmrft.inventory.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import kr.co.computermate.scmrft.inventory.api.SearchInventoryBalancesResponse;
import kr.co.computermate.scmrft.inventory.api.SearchInventoryMovementsResponse;
import kr.co.computermate.scmrft.inventory.repository.InventoryBalanceEntity;
import kr.co.computermate.scmrft.inventory.repository.InventoryMovementEntity;
import kr.co.computermate.scmrft.inventory.repository.InventoryRepository;
import kr.co.computermate.scmrft.inventory.repository.InventorySearchResult;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class InventoryServiceTests {
  @Mock
  private InventoryRepository inventoryRepository;

  @Test
  void searchBalancesReturnsMappedResponse() {
    InventoryService service = new InventoryService(inventoryRepository);
    when(inventoryRepository.searchBalances("ITEM-1", "WH-1", 0, 50))
        .thenReturn(new InventorySearchResult<>(
            List.of(new InventoryBalanceEntity("ITEM-1", "WH-1", new BigDecimal("100.5"), Instant.now())),
            1L
        ));

    SearchInventoryBalancesResponse response = service.searchBalances("ITEM-1", "WH-1", 0, 50);

    assertThat(response.total()).isEqualTo(1L);
    assertThat(response.items()).hasSize(1);
    assertThat(response.items().get(0).itemCode()).isEqualTo("ITEM-1");
  }

  @Test
  void searchMovementsRejectsInvalidType() {
    InventoryService service = new InventoryService(inventoryRepository);

    assertThatThrownBy(() -> service.searchMovements(null, null, "BAD", 0, 50))
        .isInstanceOf(InventoryApiException.class)
        .hasMessageContaining("movementType");
  }

  @Test
  void searchMovementsReturnsMappedResponse() {
    InventoryService service = new InventoryService(inventoryRepository);
    when(inventoryRepository.searchMovements(null, null, "IN", 0, 50))
        .thenReturn(new InventorySearchResult<>(
            List.of(new InventoryMovementEntity(
                UUID.randomUUID(),
                "ITEM-2",
                "WH-2",
                "IN",
                new BigDecimal("30"),
                "REF-1",
                Instant.now()
            )),
            1L
        ));

    SearchInventoryMovementsResponse response = service.searchMovements(null, null, "IN", 0, 50);

    assertThat(response.total()).isEqualTo(1L);
    assertThat(response.items()).hasSize(1);
    assertThat(response.items().get(0).movementType()).isEqualTo("IN");
  }
}
