import { useEffect, useState } from "react";
import type {
  BoardPostCreateResponse,
  BoardPostDetail,
  BoardPostSearchResponse,
} from "@scm-rft/api-client";
import Pagination from "../components/Pagination";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useAuthIdentity, useScmApiClient } from "../lib/scmApi";

const PAGE_SIZE = 10;

export default function BoardPage() {
  const client = useScmApiClient();
  const { memberId, memberName } = useAuthIdentity();
  const [page, setPage] = useState(0);
  const [boardType, setBoardType] = useState("");
  const [keyword, setKeyword] = useState("");
  const [appliedBoardType, setAppliedBoardType] = useState("");
  const [appliedKeyword, setAppliedKeyword] = useState("");
  const [reloadKey, setReloadKey] = useState(0);
  const [loading, setLoading] = useState(false);
  const [detailLoading, setDetailLoading] = useState(false);
  const [createSubmitting, setCreateSubmitting] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [searchResult, setSearchResult] = useState<BoardPostSearchResponse | null>(null);
  const [selectedPost, setSelectedPost] = useState<BoardPostDetail | null>(null);
  const [createResult, setCreateResult] = useState<BoardPostCreateResponse | null>(null);
  const [createBoardType, setCreateBoardType] = useState("GENERAL");
  const [createTitle, setCreateTitle] = useState("");
  const [createContent, setCreateContent] = useState("");

  useEffect(() => {
    let cancelled = false;

    async function loadPosts() {
      setLoading(true);
      setErrorText("");
      try {
        const result = await client.searchBoardPosts({
          boardType: appliedBoardType,
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

    void loadPosts();
    return () => {
      cancelled = true;
    };
  }, [appliedBoardType, appliedKeyword, client, page, reloadKey]);

  function handleSearch() {
    setAppliedBoardType(boardType);
    setAppliedKeyword(keyword.trim());
    setPage(0);
    setReloadKey((current) => current + 1);
  }

  async function handleLoadPost(postId: string) {
    setDetailLoading(true);
    setErrorText("");
    try {
      const result = await client.getBoardPost(postId);
      setSelectedPost(result);
    } catch (error) {
      setErrorText(formatErrorText(error));
      setSelectedPost(null);
    } finally {
      setDetailLoading(false);
    }
  }

  async function handleCreatePost() {
    setCreateSubmitting(true);
    setErrorText("");
    try {
      const result = await client.createBoardPost({
        boardType: createBoardType,
        title: createTitle.trim(),
        content: createContent.trim(),
        createdBy: memberId || memberName || "mate-scm-user",
      });
      setCreateResult(result);
      setCreateTitle("");
      setCreateContent("");
      await handleLoadPost(result.postId);
      setReloadKey((current) => current + 1);
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setCreateSubmitting(false);
    }
  }

  const items = searchResult?.items ?? [];
  const totalPages = Math.max(searchResult?.page.totalPages ?? 1, 1);

  return (
    <div className="page-body">
      <div className="page-title">게시판</div>
      <div className="card mb-12">
        <div className="card-body" style={{ padding: "14px 16px" }}>
          <div className="form-row">
            <div className="form-group">
              <label>유형</label>
              <select style={{ width: 140 }} value={boardType} onChange={(event) => setBoardType(event.target.value)}>
                <option value="">전체</option>
                <option value="NOTICE">공지</option>
                <option value="GENERAL">일반</option>
                <option value="QUALITY">품질</option>
              </select>
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input
                type="text"
                placeholder="제목 검색"
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
          </div>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="grid-2">
        <div className="card">
          <div className="card-header">
            <span className="card-title">게시글 목록</span>
          </div>
          <div className="tbl-wrap">
            <table>
              <thead>
                <tr>
                  <th>게시글 ID</th>
                  <th>유형</th>
                  <th>제목</th>
                  <th>상태</th>
                  <th>작성자</th>
                  <th>작성일</th>
                </tr>
              </thead>
              <tbody>
                {items.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="text-center text-muted" style={{ padding: 24 }}>
                      조회 결과가 없습니다.
                    </td>
                  </tr>
                ) : (
                  items.map((post) => (
                    <tr key={post.postId}>
                      <td>{post.postId}</td>
                      <td>
                        <StatusBadge status={post.boardType} />
                      </td>
                      <td className="text-primary fw-600 cursor-pointer" onClick={() => void handleLoadPost(post.postId)}>
                        {post.title}
                      </td>
                      <td>{post.status ? <StatusBadge status={post.status} /> : "-"}</td>
                      <td>{post.createdBy}</td>
                      <td>{formatDateTime(post.createdAt)}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
          <Pagination page={page} totalPages={totalPages} onChange={setPage} />
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">게시글 상세 / 작성</span>
          </div>
          <div className="card-body">
            {detailLoading ? (
              <div className="text-muted mb-16">게시글 상세를 불러오는 중입니다.</div>
            ) : selectedPost ? (
              <div className="mb-16">
                {[
                  ["게시글 ID", selectedPost.postId],
                  ["유형", <StatusBadge key="post-type" status={selectedPost.boardType} />],
                  ["제목", selectedPost.title],
                  ["상태", selectedPost.status ? <StatusBadge key="post-status" status={selectedPost.status} /> : "-"],
                  ["작성자", selectedPost.createdBy],
                  ["작성일", formatDateTime(selectedPost.createdAt)],
                  ["본문", selectedPost.content || "-"],
                  [
                    "첨부 파일",
                    selectedPost.attachments?.length
                      ? selectedPost.attachments.map((attachment) => attachment.fileId).join(", ")
                      : "-",
                  ],
                ].map(([label, value]) => (
                  <div key={String(label)} className="detail-row">
                    <div className="detail-label">{label}</div>
                    <div className="detail-value">{value}</div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-muted fs-12 mb-16">게시글을 선택하면 실제 board 상세 응답이 표시됩니다.</div>
            )}

            <div className="form-group mb-12">
              <label>새 글 유형</label>
              <select value={createBoardType} onChange={(event) => setCreateBoardType(event.target.value)} style={{ width: "100%" }}>
                <option value="GENERAL">일반</option>
                <option value="NOTICE">공지</option>
                <option value="QUALITY">품질</option>
              </select>
            </div>
            <div className="form-group mb-12">
              <label>제목</label>
              <input value={createTitle} onChange={(event) => setCreateTitle(event.target.value)} />
            </div>
            <div className="form-group mb-12">
              <label>본문</label>
              <textarea rows={5} value={createContent} onChange={(event) => setCreateContent(event.target.value)} />
            </div>
            <div className="text-muted fs-12 mb-12">
              작성자는 현재 로그인 계정인 {memberName || memberId || "Mate-SCM 사용자"}로 자동 입력됩니다.
            </div>
            <div className="flex-end">
              <button
                className="btn btn-success"
                onClick={() => void handleCreatePost()}
                disabled={createSubmitting || !createTitle.trim() || !createContent.trim()}
              >
                {createSubmitting ? "작성 중..." : "글 작성"}
              </button>
            </div>
            {createResult ? (
              <div className="alert-banner success mt-12">
                게시글 생성 완료: {createResult.postId} / {formatDateTime(createResult.createdAt)}
              </div>
            ) : null}
          </div>
        </div>
      </div>
    </div>
  );
}
