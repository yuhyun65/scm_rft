package kr.co.computermate.scmrft.gateway.dashboard;

import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.DayOfWeek;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.format.TextStyle;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import kr.co.computermate.scmrft.gateway.policy.GatewayPolicyDocument;
import kr.co.computermate.scmrft.gateway.policy.GatewayRoutePolicyResolver;
import kr.co.computermate.scmrft.gateway.policy.GatewayRoutePolicyResolver.ResolvedRoutePolicy;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

@Service
public class DashboardSummaryService {
  private static final ZoneId KST = ZoneId.of("Asia/Seoul");
  private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(8);
  private static final Set<String> ACTIVE_ORDER_STATUSES = Set.of("PENDING", "CONFIRMED", "IN_PROGRESS");
  private static final Set<String> COMPLETED_ORDER_STATUSES = Set.of("COMPLETED");
  private static final Set<String> CANCELED_ORDER_STATUSES = Set.of("CANCELED");
  private static final List<DayOfWeek> WEEK_DAYS = List.of(
      DayOfWeek.MONDAY,
      DayOfWeek.TUESDAY,
      DayOfWeek.WEDNESDAY,
      DayOfWeek.THURSDAY,
      DayOfWeek.FRIDAY
  );
  private static final Map<String, StockMetadata> STOCK_METADATA = Map.of(
      "ITEM-001", new StockMetadata("부품 ITEM-001", 90L),
      "ITEM-DEMO-01", new StockMetadata("부품 ITEM-DEMO-01", 220L),
      "ITEM-DEMO-02", new StockMetadata("부품 ITEM-DEMO-02", 40L),
      "ITEM-DEMO-03", new StockMetadata("모듈 ITEM-DEMO-03", 80L)
  );

  private final WebClient webClient;
  private final String orderLotTarget;
  private final String inventoryTarget;
  private final String qualityDocTarget;
  private final String boardTarget;

  public DashboardSummaryService(
      WebClient.Builder webClientBuilder,
      GatewayPolicyDocument policy,
      GatewayRoutePolicyResolver resolver
  ) {
    this.webClient = webClientBuilder.build();
    List<ResolvedRoutePolicy> routes = resolver.resolve(policy);
    this.orderLotTarget = resolveTarget(routes, "order-lot");
    this.inventoryTarget = resolveTarget(routes, "inventory");
    this.qualityDocTarget = resolveTarget(routes, "quality-doc");
    this.boardTarget = resolveTarget(routes, "board");
  }

  public Mono<DashboardSummaryResponse> loadSummary() {
    Mono<SearchOrdersPayload> ordersMono = fetch(
        orderLotTarget,
        "/api/order-lot/v1/orders?page=0&size=200",
        SearchOrdersPayload.class,
        SearchOrdersPayload.empty()
    );
    Mono<SearchInventoryBalancesPayload> balancesMono = fetch(
        inventoryTarget,
        "/api/inventory/v1/balances?page=0&size=50",
        SearchInventoryBalancesPayload.class,
        SearchInventoryBalancesPayload.empty()
    );
    Mono<SearchInventoryMovementsPayload> movementsMono = fetch(
        inventoryTarget,
        "/api/inventory/v1/movements?page=0&size=20",
        SearchInventoryMovementsPayload.class,
        SearchInventoryMovementsPayload.empty()
    );
    Mono<SearchQualityDocumentsPayload> qualityDocsMono = fetch(
        qualityDocTarget,
        "/api/quality-doc/v1/documents?page=0&size=20",
        SearchQualityDocumentsPayload.class,
        SearchQualityDocumentsPayload.empty()
    );
    Mono<SearchBoardPostsPayload> boardPostsMono = fetch(
        boardTarget,
        "/api/board/v1/posts?page=0&size=20",
        SearchBoardPostsPayload.class,
        SearchBoardPostsPayload.empty()
    );
    Mono<List<OrderDetailPayload>> orderDetailsMono = ordersMono.flatMap(this::fetchActiveOrderDetails);

    return Mono.zip(ordersMono, orderDetailsMono, balancesMono, movementsMono, qualityDocsMono, boardPostsMono)
        .map(tuple -> buildSummary(
            tuple.getT1(),
            tuple.getT2(),
            tuple.getT3(),
            tuple.getT4(),
            tuple.getT5(),
            tuple.getT6()
        ));
  }

  private DashboardSummaryResponse buildSummary(
      SearchOrdersPayload ordersPayload,
      List<OrderDetailPayload> activeOrderDetails,
      SearchInventoryBalancesPayload balancesPayload,
      SearchInventoryMovementsPayload movementsPayload,
      SearchQualityDocumentsPayload qualityDocsPayload,
      SearchBoardPostsPayload boardPostsPayload
  ) {
    List<OrderSummaryPayload> orders = safeList(ordersPayload.items());
    List<InventoryBalancePayload> balances = safeList(balancesPayload.items());
    List<InventoryMovementPayload> movements = safeList(movementsPayload.items());
    List<QualityDocumentSummaryPayload> qualityDocs = safeList(qualityDocsPayload.items());
    List<BoardPostSummaryPayload> boardPosts = safeList(boardPostsPayload.items());

    LocalDate businessDate = LocalDate.now(KST);
    LocalDate weekStart = businessDate.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
    LocalDate weekEnd = weekStart.plusDays(4);

    List<OrderSummaryPayload> weeklyOrders = orders.stream()
        .filter(order -> isWithinBusinessWeek(order.orderedAt(), weekStart, weekEnd))
        .toList();

    long activeOrders = orders.stream()
        .filter(order -> ACTIVE_ORDER_STATUSES.contains(normalizeStatus(order.status())))
        .count();
    long pendingLots = activeOrderDetails.stream()
        .filter(detail -> ACTIVE_ORDER_STATUSES.contains(normalizeStatus(detail.status())))
        .map(OrderDetailPayload::totalLotCount)
        .filter(Objects::nonNull)
        .mapToLong(Integer::longValue)
        .sum();
    long completedThisWeek = weeklyOrders.stream()
        .filter(order -> COMPLETED_ORDER_STATUSES.contains(normalizeStatus(order.status())))
        .count();
    long canceledThisWeek = weeklyOrders.stream()
        .filter(order -> CANCELED_ORDER_STATUSES.contains(normalizeStatus(order.status())))
        .count();
    long inProgressThisWeek = weeklyOrders.stream()
        .filter(order -> ACTIVE_ORDER_STATUSES.contains(normalizeStatus(order.status())))
        .count();

    List<DashboardSummaryResponse.DailyCount> dailyCounts = WEEK_DAYS.stream()
        .map(day -> {
          LocalDate date = weekStart.with(TemporalAdjusters.nextOrSame(day));
          long count = weeklyOrders.stream()
              .filter(order -> toLocalDate(order.orderedAt()).equals(date))
              .count();
          return new DashboardSummaryResponse.DailyCount(
              day.getDisplayName(TextStyle.SHORT, Locale.KOREAN),
              date.toString(),
              count,
              date.equals(businessDate)
          );
        })
        .toList();

    List<DashboardSummaryResponse.StockAlert> stockAlerts = balances.stream()
        .map(this::toStockAlert)
        .filter(Objects::nonNull)
        .sorted(Comparator.comparingLong((DashboardSummaryResponse.StockAlert alert) -> alert.current() - alert.safety()))
        .limit(3)
        .toList();

    List<DashboardSummaryResponse.Activity> recentActivities = buildRecentActivities(orders, movements, qualityDocs, boardPosts);

    return new DashboardSummaryResponse(
        businessDate.toString(),
        Instant.now(),
        new DashboardSummaryResponse.Kpis(
            activeOrders,
            pendingLots,
            completedThisWeek,
            stockAlerts.size()
        ),
        new DashboardSummaryResponse.WeeklyOrders(
            dailyCounts,
            completedThisWeek,
            inProgressThisWeek,
            canceledThisWeek
        ),
        recentActivities,
        stockAlerts
    );
  }

  private List<DashboardSummaryResponse.Activity> buildRecentActivities(
      List<OrderSummaryPayload> orders,
      List<InventoryMovementPayload> movements,
      List<QualityDocumentSummaryPayload> qualityDocs,
      List<BoardPostSummaryPayload> boardPosts
  ) {
    List<TimelineEvent> timeline = new ArrayList<>();

    orders.stream()
        .sorted(Comparator.comparing(OrderSummaryPayload::orderedAt, Comparator.nullsLast(Comparator.naturalOrder())).reversed())
        .limit(3)
        .forEach(order -> {
          String status = normalizeStatus(order.status());
          String tone = COMPLETED_ORDER_STATUSES.contains(status) ? "success" : (CANCELED_ORDER_STATUSES.contains(status) ? "danger" : "primary");
          String icon = COMPLETED_ORDER_STATUSES.contains(status) ? "완료" : (CANCELED_ORDER_STATUSES.contains(status) ? "취소" : "주문");
          timeline.add(new TimelineEvent(
              order.orderedAt(),
              icon,
              tone,
              "주문 #" + order.orderId() + " 상태 " + status,
              "거래처 " + nullSafe(order.supplierId())
          ));
        });

    movements.stream()
        .sorted(Comparator.comparing(InventoryMovementPayload::movedAt, Comparator.nullsLast(Comparator.naturalOrder())).reversed())
        .limit(3)
        .forEach(movement -> {
          String type = normalizeStatus(movement.movementType());
          String icon = switch (type) {
            case "ADJUST" -> "조정";
            case "OUT" -> "출고";
            default -> "입고";
          };
          String tone = "ADJUST".equals(type) ? "success" : ("OUT".equals(type) ? "warn" : "primary");
          timeline.add(new TimelineEvent(
              movement.movedAt(),
              icon,
              tone,
              "재고 " + icon + " " + movement.itemCode(),
              movement.warehouseCode() + " / 수량 " + toLong(movement.quantity())
          ));
        });

    qualityDocs.stream()
        .sorted(Comparator.comparing(QualityDocumentSummaryPayload::issuedAt, Comparator.nullsLast(Comparator.naturalOrder())).reversed())
        .limit(2)
        .forEach(document -> {
          String status = normalizeStatus(document.status());
          timeline.add(new TimelineEvent(
              document.issuedAt(),
              "품질",
              "ISSUED".equals(status) ? "warn" : "success",
              "품질문서 " + document.title(),
              "상태 " + status
          ));
        });

    boardPosts.stream()
        .sorted(Comparator.comparing(BoardPostSummaryPayload::createdAt, Comparator.nullsLast(Comparator.naturalOrder())).reversed())
        .limit(2)
        .forEach(post -> timeline.add(new TimelineEvent(
            post.createdAt(),
            "게시",
            "primary",
            "게시글 " + post.title(),
            "작성자 " + nullSafe(post.createdBy())
        )));

    return timeline.stream()
        .filter(event -> event.occurredAt() != null)
        .sorted(Comparator.comparing(TimelineEvent::occurredAt).reversed())
        .limit(4)
        .map(event -> new DashboardSummaryResponse.Activity(
            event.icon(),
            event.tone(),
            event.title(),
            event.detail(),
            event.occurredAt()
        ))
        .toList();
  }

  private DashboardSummaryResponse.StockAlert toStockAlert(InventoryBalancePayload balance) {
    StockMetadata metadata = STOCK_METADATA.getOrDefault(
        balance.itemCode(),
        new StockMetadata(balance.itemCode(), Math.max(30L, Math.round(toLong(balance.quantity()) * 1.5d)))
    );
    long current = toLong(balance.quantity());
    long safety = metadata.safety();
    if (current >= safety) {
      return null;
    }
    String level = current * 2 < safety ? "danger" : "warn";
    return new DashboardSummaryResponse.StockAlert(
        balance.itemCode(),
        metadata.name(),
        balance.warehouseCode(),
        current,
        safety,
        level
    );
  }

  private Mono<List<OrderDetailPayload>> fetchActiveOrderDetails(SearchOrdersPayload ordersPayload) {
    List<OrderSummaryPayload> activeOrders = safeList(ordersPayload.items()).stream()
        .filter(order -> ACTIVE_ORDER_STATUSES.contains(normalizeStatus(order.status())))
        .limit(30)
        .toList();

    if (activeOrders.isEmpty()) {
      return Mono.just(List.of());
    }

    return Flux.fromIterable(activeOrders)
        .flatMap(order -> fetch(
            orderLotTarget,
            "/api/order-lot/v1/orders/" + encodePathSegment(order.orderId()),
            OrderDetailPayload.class,
            null
        ).flatMap(detail -> detail == null ? Mono.empty() : Mono.just(detail)), 4)
        .collectList();
  }

  private <T> Mono<T> fetch(String target, String path, Class<T> responseType, T fallback) {
    return webClient.get()
        .uri(target + path)
        .retrieve()
        .bodyToMono(responseType)
        .timeout(REQUEST_TIMEOUT)
        .onErrorResume(error -> Mono.justOrEmpty(fallback));
  }

  private boolean isWithinBusinessWeek(Instant instant, LocalDate weekStart, LocalDate weekEnd) {
    if (instant == null) {
      return false;
    }
    LocalDate date = toLocalDate(instant);
    return !date.isBefore(weekStart) && !date.isAfter(weekEnd);
  }

  private LocalDate toLocalDate(Instant instant) {
    return instant.atZone(KST).toLocalDate();
  }

  private String resolveTarget(List<ResolvedRoutePolicy> routes, String routePrefix) {
    return routes.stream()
        .filter(route -> route.id().equals(routePrefix) || route.id().startsWith(routePrefix + "-"))
        .map(ResolvedRoutePolicy::target)
        .findFirst()
        .orElseThrow(() -> new IllegalStateException("gateway route target not found: " + routePrefix));
  }

  private String normalizeStatus(String value) {
    if (value == null) {
      return "";
    }
    return value.trim().toUpperCase(Locale.ROOT);
  }

  private String encodePathSegment(String value) {
    return URLEncoder.encode(value, StandardCharsets.UTF_8);
  }

  private long toLong(BigDecimal value) {
    if (value == null) {
      return 0L;
    }
    return Math.round(value.doubleValue());
  }

  private String nullSafe(String value) {
    return value == null || value.isBlank() ? "-" : value;
  }

  private <T> List<T> safeList(List<T> items) {
    return items == null ? List.of() : items;
  }

  private record StockMetadata(String name, long safety) {
  }

  private record TimelineEvent(
      Instant occurredAt,
      String icon,
      String tone,
      String title,
      String detail
  ) {
  }

  private record SearchOrdersPayload(
      List<OrderSummaryPayload> items,
      PageMetaPayload page
  ) {
    private static SearchOrdersPayload empty() {
      return new SearchOrdersPayload(List.of(), new PageMetaPayload(0, 0, 0, 0, false));
    }
  }

  private record OrderSummaryPayload(
      String orderId,
      String supplierId,
      String status,
      Instant orderedAt
  ) {
  }

  private record OrderDetailPayload(
      String orderId,
      String supplierId,
      String status,
      Instant orderedAt,
      Instant expectedDeliveryAt,
      Integer totalLotCount
  ) {
  }

  private record SearchInventoryBalancesPayload(
      List<InventoryBalancePayload> items,
      long total,
      int page,
      int size
  ) {
    private static SearchInventoryBalancesPayload empty() {
      return new SearchInventoryBalancesPayload(List.of(), 0L, 0, 0);
    }
  }

  private record InventoryBalancePayload(
      String itemCode,
      String warehouseCode,
      BigDecimal quantity,
      Instant updatedAt
  ) {
  }

  private record SearchInventoryMovementsPayload(
      List<InventoryMovementPayload> items,
      long total,
      int page,
      int size
  ) {
    private static SearchInventoryMovementsPayload empty() {
      return new SearchInventoryMovementsPayload(List.of(), 0L, 0, 0);
    }
  }

  private record InventoryMovementPayload(
      String movementId,
      String itemCode,
      String warehouseCode,
      String movementType,
      BigDecimal quantity,
      String referenceNo,
      Instant movedAt
  ) {
  }

  private record SearchQualityDocumentsPayload(
      List<QualityDocumentSummaryPayload> items,
      PageMetaPayload page
  ) {
    private static SearchQualityDocumentsPayload empty() {
      return new SearchQualityDocumentsPayload(List.of(), new PageMetaPayload(0, 0, 0, 0, false));
    }
  }

  private record QualityDocumentSummaryPayload(
      String documentId,
      String title,
      String status,
      Instant issuedAt
  ) {
  }

  private record SearchBoardPostsPayload(
      List<BoardPostSummaryPayload> items,
      PageMetaPayload page
  ) {
    private static SearchBoardPostsPayload empty() {
      return new SearchBoardPostsPayload(List.of(), new PageMetaPayload(0, 0, 0, 0, false));
    }
  }

  private record BoardPostSummaryPayload(
      String postId,
      String boardType,
      String title,
      String status,
      String createdBy,
      Instant createdAt
  ) {
  }

  private record PageMetaPayload(
      int page,
      int size,
      long totalElements,
      int totalPages,
      boolean hasNext
  ) {
  }
}
