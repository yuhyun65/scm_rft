import { useLocation } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';

const ROUTE_LABELS: Record<string, string> = {
  '/dashboard': '대시보드',
  '/orders': '주문 관리 / 주문 목록',
  '/inventory': '재고 관리 / 재고 현황',
  '/members': '거래처 관리',
  '/quality-docs': '품질 관리 / 품질 문서',
  '/board': '게시판',
  '/reports': '보고서 관리',
};

interface Props {
  onLogout: () => void;
}

export default function Header({ onLogout }: Props) {
  const { memberName } = useAuthStore();
  const { pathname } = useLocation();

  const label = Object.entries(ROUTE_LABELS).find(([key]) => pathname.startsWith(key))?.[1] ?? '';
  const initial = memberName ? memberName.charAt(0) : 'M';

  return (
    <header className="app-header">
      <span className="logo">Mate-SCM</span>
      {label && <span className="breadcrumb">/ {label}</span>}
      <div className="header-spacer" />
      <div className="user-info">
        <div className="user-avatar">{initial}</div>
        <span>{memberName || '사용자'}</span>
        <button className="btn btn-sm btn-gray" style={{ marginLeft: 8 }} onClick={onLogout}>
          로그아웃
        </button>
      </div>
    </header>
  );
}
