import { useState } from "react";
import type { ReportJob } from "@scm-rft/api-client";
import { useNavigate } from "react-router-dom";
import StatusBadge from "../components/StatusBadge";
import { formatDateTime, formatErrorText, useAuthIdentity, useScmApiClient } from "../lib/scmApi";

const REPORT_OPTIONS = [
  { value: "P0_DAILY", label: "P0 일일 운영 보고서" },
  { value: "ORDER_STATUS", label: "주문 현황 보고서" },
  { value: "INVENTORY_SUMMARY", label: "재고 현황 보고서" },
  { value: "QUALITY_SUMMARY", label: "품질 실적 요약 보고서" },
];

export default function ReportPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const { memberId, memberName } = useAuthIdentity();
  const [reportType, setReportType] = useState("P0_DAILY");
  const [requestedByMemberId, setRequestedByMemberId] = useState(memberId);
  const [jobId, setJobId] = useState("");
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [jobHistory, setJobHistory] = useState<ReportJob[]>([]);

  async function handleCreateJob() {
    setLoading(true);
    setErrorText("");
    try {
      const result = await client.createReportJob({
        reportType,
        requestedByMemberId: requestedByMemberId || undefined,
      });
      setJobId(result.jobId);
      setJobHistory((current) => [result, ...current.filter((job) => job.jobId !== result.jobId)].slice(0, 5));
    } catch (error) {
      setErrorText(formatErrorText(error));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="page-body">
      <div className="page-title">보고서 관리</div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="grid-2">
        <div className="card">
          <div className="card-header">
            <span className="card-title">새 보고서 생성</span>
          </div>
          <div className="card-body">
            <div className="form-group mb-12">
              <label>보고서 유형</label>
              <select style={{ width: "100%" }} value={reportType} onChange={(event) => setReportType(event.target.value)}>
                {REPORT_OPTIONS.map((option) => (
                  <option key={option.value} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-group mb-12">
              <label>요청자 Member ID</label>
              <input
                value={requestedByMemberId}
                onChange={(event) => setRequestedByMemberId(event.target.value)}
                placeholder={memberId || memberName || "자동 입력 가능"}
              />
            </div>
            <div className="text-muted fs-12 mb-12">
              보고서 생성 API는 현재 비동기 job 생성/상세 조회만 제공합니다. 다운로드는 outputFileId가 내려온 뒤 별도 파일 서비스 연계가 필요합니다.
            </div>
            <div className="flex-end mt-8">
              <button className="btn btn-primary" onClick={() => void handleCreateJob()} disabled={loading}>
                {loading ? "생성 중..." : "보고서 생성"}
              </button>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <span className="card-title">보고서 Job 상세 이동</span>
          </div>
          <div className="card-body">
            <div className="form-row mb-12">
              <div className="form-group" style={{ flex: 1 }}>
                <label>Job ID</label>
                <input value={jobId} onChange={(event) => setJobId(event.target.value)} placeholder="생성된 jobId 또는 조회할 jobId" />
              </div>
              <div className="form-group">
                <label style={{ visibility: "hidden" }}>조회</label>
                <button className="btn btn-outline" onClick={() => navigate(`/reports/${encodeURIComponent(jobId.trim())}`)} disabled={!jobId.trim()}>
                  상세 페이지 이동
                </button>
              </div>
            </div>
            <div className="text-muted fs-12">
              생성된 job이나 기존 job ID를 입력하면 dedicated route에서 실제 job 상세를 확인할 수 있습니다.
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">최근 조회/생성 이력</span>
        </div>
        <div className="card-body" style={{ padding: "10px 16px" }}>
          <table>
            <thead>
              <tr>
                <th>Job ID</th>
                <th>유형</th>
                <th>상태</th>
                <th>요청일시</th>
                <th>출력 파일</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {jobHistory.length === 0 ? (
                <tr>
                  <td colSpan={6} className="text-center text-muted" style={{ padding: 24 }}>
                    이 세션에서 생성하거나 조회한 보고서 job이 없습니다.
                  </td>
                </tr>
              ) : (
                jobHistory.map((job) => (
                  <tr key={job.jobId}>
                    <td className="fs-12">{job.jobId}</td>
                    <td className="fs-12">{job.reportType}</td>
                    <td>
                      <StatusBadge status={job.status} />
                    </td>
                    <td className="fs-11">{formatDateTime(job.requestedAt)}</td>
                    <td className="fs-11">{job.outputFileId || "-"}</td>
                    <td>
                      <button className="btn btn-sm btn-outline" onClick={() => navigate(`/reports/${encodeURIComponent(job.jobId)}`)}>
                        다시 조회
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
