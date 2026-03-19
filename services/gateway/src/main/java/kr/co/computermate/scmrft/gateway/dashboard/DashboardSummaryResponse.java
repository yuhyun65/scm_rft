package kr.co.computermate.scmrft.gateway.dashboard;

import java.time.Instant;
import java.util.List;

public record DashboardSummaryResponse(
    String businessDate,
    Instant generatedAt,
    Kpis kpis,
    WeeklyOrders weeklyOrders,
    List<Activity> recentActivities,
    List<StockAlert> stockAlerts,
    DrillDowns drillDowns
) {
  public record Kpis(
      long activeOrders,
      long pendingLots,
      long completedThisWeek,
      long stockAlertCount
  ) {
  }

  public record WeeklyOrders(
      List<DailyCount> items,
      long completed,
      long inProgress,
      long canceled
  ) {
  }

  public record DailyCount(
      String day,
      String date,
      long count,
      boolean accent
  ) {
  }

  public record Activity(
      String icon,
      String tone,
      String title,
      String detail,
      Instant occurredAt
  ) {
  }

  public record StockAlert(
      String code,
      String name,
      String warehouseCode,
      long current,
      long safety,
      String level
  ) {
  }

  public record DrillDowns(
      List<OrderItem> activeOrders,
      List<OrderItem> pendingLots,
      List<OrderItem> completedOrders,
      List<StockAlert> stockAlerts
  ) {
  }

  public record OrderItem(
      String orderId,
      String supplierId,
      String status,
      Instant orderedAt,
      Integer totalLotCount
  ) {
  }
}
