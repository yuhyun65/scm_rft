import { useState } from 'react';
import StatusBadge from '../components/StatusBadge';
import Pagination from '../components/Pagination';

const MOCK = [
  { id: 'SUP-0012', name: '한국부품(주)', bizNo: '123-45-67890', ceo: '홍길동', tel: '02-1234-5678', since: '2020-01-05', status: 'ACTIVE', lastOrder: '2026-03-17' },
  { id: 'SUP-0031', name: '대성산업(주)', bizNo: '234-56-78901', ceo: '김철수', tel: '031-234-5678', since: '2021-06-15', status: 'ACTIVE', lastOrder: '2026-03-16' },
  { id: 'SUP-0044', name: '글로벌소재(주)', bizNo: '345-67-89012', ceo: '이영희', tel: '032-345-6789', since: '2022-03-20', status: 'ACTIVE', lastOrder: '2026-03-15' },
  { id: 'SUP-0018', name: '미래물산(주)', bizNo: '456-78-90123', ceo: '박민수', tel: '051-456-7890', since: '2019-11-01', status: 'INACTIVE', lastOrder: '2025-12-10' },
];

export default function MemberPage() {
  const [page, setPage] = useState(0);
  return (
    <div className="page-body">
      <div className="page-title">거래처 관리</div>
      <div className="card mb-12">
        <div className="card-body" style={{ padding: '14px 16px' }}>
          <div className="form-row">
            <div className="form-group"><label>상태</label><select style={{ width: 100 }}><option>전체</option><option>활성</option><option>비활성</option></select></div>
            <div className="form-group"><label>검색어</label><input type="text" placeholder="거래처명 / 사업자번호" style={{ width: 200 }} /></div>
            <div className="form-group"><label style={{ visibility: 'hidden' }}>조</label><button className="btn btn-primary">🔍 조회</button></div>
            <div className="form-group" style={{ marginLeft: 'auto' }}><label style={{ visibility: 'hidden' }}>등</label><button className="btn btn-success">+ 거래처 등록</button></div>
          </div>
        </div>
      </div>
      <div className="card">
        <div className="card-header"><span className="card-title">거래처 목록 <span className="text-muted fw-600 fs-12">총 48건</span></span></div>
        <div className="tbl-wrap">
          <table>
            <thead><tr><th><input type="checkbox" /></th><th>거래처 ID</th><th>거래처명</th><th>사업자번호</th><th>대표자</th><th>연락처</th><th>거래 시작일</th><th>상태</th><th>최근 주문</th><th>액션</th></tr></thead>
            <tbody>
              {MOCK.map(m => (
                <tr key={m.id}>
                  <td><input type="checkbox" /></td>
                  <td>{m.id}</td>
                  <td className="fw-600">{m.name}</td>
                  <td>{m.bizNo}</td>
                  <td>{m.ceo}</td>
                  <td>{m.tel}</td>
                  <td>{m.since}</td>
                  <td><StatusBadge status={m.status} /></td>
                  <td>{m.lastOrder}</td>
                  <td><button className="btn btn-sm btn-outline">상세</button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination page={page} totalPages={3} onChange={setPage} />
      </div>
    </div>
  );
}
