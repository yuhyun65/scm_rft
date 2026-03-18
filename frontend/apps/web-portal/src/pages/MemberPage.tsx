import { useEffect, useState } from "react";
import type { Member, MemberSearchResponse } from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import Pagination from "../components/Pagination";
import StatusBadge from "../components/StatusBadge";
import { formatErrorText, useScmApiClient } from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function MemberPage() {
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
  const [searchResult, setSearchResult] = useState<MemberSearchResponse | null>(null);

  const [showCreateForm, setShowCreateForm] = useState(false);
  const [createMemberId, setCreateMemberId] = useState("");
  const [createMemberName, setCreateMemberName] = useState("");
  const [createStatus, setCreateStatus] = useState("ACTIVE");
  const [creating, setCreating] = useState(false);
  const [createdMember, setCreatedMember] = useState<Member | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadMembers() {
      setLoading(true);
      setErrorText("");
      try {
        const result = await client.searchMembers({
          keyword: appliedKeyword,
          status: appliedStatus,
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

    void loadMembers();
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

  async function handleCreateMember() {
    setCreating(true);
    setErrorText("");
    try {
      const result = await client.createMember({
        memberId: createMemberId.trim(),
        memberName: createMemberName.trim(),
        status: createStatus,
      });
      setCreatedMember(result);
      setShowCreateForm(false);
      setAppliedKeyword(result.memberId);
      setKeyword(result.memberId);
      setPage(0);
      setReloadKey((current) => current + 1);
      navigate(`/members/${encodeURIComponent(result.memberId)}`);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setCreating(false);
    }
  }

  const items = searchResult?.items ?? [];
  const totalPages = Math.max(Math.ceil((searchResult?.total ?? 0) / PAGE_SIZE), 1);

  return (
    <div className="page-body">
      <div className="page-title">거래처 관리</div>

      <div className="card mb-12">
        <div className="card-body" style={{ padding: "14px 16px" }}>
          <div className="form-row">
            <div className="form-group">
              <label>상태</label>
              <select style={{ width: 100 }} value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
                <option value="">전체</option>
                <option value="ACTIVE">활성</option>
                <option value="INACTIVE">비활성</option>
              </select>
            </div>
            <div className="form-group">
              <label>검색어</label>
              <input
                type="text"
                placeholder="거래처명 / 거래처 ID"
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
                + 거래처 등록
              </button>
            </div>
          </div>
          <div className="text-muted fs-12 mt-8">
            거래처 목록/상세뿐 아니라 거래처 등록도 member API에 연결되어 있습니다.
          </div>
        </div>
      </div>

      {showCreateForm ? (
        <div className="card mb-12">
          <div className="card-header">
            <span className="card-title">거래처 등록</span>
          </div>
          <div className="card-body">
            <div className="form-row">
              <div className="form-group">
                <label>거래처 ID</label>
                <input value={createMemberId} onChange={(event) => setCreateMemberId(event.target.value)} />
              </div>
              <div className="form-group">
                <label>거래처명</label>
                <input value={createMemberName} onChange={(event) => setCreateMemberName(event.target.value)} />
              </div>
              <div className="form-group">
                <label>상태</label>
                <select value={createStatus} onChange={(event) => setCreateStatus(event.target.value)}>
                  <option value="ACTIVE">활성</option>
                  <option value="INACTIVE">비활성</option>
                </select>
              </div>
            </div>
            <div className="flex gap-8">
              <button className="btn btn-primary" onClick={handleCreateMember} disabled={creating}>
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
      {createdMember ? (
        <div className="alert-banner success mb-12">
          거래처 {createdMember.memberId} / {createdMember.memberName || "-"} 등록이 완료되었습니다.
        </div>
      ) : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">
            거래처 목록 <span className="text-muted fw-600 fs-12">총 {(searchResult?.total ?? 0).toLocaleString("ko-KR")}건</span>
          </span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>거래처 ID</th>
                <th>거래처명</th>
                <th>상태</th>
                <th>액션</th>
              </tr>
            </thead>
            <tbody>
              {items.length === 0 ? (
                <tr>
                  <td colSpan={4} className="text-center text-muted" style={{ padding: 24 }}>
                    조회 결과가 없습니다.
                  </td>
                </tr>
              ) : (
                items.map((member) => (
                  <tr key={member.memberId}>
                    <td>{member.memberId}</td>
                    <td className="fw-600">{member.memberName || "-"}</td>
                    <td>{member.status ? <StatusBadge status={member.status} /> : "-"}</td>
                    <td>
                      <button className="btn btn-sm btn-outline" onClick={() => navigate(`/members/${encodeURIComponent(member.memberId)}`)}>
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
