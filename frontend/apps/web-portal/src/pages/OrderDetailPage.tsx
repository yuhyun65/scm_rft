import { useNavigate, useParams } from 'react-router-dom';
import StatusBadge from '../components/StatusBadge';

const timeline = [
  { icon: '✓', cls: 'success', title: '주문 접수 완료', time: '2026-03-17 09:14 · 김민준' },
  { icon: '✓', cls: 'success', title: '거래처 확정 통보', time: '2026-03-17 10:30 · 시스템 자동' },
  { icon: '▶', cls: '',        title: '생산 착수 (IN_PROGRESS)', time: '2026-03-17 13:00 · 이재현' },
  { icon: '○', cls: 'gray',    title: '납품 완료 (예정: 03-25)', time: '미완료', dim: true },
];

export default function OrderDetailPage() {
  const navigate = useNavigate();
  const { orderId } = useParams();

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: 'center' }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate('/orders')}>← 목록으로</button>
          <span className="fw-700" style={{ fontSize: 18 }}>{orderId ?? 'ORD-2026-0317-042'}</span>
          <StatusBadge status="IN_PROGRESS" />
        </div>
        <div className="flex gap-8">
          <button className="btn btn-outline">수정</button>
          <button className="btn btn-success">상태 변경</button>
          <button className="btn btn-gray">📊 리포트</button>
        </div>
      </div>

      <div className="grid-2 mb-16">
        <div className="card">
          <div className="card-header"><span className="card-title">주문 기본 정보</span></div>
          <div className="card-body">
            {[
              ['주문번호', orderId ?? 'ORD-2026-0317-042'],
              ['거래처', '한국부품(주)'],
              ['품목코드', 'A-001'],
              ['품목명', '부품A'],
              ['주문수량', '500 개'],
              ['단가', '25,000 원'],
              ['주문금액', <strong className="text-primary">12,500,000 원</strong>],
              ['납기일', '2026-03-25'],
              ['담당자', '김민준 (공급관리팀)'],
              ['등록일시', '2026-03-17 09:14'],
            ].map(([label, value]) => (
              <div key={String(label)} className="detail-row">
                <div className="detail-label">{label}</div>
                <div className="detail-value">{value}</div>
              </div>
            ))}
          </div>
        </div>

        <div className="card">
          <div className="card-header"><span className="card-title">처리 이력</span></div>
          <div className="card-body" style={{ padding: '12px 16px' }}>
            <div className="timeline">
              {timeline.map((t, i) => (
                <div key={i} className="tl-item" style={{ opacity: t.dim ? .4 : 1 }}>
                  <div className={`tl-dot ${t.cls}`}>{t.icon}</div>
                  <div><div className="tl-title">{t.title}</div><div className="tl-time">{t.time}</div></div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="card mb-12">
        <div className="card-header">
          <span className="card-title">연결 LOT 목록</span>
          <button className="btn btn-sm btn-outline">+ LOT 추가</button>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead><tr><th>LOT번호</th><th>수량</th><th>생산일</th><th>검수결과</th><th>비고</th></tr></thead>
            <tbody>
              <tr><td>L20260317-018</td><td>200</td><td>2026-03-17</td><td><StatusBadge status="COMPLETED" /></td><td>1차 생산분</td></tr>
              <tr><td>L20260318-005</td><td>300</td><td>2026-03-18 (예정)</td><td><StatusBadge status="PENDING" /></td><td>2차 생산분</td></tr>
            </tbody>
          </table>
        </div>
      </div>

      <div className="card">
        <div className="card-header"><span className="card-title">첨부 파일</span><button className="btn btn-sm btn-outline">+ 파일 업로드</button></div>
        <div className="card-body">
          <span className="attachment-item"><span>📄</span><span className="file-name">주문서_20260317.pdf</span><span className="file-size">245KB</span></span>
          <span className="attachment-item"><span>📊</span><span className="file-name">품목사양서.xlsx</span><span className="file-size">88KB</span></span>
        </div>
      </div>
    </div>
  );
}
