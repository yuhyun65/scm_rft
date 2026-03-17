import { type ReactNode } from 'react';

interface Props { children: ReactNode; }

export default function AuthLayout({ children }: Props) {
  return <div className="auth-layout">{children}</div>;
}
