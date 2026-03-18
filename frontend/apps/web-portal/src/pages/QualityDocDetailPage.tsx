import { useEffect, useState } from "react";
import type { QualityDocumentAckResponse, QualityDocumentDetail } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useAuthIdentity, useScmApiClient } from "../lib/scmApi";

export default function QualityDocDetailPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const { memberId, memberName } = useAuthIdentity();
  const params = useParams();
  const documentId = decodeURIComponent(params.documentId ?? "");
  const [loading, setLoading] = useState(false);
  const [ackSubmitting, setAckSubmitting] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [document, setDocument] = useState<QualityDocumentDetail | null>(null);
  const [ackResult, setAckResult] = useState<QualityDocumentAckResponse | null>(null);
  const [ackType, setAckType] = useState("READ");
  const [ackComment, setAckComment] = useState("");

  async function loadDocument() {
    if (!documentId) {
      return;
    }

    setLoading(true);
    setErrorText("");
    try {
      const result = await client.getQualityDocument(documentId);
      setDocument(result);
    } catch (error) {
      setErrorText(formatErrorText(error));
      setDocument(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadDocument();
  }, [client, documentId]);

  async function handleAcknowledge() {
    if (!documentId) {
      return;
    }

    setAckSubmitting(true);
    setErrorText("");
    try {
      const result = await client.acknowledgeQualityDocument(documentId, {
        memberId: memberId || memberName || "mate-scm-user",
        ackType,
        comment: ackComment.trim() || undefined,
      });
      setAckResult(result);
      await loadDocument();
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setAckSubmitting(false);
    }
  }

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate("/quality-docs")}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            품질 문서 상세
          </span>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="grid-2">
        <div className="card">
          <div className="card-header">
            <span className="card-title">{documentId || "문서 ID 없음"}</span>
          </div>
          <div className="card-body">
            {loading ? (
              <div className="text-muted">문서 상세를 불러오는 중입니다.</div>
            ) : document ? (
              <>
                {[
                  ["문서번호", document.documentId],
                  ["문서명", document.title],
                  ["상태", <StatusBadge key="doc-status" status={document.status} />],
                  ["등록일", formatDateTime(document.issuedAt)],
                  ["버전", document.version || "-"],
                  ["ACK 필요", document.requiresAck ? "예" : "아니오"],
                  ["콘텐츠 URL", document.contentUrl || "-"],
                ].map(([label, value]) => (
                  <div key={String(label)} className="detail-row">
                    <div className="detail-label">{label}</div>
                    <div className="detail-value">{value}</div>
                  </div>
                ))}
              </>
            ) : (
              <div className="text-muted">문서를 찾지 못했습니다.</div>
            )}
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">ACK 처리</span>
          </div>
          <div className="card-body">
            <div className="form-group mb-12">
              <label>ACK 유형</label>
              <select value={ackType} onChange={(event) => setAckType(event.target.value)} style={{ width: "100%" }}>
                <option value="READ">READ</option>
                <option value="CONFIRMED">CONFIRMED</option>
              </select>
            </div>
            <div className="form-group mb-12">
              <label>코멘트</label>
              <textarea rows={4} value={ackComment} onChange={(event) => setAckComment(event.target.value)} />
            </div>
            <div className="flex-end">
              <button className="btn btn-primary" onClick={() => void handleAcknowledge()} disabled={ackSubmitting || !document}>
                {ackSubmitting ? "ACK 처리 중..." : "ACK 실행"}
              </button>
            </div>
            {ackResult ? (
              <div className="alert-banner success mt-12">
                {ackResult.documentId} / {ackResult.ackType} / {ackResult.duplicateRequest ? "중복 ACK" : "ACK 완료"} /{" "}
                {formatDateTime(ackResult.acknowledgedAt)}
              </div>
            ) : null}
          </div>
        </div>
      </div>
    </div>
  );
}
