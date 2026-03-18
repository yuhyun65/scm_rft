import { useEffect, useState } from "react";
import type { LotDetail, OrderDetail, OrderStatusChangeResponse } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import StatusBadge from "../components/StatusBadge";
import { formatCount, formatDateTime, formatErrorText, useAuthIdentity, useScmApiClient } from "../lib/scmApi";

export default function OrderDetailPage() {
  const navigate = useNavigate();
  const { orderId = "" } = useParams();
  const client = useScmApiClient();
  const { memberId, memberName } = useAuthIdentity();
  const [loading, setLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [statusResult, setStatusResult] = useState<OrderStatusChangeResponse | null>(null);
  const [targetStatus, setTargetStatus] = useState("CONFIRMED");
  const [reason, setReason] = useState("");
  const [lotId, setLotId] = useState("");
  const [lotLoading, setLotLoading] = useState(false);
  const [lotResult, setLotResult] = useState<LotDetail | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadOrder() {
      if (!orderId) {
        return;
      }

      setLoading(true);
      setErrorText("");
      try {
        const result = await client.getOrder(orderId);
        if (!cancelled) {
          setOrder(result);
          setTargetStatus(result.status === "PENDING" ? "CONFIRMED" : result.status);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setOrder(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadOrder();
    return () => {
      cancelled = true;
    };
  }, [client, orderId]);

  async function handleRefreshOrder() {
    if (!orderId) {
      return;
    }

    setLoading(true);
    setErrorText("");
    try {
      const result = await client.getOrder(orderId);
      setOrder(result);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setLoading(false);
    }
  }

  async function handleChangeStatus() {
    if (!orderId) {
      return;
    }

    setSubmitting(true);
    setErrorText("");
    try {
      const result = await client.changeOrderStatus(orderId, {
        targetStatus,
        changedBy: memberId || memberName || "mate-scm-portal",
        reason: reason.trim() || undefined,
      });
      setStatusResult(result);
      const refreshed = await client.getOrder(orderId);
      setOrder(refreshed);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setSubmitting(false);
    }
  }

  async function handleGetLot() {
    if (!lotId.trim()) {
      setLotResult(null);
      return;
    }

    setLotLoading(true);
    setErrorText("");
    try {
      const result = await client.getLot(lotId.trim());
      setLotResult(result);
    } catch (error) {
      setErrorText(formatErrorText(error));
      setLotResult(null);
    } finally {
      setLotLoading(false);
    }
  }

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate("/orders")}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            {orderId || "-"}
          </span>
          {order ? <StatusBadge status={order.status} /> : null}
        </div>
        <div className="flex gap-8">
          <button className="btn btn-outline" onClick={handleRefreshOrder} disabled={loading}>
            {loading ? "새로고침 중..." : "새로고침"}
          </button>
          <button className="btn btn-success" onClick={handleChangeStatus} disabled={submitting || !order}>
            {submitting ? "상태 반영 중..." : "상태 변경"}
          </button>
          <button className="btn btn-gray" onClick={() => navigate("/reports")}>
            보고서 이동
          </button>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="grid-2 mb-16">
        <div className="card">
          <div className="card-header">
            <span className="card-title">주문 기본 정보</span>
          </div>
          <div className="card-body">
            {order ? (
              <>
                {[
                  ["주문번호", order.orderId],
                  ["거래처 ID", order.supplierId || "-"],
                  ["상태", <StatusBadge key="status" status={order.status} />],
                  ["주문일시", formatDateTime(order.orderedAt)],
                  ["예상 납기", formatDateTime(order.expectedDeliveryAt)],
                  ["연결 LOT 수", `${formatCount(order.totalLotCount)} 건`],
                ].map(([label, value]) => (
                  <div key={String(label)} className="detail-row">
                    <div className="detail-label">{label}</div>
                    <div className="detail-value">{value}</div>
                  </div>
                ))}
              </>
            ) : (
              <div className="text-muted" style={{ padding: "8px 0" }}>
                {loading ? "주문 정보를 불러오는 중입니다." : "주문 정보를 찾지 못했습니다."}
              </div>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">상태 변경</span>
          </div>
          <div className="card-body">
            <div className="form-group mb-12">
              <label>목표 상태</label>
              <select value={targetStatus} onChange={(event) => setTargetStatus(event.target.value)} style={{ width: "100%" }}>
                <option value="CONFIRMED">확정</option>
                <option value="IN_PROGRESS">진행 중</option>
                <option value="COMPLETED">완료</option>
                <option value="CANCELED">취소</option>
              </select>
            </div>
            <div className="form-group mb-12">
              <label>변경 사유</label>
              <textarea rows={4} value={reason} onChange={(event) => setReason(event.target.value)} />
            </div>
            <div className="text-muted fs-12 mb-12">
              변경자는 현재 로그인 계정인 {memberName || memberId || "Mate-SCM 사용자"}로 자동 기록됩니다.
            </div>
            {statusResult ? (
              <div className="alert-banner success">
                {statusResult.beforeStatus} → {statusResult.afterStatus} ({formatDateTime(statusResult.changedAt)})
              </div>
            ) : (
              <div className="text-muted fs-12">최근 상태 변경 결과가 없습니다.</div>
            )}
          </div>
        </div>
      </div>

      <div className="grid-2">
        <div className="card">
          <div className="card-header">
            <span className="card-title">LOT 상세 조회</span>
          </div>
          <div className="card-body">
            <div className="form-row">
              <div className="form-group" style={{ flex: 1 }}>
                <label>LOT ID</label>
                <input
                  value={lotId}
                  onChange={(event) => setLotId(event.target.value)}
                  placeholder="예: DEMO-LOT-1002-A"
                />
              </div>
              <div className="form-group">
                <label style={{ visibility: "hidden" }}>조회</label>
                <button className="btn btn-primary" onClick={handleGetLot} disabled={lotLoading}>
                  {lotLoading ? "조회 중..." : "LOT 조회"}
                </button>
              </div>
            </div>
            <div className="text-muted fs-12 mb-12">
              현재 routed page에서는 order detail payload에 LOT 목록이 포함되지 않아, LOT ID 기준 상세 조회만 연결했습니다.
            </div>
            {lotResult ? (
              <>
                {[
                  ["LOT ID", lotResult.lotId],
                  ["주문번호", lotResult.orderId],
                  ["수량", `${formatCount(lotResult.quantity)} EA`],
                  ["상태", <StatusBadge key="lot-status" status={lotResult.status} />],
                ].map(([label, value]) => (
                  <div key={String(label)} className="detail-row">
                    <div className="detail-label">{label}</div>
                    <div className="detail-value">{value}</div>
                  </div>
                ))}
              </>
            ) : (
              <div className="text-muted fs-12">조회한 LOT 상세가 여기에 표시됩니다.</div>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">미연결 액션 안내</span>
          </div>
          <div className="card-body">
            <div className="detail-row">
              <div className="detail-label">주문 수정</div>
              <div className="detail-value">백엔드 수정 API가 현재 노출되지 않아 routed page에서 보류합니다.</div>
            </div>
            <div className="detail-row">
              <div className="detail-label">LOT 추가</div>
              <div className="detail-value">LOT 생성 API가 현재 노출되지 않아 상세 조회만 우선 연결했습니다.</div>
            </div>
            <div className="detail-row">
              <div className="detail-label">보고서</div>
              <div className="detail-value">보고서 생성은 보고서 관리 화면에서 실제 API로 연결됩니다.</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
