import { useLocation, useNavigate } from 'react-router-dom';
import clsx from 'clsx';

interface NavItem {
  icon?: string;
  label: string;
  path: string;
  badge?: number;
}

const NAV: { section: string; items: NavItem[] }[] = [
  {
    section: '메인',
    items: [{ label: '대시보드', path: '/dashboard' }],
  },
  {
    section: '주문/생산',
    items: [{ label: '주문 관리', path: '/orders' }],
  },
  {
    section: '재고/물류',
    items: [{ label: '재고현황', path: '/inventory' }],
  },
  {
    section: '거래처/인원',
    items: [{ label: '거래관리', path: '/members' }],
  },
  {
    section: '품질/문서',
    items: [
      { label: '품질문서', path: '/quality-docs' },
      { label: '게시판', path: '/board' },
    ],
  },
  {
    section: '보고서',
    items: [{ label: '보고서 생성', path: '/reports' }],
  },
];

export default function Sidebar() {
  const navigate = useNavigate();
  const { pathname } = useLocation();

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <div>
          <div className="logo-text">Mate-SCM</div>
        </div>
      </div>
      {NAV.map(({ section, items }) => (
        <div key={section}>
          {items.map((item) => (
            <div
              key={item.path}
              className={clsx('sidebar-item', { active: pathname.startsWith(item.path) })}
              onClick={() => navigate(item.path)}
            >
              {item.icon && <span className="sidebar-icon">{item.icon}</span>}
              {item.label}
              {item.badge !== undefined && <span className="sidebar-badge">{item.badge}</span>}
            </div>
          ))}
        </div>
      ))}
    </aside>
  );
}
