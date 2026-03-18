import { useEffect, useState } from "react";
import type { ReportJob } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useScmApiClient } from "../lib/scmApi";

export default function ReportDetailPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const params = useParams();
  const jobId = decodeURIComponent(params.jobId ?? "");
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [job, setJob] = useState<ReportJob | null>(null);

  async function loadJob() {
    if (!jobId) {
      return;
    }

    setLoading(true);
    setErrorText("");
    try {
      const result = await client.getReportJob(jobId);
      setJob(result);
    } catch (error) {
      setErrorText(formatErrorText(error));
      setJob(null);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    void loadJob();
  }, [client, jobId]);

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate("/reports")}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            보고서 Job 상세
          </span>
        </div>
        <button className="btn btn-outline btn-sm" onClick={() => void loadJob()} disabled={loading}>
          {loading ? "새로고침 중..." : "새로고침"}
        </button>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">{jobId || "Job ID 없음"}</span>
        </div>
        <div className="card-body">
          {loading ? (
            <div className="text-muted">Job 상세를 불러오는 중입니다.</div>
          ) : job ? (
            <>
              {[
                ["Job ID", job.jobId],
                ["유형", job.reportType],
                ["상태", <StatusBadge key="report-status" status={job.status} />],
                ["요청자", job.requestedByMemberId || "-"],
                ["요청일시", formatDateTime(job.requestedAt)],
                ["완료일시", formatDateTime(job.completedAt)],
                [
                  "출력 파일 ID",
                  job.outputFileId ? (
                    <button
                      className="btn btn-sm btn-outline"
                      onClick={() => navigate(`/files/${encodeURIComponent(job.outputFileId ?? "")}`)}
                    >
                      {job.outputFileId}
                    </button>
                  ) : "-",
                ],
                ["오류 메시지", job.errorMessage || "-"],
              ].map(([label, value]) => (
                <div key={String(label)} className="detail-row">
                  <div className="detail-label">{label}</div>
                  <div className="detail-value">{value}</div>
                </div>
              ))}
            </>
          ) : (
            <div className="text-muted">보고서 job을 찾지 못했습니다.</div>
          )}
        </div>
      </div>
    </div>
  );
}
