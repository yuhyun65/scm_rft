import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Pagination from '../components/Pagination';
import StatusBadge from '../components/StatusBadge';

const MOCK_ORDERS = [
  { id: 'ORD-2026-0317-042', supplier: '공급부품(주)', item: '부품 A (A-001)', qty: 500, amount: '12,500,000', dueDate: '2026-03-25', status: 'IN_PROGRESS', manager: '김민수' },
  { id: 'ORD-2026-0316-038', supplier: '대성산업(주)', item: '원자재 B (B-022)', qty: 1200, amount: '8,400,000', dueDate: '2026-03-30', status: 'CONFIRMED', manager: '이재훈' },
  { id: 'ORD-2026-0315-031', supplier: '글로벌자재(주)', item: '모듈 D (D-012)', qty: 300, amount: '3,150,000', dueDate: '2026-03-20', status: 'PENDING', manager: '박수진' },
  { id: 'ORD-2026-0314-027', supplier: '공급부품(주)', item: '부품 C (C-045)', qty: 800, amount: '16,000,000', dueDate: '2026-03-18', status: 'COMPLETED', manager: '김민수' },
  { id: 'ORD-2026-0313-019', supplier: '미래물산(주)', item: '원자재 A (A-005)', qty: 2000, amount: '22,000,000', dueDate: '2026-03-15', status: 'CANCELED', manager: '최영희' },
];

export default function OrderListPage() {
  const navigate = useNavigate();
  const [page, setPage] = useState(0);
  const [statusFilter, setStatusFilter] = useState('');
  const [keyword, setKeyword] = useState('');

  return (
    <div className="page-body">
      <div className="page-title">주문 관리</div>

      <div className="card mb-12">
        <div className="card-body" style={{ padding: '14px 16px' }}>
          <div className="form-row">
            <div className="form-group">
              <label>주문 상태</label>
              <select style={{ width: 140 }} value={statusFilter} onChange={(event) => setStatusFilter(event.target.value)}>
                <option value="">전체</option>
                <option value="PENDING">대기</option>
                <option value="CONFIRMED">확정</option>
                <option value="IN_PROGRESS">진행 중</option>
                <option value="COMPLETED">완료</option>
                <option value="CANCELED">취소</option>
              </select>
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input
                type="text"
                placeholder="주문번호 / 거래처명"
                style={{ width: 180 }}
                value={keyword}
                onChange={(event) => setKeyword(event.target.value)}
              />
            </div>
            <div className="form-group">
              <label style={{ visibility: 'hidden' }}>조회</label>
              <button className="btn btn-primary">조회</button>
            </div>
            <div className="form-group" style={{ marginLeft: 'auto' }}>
              <label style={{ visibility: 'hidden' }}>등록</label>
              <div className="flex gap-8">
                <button className="btn btn-success">+ 주문 등록</button>
                <button className="btn btn-gray">엑셀 다운로드</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">주문 목록 <span className="text-muted fw-600 fs-12">총 {MOCK_ORDERS.length}건</span></span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th><input type="checkbox" /></th>
                <th>주문번호</th>
                <th>거래처명</th>
                <th>품목</th>
                <th>주문수량</th>
                <th>주문금액</th>
                <th>납기일</th>
                <th>상태</th>
                <th>담당자</th>
                <th>액션</th>
              </tr>
            </thead>
            <tbody>
              {MOCK_ORDERS.map((order) => (
                <tr key={order.id}>
                  <td><input type="checkbox" /></td>
                  <td>
                    <span className="text-primary fw-600 cursor-pointer" onClick={() => navigate(`/orders/${order.id}`)}>
                      {order.id}
                    </span>
                  </td>
                  <td>{order.supplier}</td>
                  <td>{order.item}</td>
                  <td className="text-right">{order.qty.toLocaleString()}</td>
                  <td className="text-right">{order.amount}</td>
                  <td>{order.dueDate}</td>
                  <td><StatusBadge status={order.status} /></td>
                  <td>{order.manager}</td>
                  <td>
                    <button className="btn btn-sm btn-outline" onClick={() => navigate(`/orders/${order.id}`)}>
                      상세
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination page={page} totalPages={8} onChange={setPage} />
      </div>
    </div>
  );
}
