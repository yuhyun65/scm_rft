package kr.co.computermate.scmrft.orderlot.api;

import jakarta.validation.Valid;
import kr.co.computermate.scmrft.orderlot.service.OrderLotCommandService;
import kr.co.computermate.scmrft.orderlot.service.OrderLotQueryService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/order-lot/v1")
public class OrderLotController {
  private final OrderLotQueryService queryService;
  private final OrderLotCommandService commandService;

  public OrderLotController(
      OrderLotQueryService queryService,
      OrderLotCommandService commandService
  ) {
    this.queryService = queryService;
    this.commandService = commandService;
  }

  @GetMapping("/orders")
  public SearchOrdersResponse searchOrders(
      @RequestParam(value = "supplierId", required = false) String supplierId,
      @RequestParam(value = "status", required = false) String status,
      @RequestParam(value = "keyword", required = false) String keyword,
      @RequestParam(value = "page", defaultValue = "0") int page,
      @RequestParam(value = "size", defaultValue = "20") int size
  ) {
    return queryService.searchOrders(supplierId, status, keyword, page, size);
  }

  @GetMapping("/orders/{orderId}")
  public OrderDetailResponse getOrderById(@PathVariable("orderId") String orderId) {
    return queryService.getOrderById(orderId);
  }

  @GetMapping("/lots/{lotId}")
  public LotDetailResponse getLotById(@PathVariable("lotId") String lotId) {
    return queryService.getLotById(lotId);
  }

  @PostMapping("/orders")
  public ResponseEntity<OrderDetailResponse> createOrder(@Valid @RequestBody CreateOrderRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(commandService.createOrder(request));
  }

  @PutMapping("/orders/{orderId}")
  public ResponseEntity<OrderDetailResponse> updateOrder(
      @PathVariable("orderId") String orderId,
      @Valid @RequestBody UpdateOrderRequest request
  ) {
    return ResponseEntity.ok(commandService.updateOrder(orderId, request));
  }

  @PostMapping("/orders/{orderId}/lots")
  public ResponseEntity<LotDetailResponse> addLot(
      @PathVariable("orderId") String orderId,
      @Valid @RequestBody AddLotRequest request
  ) {
    return ResponseEntity.status(HttpStatus.CREATED).body(commandService.addLot(orderId, request));
  }

  @PostMapping("/orders/{orderId}/status")
  public ResponseEntity<OrderStatusChangeResponse> changeOrderStatus(
      @PathVariable("orderId") String orderId,
      @Valid @RequestBody OrderStatusChangeRequest request
  ) {
    return ResponseEntity.ok(commandService.changeOrderStatus(orderId, request));
  }
}
