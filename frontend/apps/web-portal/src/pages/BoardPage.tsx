import { useState } from 'react';
import Pagination from '../components/Pagination';
import StatusBadge from '../components/StatusBadge';

const MOCK = [
  { id: 'notice', no: '공지', type: 'NOTICE', title: '[중요] 2026년 1분기 품질 일정 변경 안내', author: '관리자', date: '2026-03-16', views: 284, attach: 1, pinned: true },
  { id: '142', no: '142', type: 'QUALITY', title: '3월 품질 감사 결과 공유 및 불량 개선 현황', author: '김민수', date: '2026-03-15', views: 67, attach: 2, pinned: false },
  { id: '141', no: '141', type: 'GENERAL', title: '시스템 점검 완료 안내 (3/14 반영 1차)', author: '관리자', date: '2026-03-14', views: 123, attach: 0, pinned: false },
  { id: '140', no: '140', type: 'QUALITY', title: '원자재 수입검사 기준 개정 사항 공지', author: '이재훈', date: '2026-03-12', views: 89, attach: 3, pinned: false },
  { id: '139', no: '139', type: 'GENERAL', title: '4월 거래처 교육 일정 공유', author: '박수진', date: '2026-03-10', views: 45, attach: 0, pinned: false },
];

export default function BoardPage() {
  const [page, setPage] = useState(0);

  return (
    <div className="page-body">
      <div className="page-title">게시판</div>
      <div className="card mb-12">
        <div className="card-body" style={{ padding: '14px 16px' }}>
          <div className="form-row">
            <div className="form-group">
              <label>유형</label>
              <select style={{ width: 140 }}>
                <option>전체</option>
                <option>공지</option>
                <option>일반</option>
                <option>품질</option>
              </select>
            </div>
            <div className="form-group">
              <label>키워드</label>
              <input type="text" placeholder="제목 검색" style={{ width: 200 }} />
            </div>
            <div className="form-group">
              <label style={{ visibility: 'hidden' }}>조회</label>
              <button className="btn btn-primary">조회</button>
            </div>
            <div className="form-group" style={{ marginLeft: 'auto' }}>
              <label style={{ visibility: 'hidden' }}>글</label>
              <button className="btn btn-success">+ 글 작성</button>
            </div>
          </div>
        </div>
      </div>
      <div className="card">
        <div className="card-header">
          <span className="card-title">게시글 목록</span>
        </div>
        <div className="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>번호</th>
                <th>유형</th>
                <th>제목</th>
                <th>작성자</th>
                <th>작성일</th>
                <th>조회</th>
                <th>첨부</th>
              </tr>
            </thead>
            <tbody>
              {MOCK.map((post) => (
                <tr key={post.id} style={{ background: post.pinned ? '#fff7ed' : undefined }}>
                  <td>{post.pinned ? '공지' : post.no}</td>
                  <td><StatusBadge status={post.type} /></td>
                  <td className="text-primary fw-600 cursor-pointer">{post.title}</td>
                  <td>{post.author}</td>
                  <td>{post.date}</td>
                  <td>{post.views}</td>
                  <td>{post.attach > 0 ? `파일 ${post.attach}` : '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <Pagination page={page} totalPages={5} onChange={setPage} />
      </div>
    </div>
  );
}
