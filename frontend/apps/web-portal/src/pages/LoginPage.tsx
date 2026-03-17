import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../store/authStore';
import AuthLayout from '../layouts/AuthLayout';

interface Props { apiBaseUrl?: string; }

export default function LoginPage({ apiBaseUrl = '' }: Props) {
  const navigate = useNavigate();
  const { setAuth } = useAuthStore();
  const [loginId, setLoginId] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    if (!loginId || !password) { setError('아이디와 비밀번호를 입력해주세요.'); return; }
    setLoading(true); setError('');
    try {
      const res = await fetch(`${apiBaseUrl}/api/auth/v1/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ loginId, password }),
      });
      if (!res.ok) { setError('아이디 또는 비밀번호가 올바르지 않습니다.'); return; }
      const data = await res.json();
      setAuth(data.accessToken, data.memberId, loginId, data.roles ?? []);
      navigate('/dashboard', { replace: true });
    } catch {
      setError('서버 연결에 실패했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout>
      <div className="login-box">
        <div className="login-logo">🔧 HISCM</div>
        <div className="login-subtitle">공급망 관리 시스템 — 신규 플랫폼</div>
        <form onSubmit={handleSubmit}>
          <div className="form-group mb-12">
            <input
              type="text" className="btn-full" style={{ border: '1px solid #d1d5db', borderRadius: 5, padding: '10px 14px', fontSize: 13 }}
              placeholder="아이디" value={loginId}
              onChange={e => setLoginId(e.target.value)} autoFocus
            />
          </div>
          <div className="form-group mb-12">
            <input
              type="password" style={{ border: '1px solid #d1d5db', borderRadius: 5, padding: '10px 14px', fontSize: 13, width: '100%' }}
              placeholder="비밀번호" value={password}
              onChange={e => setPassword(e.target.value)}
            />
          </div>
          {error && <div style={{ color: '#dc2626', fontSize: 12, marginBottom: 8 }}>{error}</div>}
          <button type="submit" className="btn btn-primary btn-full" disabled={loading}>
            {loading ? '로그인 중...' : '로그인'}
          </button>
        </form>
        <div className="login-notice">
          ⚠ 이 시스템은 사내 전용입니다.<br />
          세션은 브라우저 종료 시 자동 만료됩니다.
        </div>
      </div>
    </AuthLayout>
  );
}
