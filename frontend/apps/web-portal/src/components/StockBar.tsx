import clsx from 'clsx';

interface Props { current: number; safety: number; }

export default function StockBar({ current, safety }: Props) {
  const pct = safety > 0 ? Math.min(Math.round((current / safety) * 100), 100) : 100;
  const level = pct < 30 ? 'danger' : pct < 70 ? 'warn' : '';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <div className="stock-bar" style={{ width: 80, display: 'inline-block' }}>
        <div className={clsx('stock-bar-fill', level)} style={{ width: `${pct}%` }} />
      </div>
      <span className={clsx('fs-11', level === 'danger' ? 'text-danger' : level === 'warn' ? 'text-warning' : 'text-success')}>
        {pct}%
      </span>
    </div>
  );
}
