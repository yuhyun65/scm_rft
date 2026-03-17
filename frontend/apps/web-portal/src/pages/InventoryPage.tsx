import { useState } from 'react';
import KpiCard from '../components/KpiCard';
import Pagination from '../components/Pagination';
import StockBar from '../components/StockBar';

const MOCK = [
  { code: 'A-001', name: '부품 A', warehouse: '서울창고', current: 12, safety: 50, lastIn: '2026-03-15', level: 'danger' },
  { code: 'B-022', name: '원자재 B', warehouse: '인천창고', current: 96, safety: 80, lastIn: '2026-03-16', level: 'ok' },
  { code: 'C-045', name: '원자재 C', warehouse: '서울창고', current: 38, safety: 60, lastIn: '2026-03-14', level: 'warn' },
  { code: 'D-012', name: '모듈 D', warehouse: '인천창고', current: 42, safety: 70, lastIn: '2026-03-13', level: 'warn' },
];

export default function InventoryPage() {
  const [page, setPage] = useState(0);

  return (
    <div className="page-body">
      <div className="page-title">재고 현황</div>

      <div className="card mb-12">
        <div className="card-body" style={{ padding: '14px 16px' }}>
          <div className="form-row">
            <div className="form-group">
              <label>창고</label>
              <select style={{ width: 130 }}>
                <option>전체</option>
                <option>서울창고</option>
                <option>인천창고</option>
              </select>
            </div>
            <div className="form-group">
              <label>품목코드</label>
              <input type="text" placeholder="코드 입력" style={{ width: 120 }} />
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input type="text" placeholder="품목명 검색" style={{ width: 160 }} />
            </div>
            <div className="form-group">
              <label style={{ visibility: 'hidden' }}>조회</label>
              <button className="btn btn-primary">조회</button>
            </div>
            <div className="form-group" style={{ marginLeft: 'auto' }}>
              <label style={{ visibility: 'hidden' }}>액션</label>
              <div className="flex gap-8">
                <button className="btn btn-gray">엑셀 다운로드</button>
                <button className="btn btn-outline">재고 조정</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 14, marginBottom: 14 }}>
        <KpiCard label="총 품목 수" value="284" sub="정상 재고 보유" variant="success" />
        <KpiCard label="안전재고 미달" value="6" sub="긴급 발주 검토 필요" variant="warn" />
        <KpiCard label="총 재고금액" value={<span style={{ fontSize: 20 }}>4.2억</span>} sub="전월 대비 +2.3%" />
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">재고 목록 <span className="text-muted fw-600 fs-12">총 284건</span></span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>품목코드</th>
                <th>품목명</th>
                <th>창고</th>
                <th>현재고</th>
                <th>안전재고</th>
                <th>재고율</th>
                <th>최종 입고일</th>
                <th>액션</th>
              </tr>
            </thead>
            <tbody>
              {MOCK.map((item) => (
                <tr key={item.code}>
                  <td>{item.code}</td>
                  <td>{item.name}</td>
                  <td>{item.warehouse}</td>
                  <td className={`text-right ${item.level === 'danger' ? 'text-danger' : item.level === 'warn' ? 'text-warning' : ''}`}>
                    {item.current.toLocaleString()}
                  </td>
                  <td className="text-right">{item.safety.toLocaleString()}</td>
                  <td><StockBar current={item.current} safety={item.safety} /></td>
                  <td>{item.lastIn}</td>
                  <td>
                    {item.level === 'danger' ? (
                      <button className="btn btn-sm btn-danger">발주 요청</button>
                    ) : item.level === 'warn' ? (
                      <button className="btn btn-sm btn-outline">발주 검토</button>
                    ) : (
                      <button className="btn btn-sm btn-gray">이력 조회</button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination page={page} totalPages={6} onChange={setPage} />
      </div>
    </div>
  );
}
