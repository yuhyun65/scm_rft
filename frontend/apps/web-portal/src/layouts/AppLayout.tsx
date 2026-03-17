import { Outlet, useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import Sidebar from '../components/Sidebar';
import Header from '../components/Header';

export default function AppLayout() {
  const { isAuthenticated, clearAuth } = useAuthStore();
  const navigate = useNavigate();

  if (!isAuthenticated()) {
    navigate('/login', { replace: true });
    return null;
  }

  const handleLogout = () => {
    clearAuth();
    navigate('/login', { replace: true });
  };

  return (
    <div className="app-shell">
      <Sidebar />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
        <Header onLogout={handleLogout} />
        <main className="main-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
