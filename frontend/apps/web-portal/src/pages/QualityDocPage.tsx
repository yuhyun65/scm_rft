import { useState } from 'react';
import Pagination from '../components/Pagination';
import StatusBadge from '../components/StatusBadge';

const MOCK = [
  { id: 'SQ-2026-031', title: '2026년 1분기 품질 지침서', ver: 'v2.1', author: '김민수', date: '2026-03-15', expires: '2027-03-14', status: 'ACTIVE', ack: false },
  { id: 'SQ-2026-028', title: '원자재 수입 검사 규격 개정', ver: 'v3.0', author: '이재훈', date: '2026-03-10', expires: '2028-03-09', status: 'ACTIVE', ack: false },
  { id: 'SQ-2025-198', title: '공정별 불량 판정 기준', ver: 'v1.5', author: '박수진', date: '2025-12-01', expires: '2026-11-30', status: 'ACTIVE', ack: true },
  { id: 'SQ-2024-102', title: '품질 사양 규격서(구버전)', ver: 'v1.0', author: '최영희', date: '2024-01-15', expires: '2025-01-14', status: 'EXPIRED', ack: true },
];

export default function QualityDocPage() {
  const [page, setPage] = useState(0);

  return (
    <div className="page-body">
      <div className="page-title">품질 문서 관리</div>
      <div className="alert-banner info">
        <span style={{ fontSize: 20 }}>알림</span>
        <div>
          <div className="alert-title">확인 대기 문서 2건</div>
          <div className="alert-desc">SQ-2026-031, SQ-2026-028 문서를 검토하고 ACK 처리해 주세요.</div>
        </div>
        <button className="btn btn-primary btn-sm" style={{ marginLeft: 'auto' }}>
          확인 화면으로 이동
        </button>
      </div>
      <div className="card mb-12">
        <div className="card-body" style={{ padding: '14px 16px' }}>
          <div className="form-row">
            <div className="form-group">
              <label>상태</label>
              <select style={{ width: 140 }}>
                <option>전체</option>
                <option>활성</option>
                <option>만료</option>
                <option>보관</option>
              </select>
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input type="text" placeholder="문서명 검색" style={{ width: 200 }} />
            </div>
            <div className="form-group">
              <label style={{ visibility: 'hidden' }}>조회</label>
              <button className="btn btn-primary">조회</button>
            </div>
            <div className="form-group" style={{ marginLeft: 'auto' }}>
              <label style={{ visibility: 'hidden' }}>등록</label>
              <button className="btn btn-success">+ 문서 등록</button>
            </div>
          </div>
        </div>
      </div>
      <div className="card">
        <div className="card-header">
          <span className="card-title">품질 문서 목록</span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>문서번호</th>
                <th>문서명</th>
                <th>버전</th>
                <th>작성자</th>
                <th>등록일</th>
                <th>유효기간</th>
                <th>상태</th>
                <th>확인여부</th>
                <th>액션</th>
              </tr>
            </thead>
            <tbody>
              {MOCK.map((doc) => (
                <tr key={doc.id}>
                  <td className="fw-600">{doc.id}</td>
                  <td>{doc.title}</td>
                  <td>{doc.ver}</td>
                  <td>{doc.author}</td>
                  <td>{doc.date}</td>
                  <td>{doc.expires}</td>
                  <td><StatusBadge status={doc.status} /></td>
                  <td>
                    {doc.ack ? (
                      <span className="text-success fw-600 fs-12">확인 완료</span>
                    ) : (
                      <span style={{ color: 'var(--color-warning)', fontWeight: 600, fontSize: 12 }}>확인 대기</span>
                    )}
                  </td>
                  <td>
                    {!doc.ack ? (
                      <button className="btn btn-sm btn-primary">ACK 확인</button>
                    ) : doc.status === 'EXPIRED' ? (
                      <button className="btn btn-sm btn-gray">아카이브</button>
                    ) : (
                      <button className="btn btn-sm btn-outline">상세 보기</button>
                    )}
                  </td>
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
