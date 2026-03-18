import { useEffect, useMemo, useState } from "react";
import type { InventoryBalance, InventoryMovementSearchResponse } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import Pagination from "../components/Pagination";
import { formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function InventoryDetailPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const params = useParams();
  const itemCode = decodeURIComponent(params.itemCode ?? "");
  const warehouseCode = decodeURIComponent(params.warehouseCode ?? "");
  const [page, setPage] = useState(0);
  const [movementType, setMovementType] = useState("");
  const [appliedMovementType, setAppliedMovementType] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [balance, setBalance] = useState<InventoryBalance | null>(null);
  const [movementResult, setMovementResult] = useState<InventoryMovementSearchResponse | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadDetail() {
      if (!itemCode || !warehouseCode) {
        return;
      }

      setLoading(true);
      setErrorText("");
      try {
        const [balanceResponse, movementResponse] = await Promise.all([
          client.searchInventoryBalances({
            itemCode,
            warehouseCode,
            page: 0,
            size: PAGE_SIZE,
          }),
          client.searchInventoryMovements({
            itemCode,
            warehouseCode,
            movementType: appliedMovementType,
            page,
            size: PAGE_SIZE,
          }),
        ]);

        if (!cancelled) {
          setBalance(
            balanceResponse.items.find(
              (item) => item.itemCode === itemCode && item.warehouseCode === warehouseCode
            ) ?? null
          );
          setMovementResult(movementResponse);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setBalance(null);
          setMovementResult(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadDetail();
    return () => {
      cancelled = true;
    };
  }, [appliedMovementType, client, itemCode, page, reloadKey, warehouseCode]);

  function handleSearch() {
    setAppliedMovementType(movementType);
    setPage(0);
    setReloadKey((current) => current + 1);
  }

  const totalPages = useMemo(() => {
    const total = movementResult?.total ?? 0;
    return Math.max(Math.ceil(total / PAGE_SIZE), 1);
  }, [movementResult]);

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate("/inventory")}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            {itemCode} / {warehouseCode}
          </span>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="grid-2 mb-16">
        <div className="card">
          <div className="card-header">
            <span className="card-title">재고 상세</span>
          </div>
          <div className="card-body">
            {balance ? (
              <>
                {[
                  ["품목코드", balance.itemCode],
                  ["창고코드", balance.warehouseCode],
                  ["현재고", `${balance.quantity.toLocaleString("ko-KR")} EA`],
                  ["최종 반영시각", formatDateTime(balance.updatedAt)],
                ].map(([label, value]) => (
                  <div key={String(label)} className="detail-row">
                    <div className="detail-label">{label}</div>
                    <div className="detail-value">{value}</div>
                  </div>
                ))}
              </>
            ) : (
              <div className="text-muted">{loading ? "재고 상세를 불러오는 중입니다." : "일치하는 재고 balance가 없습니다."}</div>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">조회 조건</span>
          </div>
          <div className="card-body">
            <div className="form-row">
              <div className="form-group" style={{ flex: 1 }}>
                <label>Movement Type</label>
                <select value={movementType} onChange={(event) => setMovementType(event.target.value)} style={{ width: "100%" }}>
                  <option value="">전체</option>
                  <option value="IN">IN</option>
                  <option value="OUT">OUT</option>
                  <option value="ADJUST">ADJUST</option>
                </select>
              </div>
              <div className="form-group">
                <label style={{ visibility: "hidden" }}>조회</label>
                <button className="btn btn-primary" onClick={handleSearch} disabled={loading}>
                  {loading ? "조회 중..." : "이력 조회"}
                </button>
              </div>
            </div>
            <div className="text-muted fs-12 mt-8">
              재고 조정은 아직 별도 write API가 없어서 history 조회까지만 연결했습니다.
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">재고 이동 이력</span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>이동 ID</th>
                <th>이동 유형</th>
                <th>수량</th>
                <th>참조번호</th>
                <th>이동일시</th>
              </tr>
            </thead>
            <tbody>
              {(movementResult?.items ?? []).length === 0 ? (
                <tr>
                  <td colSpan={5} className="text-center text-muted" style={{ padding: 24 }}>
                    조회 결과가 없습니다.
                  </td>
                </tr>
              ) : (
                movementResult?.items.map((movement) => (
                  <tr key={movement.movementId}>
                    <td>{movement.movementId}</td>
                    <td>{movement.movementType}</td>
                    <td className="text-right">{movement.quantity.toLocaleString("ko-KR")}</td>
                    <td>{movement.referenceNo || "-"}</td>
                    <td>{formatDateTime(movement.movedAt)}</td>
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
