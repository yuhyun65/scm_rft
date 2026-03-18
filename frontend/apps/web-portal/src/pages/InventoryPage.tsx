import { useEffect, useMemo, useState } from "react";
import type {
  InventoryAdjustmentResponse,
  InventoryBalanceSearchResponse,
} from "@scm-rft/api-client";
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

  const [showAdjustForm, setShowAdjustForm] = useState(false);
  const [adjustItemCode, setAdjustItemCode] = useState("");
  const [adjustWarehouseCode, setAdjustWarehouseCode] = useState("");
  const [adjustQuantityDelta, setAdjustQuantityDelta] = useState("0");
  const [adjustReferenceNo, setAdjustReferenceNo] = useState("");
  const [adjusting, setAdjusting] = useState(false);
  const [adjustmentResult, setAdjustmentResult] = useState<InventoryAdjustmentResponse | null>(null);

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

  async function handleAdjustInventory() {
    const quantityDelta = Number(adjustQuantityDelta);
    if (!Number.isFinite(quantityDelta) || quantityDelta === 0) {
      setErrorText("조정 수량은 0이 아닌 숫자여야 합니다.");
      return;
    }

    setAdjusting(true);
    setErrorText("");
    try {
      const result = await client.adjustInventory({
        itemCode: adjustItemCode.trim(),
        warehouseCode: adjustWarehouseCode.trim(),
        quantityDelta,
        referenceNo: adjustReferenceNo.trim() || undefined,
      });
      setAdjustmentResult(result);
      setShowAdjustForm(false);
      setItemCode(result.itemCode);
      setWarehouseCode(result.warehouseCode);
      setAppliedItemCode(result.itemCode);
      setAppliedWarehouseCode(result.warehouseCode);
      setPage(0);
      setReloadKey((current) => current + 1);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setAdjusting(false);
    }
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
              <label>품목 코드</label>
              <input
                type="text"
                placeholder="품목 코드"
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
                <button
                  className="btn btn-outline"
                  onClick={() => {
                    setShowAdjustForm((current) => !current);
                    setAdjustItemCode(itemCode.trim() || items[0]?.itemCode || "");
                    setAdjustWarehouseCode(warehouseCode.trim() || items[0]?.warehouseCode || "");
                  }}
                >
                  재고 조정
                </button>
              </div>
            </div>
          </div>
          <div className="text-muted fs-12 mt-8">
            조회는 balance API, 상세는 movement API, 재고 조정은 adjustment API에 연결되어 있습니다.
          </div>
        </div>
      </div>

      {showAdjustForm ? (
        <div className="card mb-12">
          <div className="card-header">
            <span className="card-title">재고 조정</span>
          </div>
          <div className="card-body">
            <div className="form-row">
              <div className="form-group">
                <label>품목 코드</label>
                <input value={adjustItemCode} onChange={(event) => setAdjustItemCode(event.target.value)} />
              </div>
              <div className="form-group">
                <label>창고 코드</label>
                <input
                  value={adjustWarehouseCode}
                  onChange={(event) => setAdjustWarehouseCode(event.target.value)}
                />
              </div>
              <div className="form-group">
                <label>조정 수량</label>
                <input
                  type="number"
                  step="0.001"
                  value={adjustQuantityDelta}
                  onChange={(event) => setAdjustQuantityDelta(event.target.value)}
                />
              </div>
              <div className="form-group" style={{ minWidth: 180 }}>
                <label>참조 번호</label>
                <input
                  value={adjustReferenceNo}
                  onChange={(event) => setAdjustReferenceNo(event.target.value)}
                  placeholder="예: ADJ-20260318-01"
                />
              </div>
            </div>
            <div className="flex gap-8">
              <button className="btn btn-primary" onClick={handleAdjustInventory} disabled={adjusting}>
                {adjusting ? "조정 중..." : "조정 실행"}
              </button>
              <button className="btn btn-gray" onClick={() => setShowAdjustForm(false)} disabled={adjusting}>
                닫기
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}
      {adjustmentResult ? (
        <div className="alert-banner success mb-12">
          {adjustmentResult.itemCode} / {adjustmentResult.warehouseCode} 조정 완료
          ({adjustmentResult.quantityDelta.toLocaleString("ko-KR")} → 현재 {adjustmentResult.resultingQuantity.toLocaleString("ko-KR")})
        </div>
      ) : null}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 14, marginBottom: 14 }}>
        <KpiCard
          label="총 조회 건수"
          value={total.toLocaleString("ko-KR")}
          sub="inventory balance API 기준"
          variant="success"
        />
        <KpiCard
          label="현재 페이지 수량 합계"
          value={pageQuantity.toLocaleString("ko-KR")}
          sub="현재 화면 합계"
        />
        <KpiCard
          label="최종 반영 시각"
          value={latestUpdatedAt ? formatDateTime(latestUpdatedAt) : "-"}
          sub={appliedWarehouseCode || "전체 창고 기준"}
          variant="warn"
        />
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
                <th>품목 코드</th>
                <th>창고 코드</th>
                <th>현재고</th>
                <th>최종 반영 시각</th>
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
