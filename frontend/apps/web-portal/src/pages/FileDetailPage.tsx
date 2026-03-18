import { useEffect, useState } from "react";
import type { FileMetadata } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import { formatErrorText, useScmApiClient } from "../lib/scmApi";

export default function FileDetailPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const params = useParams();
  const fileId = decodeURIComponent(params.fileId ?? "");
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [file, setFile] = useState<FileMetadata | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadFile() {
      if (!fileId) {
        return;
      }

      setLoading(true);
      setErrorText("");
      try {
        const result = await client.getFile(fileId);
        if (!cancelled) {
          setFile(result);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setFile(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadFile();
    return () => {
      cancelled = true;
    };
  }, [client, fileId]);

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate(-1)}>
            뒤로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            파일 메타데이터 상세
          </span>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">{fileId || "파일 ID 없음"}</span>
        </div>
        <div className="card-body">
          {loading ? (
            <div className="text-muted">파일 메타데이터를 불러오는 중입니다.</div>
          ) : file ? (
            <>
              {[
                ["파일 ID", file.fileId],
                ["도메인 키", file.domainKey],
                ["원본 파일명", file.originalName],
                ["저장 경로", file.storagePath],
              ].map(([label, value]) => (
                <div key={String(label)} className="detail-row">
                  <div className="detail-label">{label}</div>
                  <div className="detail-value">{value}</div>
                </div>
              ))}
            </>
          ) : (
            <div className="text-muted">파일 메타데이터를 찾지 못했습니다.</div>
          )}
        </div>
      </div>
    </div>
  );
}
