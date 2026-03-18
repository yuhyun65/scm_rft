import { useEffect, useState } from "react";
import type { QualityDocumentSearchResponse } from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import Pagination from "../components/Pagination";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function QualityDocPage() {
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
  const [searchResult, setSearchResult] = useState<QualityDocumentSearchResponse | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadDocuments() {
      setLoading(true);
      setErrorText("");
      try {
        const result = await client.searchQualityDocuments({
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

    void loadDocuments();
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

  return (
    <div className="page-body">
      <div className="page-title">품질 문서 관리</div>
      <div className="alert-banner info">
        <span style={{ fontSize: 20 }}>알림</span>
        <div>
          <div className="alert-title">실제 ACK 흐름 연결 완료</div>
          <div className="alert-desc">문서 상세 라우트에서 ACK 유형과 코멘트를 지정하면 gateway를 통해 실제 ACK 요청을 보냅니다.</div>
        </div>
        <button
          className="btn btn-primary btn-sm"
          style={{ marginLeft: "auto" }}
          onClick={() => {
            setStatusFilter("ACTIVE");
            setAppliedStatus("ACTIVE");
            setPage(0);
            setReloadKey((current) => current + 1);
          }}
        >
          활성 문서만 보기
        </button>
      </div>
      <div className="card mb-12">
        <div className="card-body" style={{ padding: "14px 16px" }}>
          <div className="form-row">
            <div className="form-group">
              <label>상태</label>
              <select style={{ width: 140 }} value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
                <option value="">전체</option>
                <option value="ACTIVE">활성</option>
                <option value="EXPIRED">만료</option>
                <option value="ARCHIVED">보관</option>
              </select>
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input
                type="text"
                placeholder="문서명 검색"
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
                {loading ? "조회 중..." : "조회"}
              </button>
            </div>
            <div className="form-group" style={{ marginLeft: "auto" }}>
              <label style={{ visibility: "hidden" }}>등록</label>
              <button className="btn btn-success" disabled title="문서 등록 API는 아직 routed page에 연결하지 않았습니다.">
                + 문서 등록 예정
              </button>
            </div>
          </div>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">품질 문서 목록</span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>문서번호</th>
                <th>문서명</th>
                <th>등록일</th>
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
                items.map((doc) => (
                  <tr key={doc.documentId}>
                    <td className="fw-600">{doc.documentId}</td>
                    <td>{doc.title}</td>
                    <td>{formatDateTime(doc.issuedAt)}</td>
                    <td>
                      <StatusBadge status={doc.status} />
                    </td>
                    <td>
                      <button className="btn btn-sm btn-outline" onClick={() => navigate(`/quality-docs/${encodeURIComponent(doc.documentId)}`)}>
                        상세 / ACK
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
