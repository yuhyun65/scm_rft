import { useEffect, useState } from "react";
import type { OrderDetail, OrderSearchResponse, OrderSummary } from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import Pagination from "../components/Pagination";
import StatusBadge from "../components/StatusBadge";
import { buildExportFileName, downloadCsv } from "../lib/export";
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

  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createOrderId, setCreateOrderId] = useState("");
  const [createSupplierId, setCreateSupplierId] = useState("");
  const [createOrderDate, setCreateOrderDate] = useState(new Date().toISOString().slice(0, 10));
  const [createOrderStatus, setCreateOrderStatus] = useState("PENDING");
  const [creating, setCreating] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [createdOrder, setCreatedOrder] = useState<OrderDetail | null>(null);

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

  async function handleCreateOrder() {
    setCreating(true);
    setErrorText("");
    try {
      const result = await client.createOrder({
        orderId: createOrderId.trim(),
        supplierId: createSupplierId.trim(),
        orderDate: createOrderDate,
        status: createOrderStatus,
      });
      setCreatedOrder(result);
      setShowCreateForm(false);
      setKeyword(result.orderId);
      setAppliedKeyword(result.orderId);
      setPage(0);
      setReloadKey((current) => current + 1);
      navigate(`/orders/${encodeURIComponent(result.orderId)}`);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setCreating(false);
    }
  }

  async function loadAllOrdersForExport() {
    const firstPage =
      searchResult ??
      (await client.searchOrders({
        status: appliedStatus,
        keyword: appliedKeyword,
        page: 0,
        size: PAGE_SIZE,
      }));
    const allItems: OrderSummary[] = [...firstPage.items];
    const totalPages = Math.max(firstPage.page.totalPages ?? 1, 1);

    for (let currentPage = 1; currentPage < totalPages; currentPage += 1) {
      const nextPage = await client.searchOrders({
        status: appliedStatus,
        keyword: appliedKeyword,
        page: currentPage,
        size: PAGE_SIZE,
      });
      allItems.push(...nextPage.items);
    }

    return allItems;
  }

  async function handleExportOrders() {
    setExporting(true);
    setErrorText("");
    try {
      const orders = await loadAllOrdersForExport();
      if (orders.length === 0) {
        setErrorText("엑셀로 내보낼 주문 목록이 없습니다.");
        return;
      }

      downloadCsv(
        buildExportFileName("mate-scm-orders"),
        [
          { header: "주문번호", render: (order) => order.orderId },
          { header: "거래처 ID", render: (order) => order.supplierId || "-" },
          { header: "주문일시", render: (order) => formatDateTime(order.orderedAt) },
          { header: "상태", render: (order) => order.status },
        ],
        orders
      );
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setExporting(false);
    }
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
                style={{ width: 200 }}
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
                {loading ? "조회 중.." : "조회"}
              </button>
            </div>
            <div className="form-group" style={{ marginLeft: "auto" }}>
              <label style={{ visibility: "hidden" }}>액션</label>
              <div className="flex gap-8">
                <button className="btn btn-success" onClick={() => setShowCreateForm((current) => !current)}>
                  + 주문 등록
                </button>
                <button
                  className="btn btn-gray"
                  onClick={() => void handleExportOrders()}
                  disabled={loading || exporting}
                >
                  {exporting ? "엑셀 다운로드 중.." : "엑셀 다운로드"}
                </button>
              </div>
            </div>
          </div>
          <div className="text-muted fs-12 mt-8">
            주문 목록, 상세, 상태 변경뿐 아니라 주문 등록도 routed 페이지에서 실제 API로 처리됩니다.
          </div>
        </div>
      </div>

      {showCreateForm ? (
        <div className="card mb-12">
          <div className="card-header">
            <span className="card-title">주문 등록</span>
          </div>
          <div className="card-body">
            <div className="form-row">
              <div className="form-group">
                <label>주문번호</label>
                <input value={createOrderId} onChange={(event) => setCreateOrderId(event.target.value)} />
              </div>
              <div className="form-group">
                <label>거래처 ID</label>
                <input value={createSupplierId} onChange={(event) => setCreateSupplierId(event.target.value)} />
              </div>
              <div className="form-group">
                <label>주문일</label>
                <input type="date" value={createOrderDate} onChange={(event) => setCreateOrderDate(event.target.value)} />
              </div>
              <div className="form-group">
                <label>초기 상태</label>
                <select value={createOrderStatus} onChange={(event) => setCreateOrderStatus(event.target.value)}>
                  <option value="PENDING">대기</option>
                  <option value="CONFIRMED">확정</option>
                  <option value="IN_PROGRESS">진행 중</option>
                  <option value="COMPLETED">완료</option>
                  <option value="CANCELED">취소</option>
                </select>
              </div>
            </div>
            <div className="flex gap-8">
              <button className="btn btn-primary" onClick={handleCreateOrder} disabled={creating}>
                {creating ? "등록 중.." : "등록"}
              </button>
              <button className="btn btn-gray" onClick={() => setShowCreateForm(false)} disabled={creating}>
                닫기
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}
      {createdOrder ? (
        <div className="alert-banner success mb-12">
          주문 {createdOrder.orderId} 등록 완료 ({formatDateTime(createdOrder.orderedAt)})
        </div>
      ) : null}

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
                      <span className="text-primary fw-600 cursor-pointer" onClick={() => navigate(`/orders/${order.orderId}`)}>
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
