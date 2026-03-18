import { useEffect, useState } from "react";
import type { OrderSearchResponse } from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import Pagination from "../components/Pagination";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function OrderListPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const [page, setPage] = useState(0);
  const [statusFilter, setStatusFilter] = useState("");
  const [keyword, setKeyword] = useState("");
  const [appliedStatus, setAppliedStatus] = useState("");
  const [appliedKeyword, setAppliedKeyword] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [searchResult, setSearchResult] = useState<OrderSearchResponse | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadOrders() {
      setLoading(true);
      setErrorText("");
      try {
        const result = await client.searchOrders({
          status: appliedStatus,
          keyword: appliedKeyword,
          page,
          size: PAGE_SIZE,
        });

        if (!cancelled) {
          setSearchResult(result);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setSearchResult(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadOrders();
    return () => {
      cancelled = true;
    };
  }, [appliedKeyword, appliedStatus, client, page, reloadKey]);

  function handleSearch() {
    setAppliedStatus(statusFilter);
    setAppliedKeyword(keyword.trim());
    setPage(0);
    setReloadKey((current) => current + 1);
  }

  const items = searchResult?.items ?? [];
  const totalPages = Math.max(searchResult?.page.totalPages ?? 1, 1);
  const totalElements = searchResult?.page.totalElements ?? items.length;

  return (
    <div className="page-body">
      <div className="page-title">주문 관리</div>

      <div className="card mb-12">
        <div className="card-body" style={{ padding: "14px 16px" }}>
          <div className="form-row">
            <div className="form-group">
              <label>주문 상태</label>
              <select
                style={{ width: 140 }}
                value={statusFilter}
                onChange={(event) => setStatusFilter(event.target.value)}
              >
                <option value="">전체</option>
                <option value="PENDING">대기</option>
                <option value="CONFIRMED">확정</option>
                <option value="IN_PROGRESS">진행 중</option>
                <option value="COMPLETED">완료</option>
                <option value="CANCELED">취소</option>
              </select>
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input
                type="text"
                placeholder="주문번호 / 거래처 ID"
                style={{ width: 180 }}
                value={keyword}
                onChange={(event) => setKeyword(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") {
                    handleSearch();
                  }
                }}
              />
            </div>
            <div className="form-group">
              <label style={{ visibility: "hidden" }}>조회</label>
              <button className="btn btn-primary" onClick={handleSearch} disabled={loading}>
                {loading ? "조회 중..." : "조회"}
              </button>
            </div>
            <div className="form-group" style={{ marginLeft: "auto" }}>
              <label style={{ visibility: "hidden" }}>등록</label>
              <div className="flex gap-8">
                <button className="btn btn-success" disabled title="주문 등록 API는 아직 routed page에 연결하지 않았습니다.">
                  + 주문 등록 예정
                </button>
                <button className="btn btn-gray" disabled title="엑셀 다운로드 API는 현재 제공되지 않습니다.">
                  엑셀 다운로드 예정
                </button>
              </div>
            </div>
          </div>
          <div className="text-muted fs-12 mt-8">
            실제 API 기준으로 주문 목록/상세/상태 변경까지 연결했습니다. 주문 등록과 엑셀 다운로드는 백엔드
            지원 범위가 정리되기 전까지 노출만 보류합니다.
          </div>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">
            주문 목록 <span className="text-muted fw-600 fs-12">총 {totalElements.toLocaleString("ko-KR")}건</span>
          </span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>주문번호</th>
                <th>거래처 ID</th>
                <th>주문일시</th>
                <th>상태</th>
                <th>액션</th>
              </tr>
            </thead>
            <tbody>
              {items.length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center text-muted" style={{ padding: 24 }}>
                    조회 결과가 없습니다.
                  </td>
                </tr>
              ) : (
                items.map((order) => (
                  <tr key={order.orderId}>
                    <td>
                      <span
                        className="text-primary fw-600 cursor-pointer"
                        onClick={() => navigate(`/orders/${order.orderId}`)}
                      >
                        {order.orderId}
                      </span>
                    </td>
                    <td>{order.supplierId || "-"}</td>
                    <td>{formatDateTime(order.orderedAt)}</td>
                    <td>
                      <StatusBadge status={order.status} />
                    </td>
                    <td>
                      <button className="btn btn-sm btn-outline" onClick={() => navigate(`/orders/${order.orderId}`)}>
                        상세
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <Pagination page={page} totalPages={totalPages} onChange={setPage} />
      </div>
    </div>
  );
}
