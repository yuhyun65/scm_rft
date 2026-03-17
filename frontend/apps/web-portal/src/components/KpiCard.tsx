import clsx from 'clsx';
import { type ReactNode } from 'react';

interface Props {
  label: string;
  value: ReactNode;
  sub?: ReactNode;
  variant?: 'default' | 'warn' | 'success' | 'danger';
}

export default function KpiCard({ label, value, sub, variant = 'default' }: Props) {
  return (
    <div className={clsx('kpi-card', variant !== 'default' && variant)}>
      <div className="kpi-label">{label}</div>
      <div className="kpi-value">{value}</div>
      {sub && <div className="kpi-sub">{sub}</div>}
    </div>
  );
}
