import { useEffect, useMemo, useState } from "react";
import type {
  DashboardActivity,
  DashboardOrderItem,
  DashboardStockAlert,
  DashboardSummaryResponse,
} from "@scm-rft/api-client";
import KpiCard from "../components/KpiCard";
import { formatCount, formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

type KpiModalState =
  | {
      title: string;
      description: string;
      type: "orders";
      orderItems: DashboardOrderItem[];
    }
  | {
      title: string;
      description: string;
      type: "stocks";
      stockItems: DashboardStockAlert[];
    };

function formatBusinessDate(value?: string | null) {
  if (!value) {
    return "-";
  }

  const [year, month, day] = value.split("-");
  if (!year || !month || !day) {
    return value;
  }

  return `${year}년 ${Number(month)}월 ${Number(day)}일`;
}

function getToneClass(tone: string) {
  if (tone === "danger") {
    return "warn";
  }
  return tone;
}

export default function DashboardPage() {
  const client = useScmApiClient();
  const [loading, setLoading] = useState(true);
  const [errorText, setErrorText] = useState("");
  const [summary, setSummary] = useState<DashboardSummaryResponse | null>(null);
  const [selectedActivity, setSelectedActivity] = useState<DashboardActivity | null>(null);
  const [selectedKpi, setSelectedKpi] = useState<KpiModalState | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadSummary() {
      setLoading(true);
      setErrorText("");
      try {
        const result = await client.getDashboardSummary();
        if (!cancelled) {
          setSummary(result);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setSummary(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadSummary();
    return () => {
      cancelled = true;
    };
  }, [client]);

  const weeklyItems = summary?.weeklyOrders.items ?? [];
  const maxWeeklyCount = useMemo(() => Math.max(1, ...weeklyItems.map((item) => item.count)), [weeklyItems]);

  function getBarHeight(count: number) {
    if (count <= 0) {
      return 12;
    }
    return Math.max(24, Math.round((count / maxWeeklyCount) * 100));
  }

  function handleActivityKeyDown(event: React.KeyboardEvent<HTMLDivElement>, activity: DashboardActivity) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      setSelectedActivity(activity);
    }
  }

  function openKpiModal(kind: "active" | "pending" | "completed" | "stock") {
    if (!summary) {
      return;
    }

    switch (kind) {
      case "active":
        setSelectedKpi({
          title: "진행 중 주문 목록",
          description: "PENDING / CONFIRMED / IN_PROGRESS 상태 주문 목록입니다.",
          type: "orders",
          orderItems: summary.drillDowns.activeOrders,
        });
        return;
      case "pending":
        setSelectedKpi({
          title: "검토 대기 LOT 연결 주문 목록",
          description: "연결된 LOT 건수가 있는 진행 중 주문 목록입니다.",
          type: "orders",
          orderItems: summary.drillDowns.pendingLots,
        });
        return;
      case "completed":
        setSelectedKpi({
          title: "이번 주 완료 주문 목록",
          description: "이번 주에 COMPLETED 상태인 주문 목록입니다.",
          type: "orders",
          orderItems: summary.drillDowns.completedOrders,
        });
        return;
      case "stock":
        setSelectedKpi({
          title: "재고 경고 품목 목록",
          description: "안전재고 미달 품목 전체 목록입니다.",
          type: "stocks",
          stockItems: summary.drillDowns.stockAlerts,
        });
    }
  }

  return (
    <div className="page-body">
      <div className="page-title">
        대시보드
        <span style={{ fontSize: 13, fontWeight: 400, color: "var(--color-gray-400)" }}>
          {" "}
          / {formatBusinessDate(summary?.businessDate)}
        </span>
      </div>

      {errorText && (
        <div className="alert-banner danger">
          <div>
            <div className="alert-title">대시보드 집계 조회 실패</div>
            <div className="alert-desc">{errorText}</div>
          </div>
        </div>
      )}

      <div className="kpi-grid">
        <KpiCard
          label="진행 중 주문"
          value={
            <button
              type="button"
              className="kpi-value-button"
              onClick={() => openKpiModal("active")}
              disabled={loading || !summary}
            >
              {loading ? "..." : formatCount(summary?.kpis.activeOrders)}
            </button>
          }
          sub="PENDING / CONFIRMED / IN_PROGRESS 기준"
        />
        <KpiCard
          label="검토 대기 LOT"
          value={
            <button
              type="button"
              className="kpi-value-button"
              onClick={() => openKpiModal("pending")}
              disabled={loading || !summary}
            >
              {loading ? "..." : formatCount(summary?.kpis.pendingLots)}
            </button>
          }
          variant="warn"
          sub="연결 LOT 건수 합계"
        />
        <KpiCard
          label="이번 주 완료"
          value={
            <button
              type="button"
              className="kpi-value-button"
              onClick={() => openKpiModal("completed")}
              disabled={loading || !summary}
            >
              {loading ? "..." : formatCount(summary?.kpis.completedThisWeek)}
            </button>
          }
          variant="success"
          sub="금주 COMPLETED 주문 수"
        />
        <KpiCard
          label="재고 경고 품목"
          value={
            <button
              type="button"
              className="kpi-value-button"
              onClick={() => openKpiModal("stock")}
              disabled={loading || !summary}
            >
              {loading ? "..." : formatCount(summary?.kpis.stockAlertCount)}
            </button>
          }
          variant="danger"
          sub="안전재고 미달 품목"
        />
      </div>

      <div className="grid-2">
        <div className="card">
          <div className="card-header">
            <span className="card-title">이번 주 주문 현황</span>
          </div>
          <div className="card-body">
            <div className="fs-11 text-muted">생성 시각: {formatDateTime(summary?.generatedAt)}</div>
            <div
              style={{
                display: "flex",
                alignItems: "stretch",
                gap: 12,
                height: 180,
                padding: "12px 0 16px",
              }}
            >
              {weeklyItems.length === 0 ? (
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    width: "100%",
                    color: "var(--color-gray-400)",
                    fontSize: 12,
                    border: "1px dashed var(--color-gray-200)",
                    borderRadius: 8,
                  }}
                >
                  {loading ? "주문 현황을 불러오는 중입니다." : "이번 주 주문 데이터가 없습니다."}
                </div>
              ) : (
                weeklyItems.map((item) => (
                  <div
                    key={item.date}
                    style={{
                      flex: 1,
                      minWidth: 0,
                      display: "flex",
                      flexDirection: "column",
                      justifyContent: "flex-end",
                      alignItems: "stretch",
                      gap: 8,
                    }}
                  >
                    <div className="text-center fs-11 text-muted">{formatCount(item.count)}건</div>
                    <div style={{ flex: 1, display: "flex", alignItems: "flex-end" }}>
                      <div
                        style={{
                          width: "100%",
                          minHeight: item.count === 0 ? 12 : 24,
                          height: `${getBarHeight(item.count)}%`,
                          background: item.accent ? "var(--color-primary)" : "var(--color-primary-light)",
                          borderRadius: "6px 6px 0 0",
                          transition: "height .2s ease",
                        }}
                      />
                    </div>
                    <span className="text-center fs-11 text-muted">{item.day}</span>
                  </div>
                ))
              )}
            </div>
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                fontSize: 11,
                color: "var(--color-gray-400)",
                paddingTop: 8,
                borderTop: "1px solid var(--color-gray-100)",
              }}
            >
              <span>
                완료: <strong className="text-success">{formatCount(summary?.weeklyOrders.completed)}건</strong>
              </span>
              <span>
                처리 중: <strong className="text-primary">{formatCount(summary?.weeklyOrders.inProgress)}건</strong>
              </span>
              <span>
                취소: <strong className="text-danger">{formatCount(summary?.weeklyOrders.canceled)}건</strong>
              </span>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">최근 활동</span>
          </div>
          <div className="card-body" style={{ padding: "12px 16px" }}>
            <div className="timeline">
              {summary?.recentActivities.length ? (
                summary.recentActivities.map((activity) => (
                  <div
                    key={`${activity.title}-${activity.occurredAt}`}
                    className="tl-item tl-item-clickable"
                    role="button"
                    tabIndex={0}
                    onClick={() => setSelectedActivity(activity)}
                    onKeyDown={(event) => handleActivityKeyDown(event, activity)}
                  >
                    <div className={`tl-dot ${getToneClass(activity.tone)}`}>{activity.icon}</div>
                    <div>
                      <div className="tl-title">{activity.title}</div>
                      <div className="tl-time">
                        {formatDateTime(activity.occurredAt)} / {activity.detail}
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="fs-12 text-muted">
                  {loading ? "최근 활동을 불러오는 중입니다." : "표시할 최근 활동이 없습니다."}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">주요 재고 경고 품목</span>
        </div>
        <div className="card-body">
          {summary?.stockAlerts.length ? (
            <div className="grid-3">
              {summary.stockAlerts.map((stock) => (
                <div
                  key={`${stock.code}-${stock.warehouseCode}`}
                  style={{
                    padding: "10px 14px",
                    border: `1px solid ${stock.level === "danger" ? "#fee2e2" : "#fef3c7"}`,
                    borderRadius: 6,
                    background: stock.level === "danger" ? "#fff5f5" : "#fffbeb",
                  }}
                >
                  <div className="fw-700">
                    {stock.name} ({stock.code})
                  </div>
                  <div className="fs-11 text-muted mt-4">
                    창고: {stock.warehouseCode} / 현재: {formatCount(stock.current)}개 / 안전재고: {formatCount(stock.safety)}개
                  </div>
                  <div className="stock-bar mt-4">
                    <div
                      className={`stock-bar-fill ${stock.level}`}
                      style={{ width: `${Math.min(100, Math.round((stock.current / stock.safety) * 100))}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="alert-banner success" style={{ marginBottom: 0 }}>
              <div>
                <div className="alert-title">재고 경고 없음</div>
                <div className="alert-desc">
                  {loading ? "재고 경고 품목을 불러오는 중입니다." : "현재 기준으로 안전재고 미달 품목이 없습니다."}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {selectedActivity && (
        <div className="modal-backdrop" onClick={() => setSelectedActivity(null)}>
          <div
            className="modal-card"
            onClick={(event) => event.stopPropagation()}
            role="dialog"
            aria-modal="true"
            aria-labelledby="dashboard-activity-title"
          >
            <div className="card-header">
              <span className="card-title" id="dashboard-activity-title">
                최근 활동 상세
              </span>
              <button type="button" className="btn btn-gray btn-sm" onClick={() => setSelectedActivity(null)}>
                닫기
              </button>
            </div>
            <div className="card-body">
              <div className="detail-row">
                <div className="detail-label">유형</div>
                <div className="detail-value">{selectedActivity.icon}</div>
              </div>
              <div className="detail-row">
                <div className="detail-label">제목</div>
                <div className="detail-value">{selectedActivity.title}</div>
              </div>
              <div className="detail-row">
                <div className="detail-label">발생 시각</div>
                <div className="detail-value">{formatDateTime(selectedActivity.occurredAt)}</div>
              </div>
              <div className="detail-row">
                <div className="detail-label">상태 톤</div>
                <div className="detail-value">{selectedActivity.tone}</div>
              </div>
              <div className="detail-row">
                <div className="detail-label">상세 내용</div>
                <div className="detail-value">{selectedActivity.detail}</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {selectedKpi && (
        <div className="modal-backdrop" onClick={() => setSelectedKpi(null)}>
          <div
            className="modal-card"
            style={{ width: "min(760px, 100%)" }}
            onClick={(event) => event.stopPropagation()}
            role="dialog"
            aria-modal="true"
            aria-labelledby="dashboard-kpi-title"
          >
            <div className="card-header">
              <div>
                <div className="card-title" id="dashboard-kpi-title">
                  {selectedKpi.title}
                </div>
                <div className="fs-11 text-muted mt-4">{selectedKpi.description}</div>
              </div>
              <button type="button" className="btn btn-gray btn-sm" onClick={() => setSelectedKpi(null)}>
                닫기
              </button>
            </div>
            <div className="card-body">
              {selectedKpi.type === "orders" ? (
                selectedKpi.orderItems.length ? (
                  <div className="tbl-wrap">
                    <table>
                      <thead>
                        <tr>
                          <th>주문번호</th>
                          <th>거래처</th>
                          <th>상태</th>
                          <th>주문일시</th>
                          <th className="text-right">연결 LOT</th>
                        </tr>
                      </thead>
                      <tbody>
                        {selectedKpi.orderItems.map((item) => (
                          <tr key={`${selectedKpi.title}-${item.orderId}`}>
                            <td>{item.orderId}</td>
                            <td>{item.supplierId}</td>
                            <td>
                              <StatusBadge status={item.status} />
                            </td>
                            <td>{formatDateTime(item.orderedAt)}</td>
                            <td className="text-right">
                              {item.totalLotCount === null || item.totalLotCount === undefined
                                ? "-"
                                : formatCount(item.totalLotCount)}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <div className="alert-banner info" style={{ marginBottom: 0 }}>
                    <div>
                      <div className="alert-title">표시할 목록 없음</div>
                      <div className="alert-desc">현재 조건에 맞는 주문 목록이 없습니다.</div>
                    </div>
                  </div>
                )
              ) : selectedKpi.stockItems.length ? (
                <div className="tbl-wrap">
                  <table>
                    <thead>
                      <tr>
                        <th>품목코드</th>
                        <th>품목명</th>
                        <th>창고</th>
                        <th className="text-right">현재수량</th>
                        <th className="text-right">안전재고</th>
                        <th>경고수준</th>
                      </tr>
                    </thead>
                    <tbody>
                      {selectedKpi.stockItems.map((item) => (
                        <tr key={`${item.code}-${item.warehouseCode}`}>
                          <td>{item.code}</td>
                          <td>{item.name}</td>
                          <td>{item.warehouseCode}</td>
                          <td className="text-right">{formatCount(item.current)}</td>
                          <td className="text-right">{formatCount(item.safety)}</td>
                          <td className={item.level === "danger" ? "text-danger" : "text-warning"}>
                            {item.level === "danger" ? "위험" : "주의"}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="alert-banner info" style={{ marginBottom: 0 }}>
                  <div>
                    <div className="alert-title">표시할 목록 없음</div>
                    <div className="alert-desc">현재 조건에 맞는 재고 경고 품목이 없습니다.</div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
