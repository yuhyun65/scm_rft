import { useEffect, useMemo, useState } from "react";
import type { InventoryBalanceSearchResponse } from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import KpiCard from "../components/KpiCard";
import Pagination from "../components/Pagination";
import { formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function InventoryPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const [page, setPage] = useState(0);
  const [itemCode, setItemCode] = useState("");
  const [warehouseCode, setWarehouseCode] = useState("");
  const [appliedItemCode, setAppliedItemCode] = useState("");
  const [appliedWarehouseCode, setAppliedWarehouseCode] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [searchResult, setSearchResult] = useState<InventoryBalanceSearchResponse | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadBalances() {
      setLoading(true);
      setErrorText("");
      try {
        const result = await client.searchInventoryBalances({
          itemCode: appliedItemCode,
          warehouseCode: appliedWarehouseCode,
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

    void loadBalances();
    return () => {
      cancelled = true;
    };
  }, [appliedItemCode, appliedWarehouseCode, client, page, reloadKey]);

  function handleSearch() {
    setAppliedItemCode(itemCode.trim());
    setAppliedWarehouseCode(warehouseCode.trim());
    setPage(0);
    setReloadKey((current) => current + 1);
  }

  const items = searchResult?.items ?? [];
  const total = searchResult?.total ?? 0;
  const totalPages = Math.max(Math.ceil(total / PAGE_SIZE), 1);
  const pageQuantity = useMemo(
    () => items.reduce((sum, item) => sum + item.quantity, 0),
    [items]
  );
  const latestUpdatedAt = useMemo(() => {
    const candidates = items.map((item) => item.updatedAt).filter(Boolean).sort();
    return candidates.at(-1);
  }, [items]);

  return (
    <div className="page-body">
      <div className="page-title">재고 현황</div>

      <div className="card mb-12">
        <div className="card-body" style={{ padding: "14px 16px" }}>
          <div className="form-row">
            <div className="form-group">
              <label>창고 코드</label>
              <input
                type="text"
                placeholder="예: WH-01"
                style={{ width: 130 }}
                value={warehouseCode}
                onChange={(event) => setWarehouseCode(event.target.value)}
                onKeyDown={(event) => {
                  if (event.key === "Enter") {
                    handleSearch();
                  }
                }}
              />
            </div>
            <div className="form-group">
              <label>품목코드</label>
              <input
                type="text"
                placeholder="코드 입력"
                style={{ width: 140 }}
                value={itemCode}
                onChange={(event) => setItemCode(event.target.value)}
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
              <label style={{ visibility: "hidden" }}>액션</label>
              <div className="flex gap-8">
                <button className="btn btn-gray" disabled title="엑셀 다운로드 API는 아직 없습니다.">
                  엑셀 다운로드 예정
                </button>
                <button className="btn btn-outline" disabled title="재고 조정 API는 현재 노출되지 않았습니다.">
                  재고 조정 예정
                </button>
              </div>
            </div>
          </div>
          <div className="text-muted fs-12 mt-8">
            재고 화면은 실제 inventory balance API로 전환했습니다. 상세는 `품목코드 + 창고코드` 기준 route에서 movement 조회까지 이어집니다.
          </div>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 14, marginBottom: 14 }}>
        <KpiCard label="총 조회 건수" value={total.toLocaleString("ko-KR")} sub="inventory balance API 기준" variant="success" />
        <KpiCard label="현재 페이지 수량 합계" value={pageQuantity.toLocaleString("ko-KR")} sub="현재 표시 중인 balance row 합계" />
        <KpiCard label="최근 동기화 시각" value={latestUpdatedAt ? formatDateTime(latestUpdatedAt) : "-"} sub={appliedWarehouseCode || "전체 창고 기준"} variant="warn" />
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">
            재고 목록 <span className="text-muted fw-600 fs-12">총 {total.toLocaleString("ko-KR")}건</span>
          </span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>품목코드</th>
                <th>창고코드</th>
                <th>현재고</th>
                <th>최종 반영시각</th>
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
                items.map((item) => (
                  <tr key={`${item.itemCode}:${item.warehouseCode}`}>
                    <td>{item.itemCode}</td>
                    <td>{item.warehouseCode}</td>
                    <td className="text-right">{item.quantity.toLocaleString("ko-KR")}</td>
                    <td>{formatDateTime(item.updatedAt)}</td>
                    <td>
                      <button
                        className="btn btn-sm btn-outline"
                        onClick={() =>
                          navigate(
                            `/inventory/${encodeURIComponent(item.itemCode)}/${encodeURIComponent(item.warehouseCode)}`
                          )
                        }
                      >
                        이력 조회
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
