import { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import KpiCard from '../components/KpiCard';

const recentJobs = [
  { name: '주문현황_20260317.pdf', type: '주문 현황', status: 'COMPLETED', time: '03-17 14:05' },
  { name: '재고현황_20260315.xlsx', type: '재고 현황', status: 'COMPLETED', time: '03-15 09:22' },
  { name: '납품실적_202603.pdf', type: '납품 실적', status: 'IN_PROGRESS', time: '03-17 15:01' },
];

export default function ReportPage() {
  const [reportType, setReportType] = useState('주문 현황 보고서');
  const [format, setFormat] = useState('PDF');

  return (
    <div className="page-body">
      <div className="page-title">보고서 관리</div>
      <div className="grid-2">
        <div className="card">
          <div className="card-header"><span className="card-title">📋 보고서 생성</span></div>
          <div className="card-body">
            <div className="form-group mb-12">
              <label>보고서 유형</label>
              <select style={{ width: '100%' }} value={reportType} onChange={e => setReportType(e.target.value)}>
                <option>주문 현황 보고서</option>
                <option>재고 현황 보고서</option>
                <option>거래처별 납품 실적</option>
                <option>품질 검사 결과서</option>
                <option>월별 발주 통계</option>
              </select>
            </div>
            <div className="form-row mb-12">
              <div className="form-group" style={{ flex: 1 }}>
                <label>기간 (시작)</label>
                <input type="date" defaultValue="2026-03-01" style={{ width: '100%' }} />
              </div>
              <div className="form-group" style={{ flex: 1 }}>
                <label>기간 (종료)</label>
                <input type="date" defaultValue="2026-03-17" style={{ width: '100%' }} />
              </div>
            </div>
            <div className="form-group mb-12">
              <label>거래처 (선택)</label>
              <select style={{ width: '100%' }}><option>전체</option><option>한국부품(주)</option><option>대성산업(주)</option></select>
            </div>
            <div className="form-group mb-12">
              <label>출력 형식</label>
              <div className="flex gap-12 mt-4">
                {['PDF', 'Excel', 'CSV'].map(f => (
                  <label key={f} style={{ display: 'flex', alignItems: 'center', gap: 4, fontWeight: 400, fontSize: 12.5 }}>
                    <input type="radio" name="fmt" value={f} checked={format === f} onChange={() => setFormat(f)} /> {f}
                  </label>
                ))}
              </div>
            </div>
            <div className="flex-end mt-8">
              <button className="btn btn-primary">📊 보고서 생성</button>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header"><span className="card-title">🕒 최근 생성 이력</span></div>
          <div className="card-body" style={{ padding: '10px 16px' }}>
            <table>
              <thead><tr><th>파일명</th><th>유형</th><th>상태</th><th>요청일시</th><th></th></tr></thead>
              <tbody>
                {recentJobs.map(j => (
                  <tr key={j.name}>
                    <td className="fs-12">{j.name}</td>
                    <td className="fs-12">{j.type}</td>
                    <td><StatusBadge status={j.status} /></td>
                    <td className="fs-11">{j.time}</td>
                    <td>
                      {j.status === 'COMPLETED'
                        ? <button className="btn btn-sm btn-outline">다운</button>
                        : <button className="btn btn-sm btn-gray">대기중</button>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header"><span className="card-title">📈 3월 주요 통계 요약</span></div>
        <div className="card-body">
          <div className="grid-3">
            <div style={{ textAlign: 'center', padding: '16px', border: '1px solid var(--color-gray-100)', borderRadius: 8 }}>
              <div className="fs-11 text-muted mb-8">이번 달 발주 금액</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--color-primary)' }}>2.8억</div>
              <div className="fs-11 text-success mt-4">↑ 전월 대비 +8%</div>
            </div>
            <div style={{ textAlign: 'center', padding: '16px', border: '1px solid var(--color-gray-100)', borderRadius: 8 }}>
              <div className="fs-11 text-muted mb-8">납기 준수율</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--color-success)' }}>96.4%</div>
              <div className="fs-11 text-success mt-4">↑ 전월 대비 +1.2%</div>
            </div>
            <div style={{ textAlign: 'center', padding: '16px', border: '1px solid var(--color-gray-100)', borderRadius: 8 }}>
              <div className="fs-11 text-muted mb-8">불량률</div>
              <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--color-warning)' }}>0.8%</div>
              <div className="fs-11 text-success mt-4">↓ 전월 대비 -0.3%</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
