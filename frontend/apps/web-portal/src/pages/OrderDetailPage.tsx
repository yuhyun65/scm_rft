import { useNavigate, useParams } from 'react-router-dom';
import StatusBadge from '../components/StatusBadge';

const timeline = [
  { icon: '접수', cls: 'success', title: '주문 접수 완료', time: '2026-03-17 09:14 / 김민수' },
  { icon: '확정', cls: 'success', title: '거래처 확정 통보', time: '2026-03-17 10:30 / 시스템 자동 발송' },
  { icon: '생산', cls: '', title: '생산 착수 (IN_PROGRESS)', time: '2026-03-17 13:00 / 이재훈' },
  { icon: '예정', cls: 'gray', title: '납품 완료 예정 (03-25)', time: '미완료', dim: true },
];

const lots = [
  { lotNo: 'L20260317-018', quantity: '320 EA', startedAt: '2026-03-17 13:00', qualityResult: '양호', note: '1차 생산 라인' },
  { lotNo: 'L20260317-019', quantity: '180 EA', startedAt: '2026-03-17 14:10', qualityResult: '검사 대기', note: '추가 생산분' },
];

export default function OrderDetailPage() {
  const navigate = useNavigate();
  const { orderId } = useParams();

  return (
    <div className="page-body">
      <div className="flex-between mb-16">
        <div className="flex gap-12" style={{ alignItems: 'center' }}>
          <button className="btn btn-gray btn-sm" onClick={() => navigate('/orders')}>
            목록으로
          </button>
          <span className="fw-700" style={{ fontSize: 18 }}>{orderId ?? 'ORD-2026-0317-042'}</span>
          <StatusBadge status="IN_PROGRESS" />
        </div>
        <div className="flex gap-8">
          <button className="btn btn-outline">수정</button>
          <button className="btn btn-success">상태 변경</button>
          <button className="btn btn-gray">리포트</button>
        </div>
      </div>

      <div className="grid-2 mb-16">
        <div className="card">
          <div className="card-header">
            <span className="card-title">주문 기본 정보</span>
          </div>
          <div className="card-body">
            {[
              ['주문번호', orderId ?? 'ORD-2026-0317-042'],
              ['거래처', '공급부품(주)'],
              ['품목코드', 'A-001'],
              ['품목명', '부품 A'],
              ['주문수량', '500 EA'],
              ['단가', '25,000원'],
              ['주문금액', <strong className="text-primary">12,500,000원</strong>],
              ['납기일', '2026-03-25'],
              ['담당자', '김민수 (공급관리)'],
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
          <div className="card-header">
            <span className="card-title">처리 이력</span>
          </div>
          <div className="card-body" style={{ padding: '12px 16px' }}>
            <div className="timeline">
              {timeline.map((item, index) => (
                <div key={index} className="tl-item" style={{ opacity: item.dim ? 0.4 : 1 }}>
                  <div className={`tl-dot ${item.cls}`}>{item.icon}</div>
                  <div>
                    <div className="tl-title">{item.title}</div>
                    <div className="tl-time">{item.time}</div>
                  </div>
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
            <thead>
              <tr>
                <th>LOT번호</th>
                <th>수량</th>
                <th>생산일시</th>
                <th>검사결과</th>
                <th>비고</th>
              </tr>
            </thead>
            <tbody>
              {lots.map((lot) => (
                <tr key={lot.lotNo}>
                  <td>{lot.lotNo}</td>
                  <td>{lot.quantity}</td>
                  <td>{lot.startedAt}</td>
                  <td>{lot.qualityResult}</td>
                  <td>{lot.note}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
