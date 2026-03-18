import { useEffect, useState } from "react";
import type {
  QualityDocumentDetail,
  QualityDocumentSearchResponse,
} from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import Pagination from "../components/Pagination";
import StatusBadge from "../components/StatusBadge";
import {
  formatDateTime,
  formatErrorText,
  useAuthIdentity,
  useScmApiClient,
} from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function QualityDocPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const { memberId, memberName } = useAuthIdentity();
  const [page, setPage] = useState(0);
  const [statusFilter, setStatusFilter] = useState("");
  const [keyword, setKeyword] = useState("");
  const [appliedStatus, setAppliedStatus] = useState("");
  const [appliedKeyword, setAppliedKeyword] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [searchResult, setSearchResult] = useState<QualityDocumentSearchResponse | null>(null);

  const [showCreateForm, setShowCreateForm] = useState(false);
  const [documentTitle, setDocumentTitle] = useState("");
  const [documentType, setDocumentType] = useState("NOTICE");
  const [publisherMemberId, setPublisherMemberId] = useState(memberId || "");
  const [creating, setCreating] = useState(false);
  const [createdDocument, setCreatedDocument] = useState<QualityDocumentDetail | null>(null);

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

  async function handleCreateDocument() {
    setCreating(true);
    setErrorText("");
    try {
      const result = await client.registerQualityDocument({
        title: documentTitle.trim(),
        documentType,
        publisherMemberId: publisherMemberId.trim() || undefined,
      });
      setCreatedDocument(result);
      setShowCreateForm(false);
      setStatusFilter("ACTIVE");
      setAppliedStatus("ACTIVE");
      setKeyword(result.title);
      setAppliedKeyword(result.title);
      setPage(0);
      setReloadKey((current) => current + 1);
      navigate(`/quality-docs/${encodeURIComponent(result.documentId)}`);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setCreating(false);
    }
  }

  const items = searchResult?.items ?? [];
  const totalPages = Math.max(searchResult?.page.totalPages ?? 1, 1);

  return (
    <div className="page-body">
      <div className="page-title">품질 문서 관리</div>

      <div className="alert-banner info">
        <span style={{ fontSize: 20 }}>알림</span>
        <div>
          <div className="alert-title">ACK 흐름과 문서 등록 모두 연결됨</div>
          <div className="alert-desc">
            문서 목록/상세/ACK뿐 아니라 routed 페이지에서 품질 문서 등록까지 gateway 경로로 처리합니다.
          </div>
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
                style={{ width: 220 }}
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
              <button className="btn btn-success" onClick={() => setShowCreateForm((current) => !current)}>
                + 문서 등록
              </button>
            </div>
          </div>
        </div>
      </div>

      {showCreateForm ? (
        <div className="card mb-12">
          <div className="card-header">
            <span className="card-title">품질 문서 등록</span>
          </div>
          <div className="card-body">
            <div className="form-row">
              <div className="form-group" style={{ flex: 2 }}>
                <label>문서명</label>
                <input value={documentTitle} onChange={(event) => setDocumentTitle(event.target.value)} />
              </div>
              <div className="form-group">
                <label>문서 유형</label>
                <select value={documentType} onChange={(event) => setDocumentType(event.target.value)}>
                  <option value="NOTICE">NOTICE</option>
                  <option value="COA">COA</option>
                  <option value="AUDIT">AUDIT</option>
                  <option value="GUIDE">GUIDE</option>
                </select>
              </div>
              <div className="form-group">
                <label>발행자</label>
                <input
                  value={publisherMemberId}
                  onChange={(event) => setPublisherMemberId(event.target.value)}
                  placeholder={memberName || memberId || "member id"}
                />
              </div>
            </div>
            <div className="flex gap-8">
              <button className="btn btn-primary" onClick={handleCreateDocument} disabled={creating}>
                {creating ? "등록 중..." : "등록"}
              </button>
              <button className="btn btn-gray" onClick={() => setShowCreateForm(false)} disabled={creating}>
                닫기
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}
      {createdDocument ? (
        <div className="alert-banner success mb-12">
          문서 {createdDocument.title} 등록 완료 ({formatDateTime(createdDocument.issuedAt)})
        </div>
      ) : null}

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
                <th>발행일</th>
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
