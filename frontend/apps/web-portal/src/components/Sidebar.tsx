import { useNavigate, useLocation } from 'react-router-dom';
import clsx from 'clsx';

interface NavItem {
  icon: string;
  label: string;
  path: string;
  badge?: number;
}

const NAV: { section: string; items: NavItem[] }[] = [
  {
    section: '홈',
    items: [{ icon: '🏠', label: '대시보드', path: '/dashboard' }],
  },
  {
    section: '주문/생산',
    items: [
      { icon: '📦', label: '주문 관리', path: '/orders' },
    ],
  },
  {
    section: '재고/물류',
    items: [
      { icon: '🗃️', label: '재고 현황', path: '/inventory' },
    ],
  },
  {
    section: '거래처/인원',
    items: [
      { icon: '🏢', label: '거래처 관리', path: '/members' },
    ],
  },
  {
    section: '품질/문서',
    items: [
      { icon: '✅', label: '품질 문서', path: '/quality-docs', badge: 3 },
      { icon: '📋', label: '게시판', path: '/board' },
    ],
  },
  {
    section: '보고서',
    items: [
      { icon: '📊', label: '보고서 생성', path: '/reports' },
    ],
  },
];

export default function Sidebar() {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <div>
          <div className="logo-text">HISCM</div>
          <div className="logo-sub">공급망 관리 시스템</div>
        </div>
      </div>
      {NAV.map(({ section, items }) => (
        <div key={section}>
          <div className="sidebar-section">{section}</div>
          {items.map(item => (
            <div
              key={item.path}
              className={clsx('sidebar-item', { active: pathname.startsWith(item.path) })}
              onClick={() => navigate(item.path)}
            >
              <span className="sidebar-icon">{item.icon}</span>
              {item.label}
              {item.badge !== undefined && (
                <span className="sidebar-badge">{item.badge}</span>
              )}
            </div>
          ))}
        </div>
      ))}
    </aside>
  );
}
