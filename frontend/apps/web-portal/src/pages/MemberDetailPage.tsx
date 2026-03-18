import { useEffect, useState } from "react";
import type { Member } from "@scm-rft/api-client";
import { useNavigate, useParams } from "react-router-dom";
import StatusBadge from "../components/StatusBadge";
import { formatErrorText, useScmApiClient } from "../lib/scmApi";

export default function MemberDetailPage() {
  const navigate = useNavigate();
  const client = useScmApiClient();
  const params = useParams();
  const memberId = decodeURIComponent(params.memberId ?? "");
  const [loading, setLoading] = useState(false);
  const [errorText, setErrorText] = useState("");
  const [member, setMember] = useState<Member | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function loadMember() {
      if (!memberId) {
        return;
      }

      setLoading(true);
      setErrorText("");
      try {
        const result = await client.getMember(memberId);
        if (!cancelled) {
          setMember(result);
        }
      } catch (error) {
        if (!cancelled) {
          setErrorText(formatErrorText(error));
          setMember(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    void loadMember();
    return () => {
      cancelled = true;
    };
  }, [client, memberId]);

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: "center" }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate("/members")}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>
            거래처 상세
          </span>
        </div>
      </div>

      {errorText ? <div className="alert-banner danger mb-12">{errorText}</div> : null}

      <div className="card">
        <div className="card-header">
          <span className="card-title">{memberId || "거래처 ID 없음"}</span>
        </div>
        <div className="card-body">
          {loading ? (
            <div className="text-muted">거래처 상세를 불러오는 중입니다.</div>
          ) : member ? (
            <>
              {[
                ["거래처 ID", member.memberId],
                ["거래처명", member.memberName || "-"],
                ["상태", member.status ? <StatusBadge key="member-status" status={member.status} /> : "-"],
              ].map(([label, value]) => (
                <div key={String(label)} className="detail-row">
                  <div className="detail-label">{label}</div>
                  <div className="detail-value">{value}</div>
                </div>
              ))}
            </>
          ) : (
            <div className="text-muted">거래처를 찾지 못했습니다.</div>
          )}
        </div>
      </div>
    </div>
  );
}
