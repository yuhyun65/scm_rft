import KpiCard from '../components/KpiCard';

const recentActivities = [
  { icon: '✓', cls: 'success', title: '주문 #ORD-2026-0317-042 완료', time: '오늘 14:22 · 거래처: 한국부품(주)' },
  { icon: '!', cls: 'warn',    title: '품질문서 승인 요청 — SQ-2026-031', time: '오늘 13:05 · 김민준 대리' },
  { icon: '📦', cls: '',       title: 'LOT #L20260317-018 입고 처리',  time: '오늘 11:44 · 창고팀' },
  { icon: '✓', cls: 'success', title: '재고 조정 완료 — A-001 (부품A)', time: '오늘 10:30 · 이재현 사원' },
];

const stockAlerts = [
  { code: 'A-001', name: '부품A',   current: 12, safety: 50, level: 'danger' },
  { code: 'C-045', name: '원자재C', current: 38, safety: 60, level: 'warn' },
  { code: 'D-012', name: '소모품D', current: 42, safety: 70, level: 'warn' },
];

const weeklyData = [
  { day: '월', pct: 60 }, { day: '화', pct: 80 }, { day: '수', pct: 70 },
  { day: '목', pct: 90, accent: true }, { day: '금', pct: 55 },
];

export default function DashboardPage() {
  return (
    <div className="page-body">
      <div className="page-title">
        대시보드 <span style={{ fontSize: 13, fontWeight: 400, color: 'var(--color-gray-400)' }}>— 2026년 3월 17일</span>
      </div>

      <div className="kpi-grid">
        <KpiCard label="진행 중 주문" value="142" sub={<><span className="kpi-change up">↑ 12</span> 어제 대비</>} />
        <KpiCard label="검수 대기 LOT" value="28" variant="warn" sub={<><span className="kpi-change down">↑ 5</span> 어제 대비</>} />
        <KpiCard label="이번 주 완료" value="87" variant="success" sub={<><span className="kpi-change up">↑ 3%</span> 지난 주 대비</>} />
        <KpiCard label="재고 경고 품목" value="6" variant="danger" sub="안전재고 미달" />
      </div>

      <div className="grid-2">
        <div className="card">
          <div className="card-header"><span className="card-title">📈 이번 주 주문 현황</span></div>
          <div className="card-body">
            <div style={{ display: 'flex', alignItems: 'flex-end', gap: 8, height: 120, padding: '10px 0 20px' }}>
              {weeklyData.map(({ day, pct, accent }) => (
                <div key={day} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                  <div style={{ width: '100%', height: `${pct}%`, background: accent ? 'var(--color-accent)' : 'var(--color-primary-light)', borderRadius: '3px 3px 0 0' }} />
                  <span style={{ fontSize: 10, color: 'var(--color-gray-500)' }}>{day}</span>
                </div>
              ))}
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--color-gray-400)', paddingTop: 8, borderTop: '1px solid var(--color-gray-100)' }}>
              <span>완료: <strong className="text-success">87건</strong></span>
              <span>처리중: <strong className="text-primary">142건</strong></span>
              <span>취소: <strong className="text-danger">4건</strong></span>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header"><span className="card-title">🔔 최근 활동</span></div>
          <div className="card-body" style={{ padding: '12px 16px' }}>
            <div className="timeline">
              {recentActivities.map((a, i) => (
                <div key={i} className="tl-item">
                  <div className={`tl-dot ${a.cls}`}>{a.icon}</div>
                  <div><div className="tl-title">{a.title}</div><div className="tl-time">{a.time}</div></div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <span className="card-title">⚠️ 재고 경고 품목</span>
        </div>
        <div className="card-body">
          <div className="grid-3">
            {stockAlerts.map(s => (
              <div key={s.code} style={{ padding: '10px 14px', border: `1px solid ${s.level === 'danger' ? '#fee2e2' : '#fef3c7'}`, borderRadius: 6, background: s.level === 'danger' ? '#fff5f5' : '#fffbeb' }}>
                <div className="fw-700">{s.name} ({s.code})</div>
                <div className="fs-11 text-muted mt-4">현재: {s.current}개 / 안전재고: {s.safety}개</div>
                <div className="stock-bar mt-4">
                  <div className={`stock-bar-fill ${s.level}`} style={{ width: `${Math.round(s.current / s.safety * 100)}%` }} />
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
