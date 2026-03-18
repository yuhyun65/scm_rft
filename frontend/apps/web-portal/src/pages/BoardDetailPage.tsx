import { useEffect, useState } from "react";
import type { BoardPostDetail } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

export default function BoardDetailPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const params = useParams();
  const postId = decodeURIComponent(params.postId ?? "");
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [post, setPost] = useState<BoardPostDetail | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadPost() {
      if (!postId) {
        return;
      }

      setLoading(true);
      setErrorText("");
      try {
        const result = await client.getBoardPost(postId);
        if (!cancelled) {
          setPost(result);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setPost(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadPost();
    return () => {
      cancelled = true;
    };
  }, [client, postId]);

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate("/board")}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            게시글 상세
          </span>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">{postId || "게시글 ID 없음"}</span>
        </div>
        <div className="card-body">
          {loading ? (
            <div className="text-muted">게시글 상세를 불러오는 중입니다.</div>
          ) : post ? (
            <>
              {[
                ["게시글 ID", post.postId],
                ["유형", <StatusBadge key="post-type" status={post.boardType} />],
                ["제목", post.title],
                ["상태", post.status ? <StatusBadge key="post-status" status={post.status} /> : "-"],
                ["작성자", post.createdBy],
                ["작성일", formatDateTime(post.createdAt)],
                ["본문", post.content || "-"],
                [
                  "첨부 파일",
                  post.attachments?.length ? post.attachments.map((attachment) => attachment.fileId).join(", ") : "-",
                ],
              ].map(([label, value]) => (
                <div key={String(label)} className="detail-row">
                  <div className="detail-label">{label}</div>
                  <div className="detail-value">{value}</div>
                </div>
              ))}
            </>
          ) : (
            <div className="text-muted">게시글을 찾지 못했습니다.</div>
          )}
        </div>
      </div>
    </div>
  );
}
