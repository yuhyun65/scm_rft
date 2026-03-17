import { useMemo } from 'react';
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import AppLayout from './layouts/AppLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import OrderListPage from './pages/OrderListPage';
import OrderDetailPage from './pages/OrderDetailPage';
import InventoryPage from './pages/InventoryPage';
import MemberPage from './pages/MemberPage';
import QualityDocPage from './pages/QualityDocPage';
import BoardPage from './pages/BoardPage';
import ReportPage from './pages/ReportPage';

/** @deprecated kept for test compatibility */
export function formatPortalTitle(scope: string): string {
  return `Mate-SCM Portal (${scope})`;
}

const apiBaseUrl = (import.meta as { env?: Record<string, string> }).env?.VITE_API_BASE_URL ?? '';

const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: 1, staleTime: 30_000 } },
});

export function createAppRouter(resolvedApiBaseUrl: string) {
  return createBrowserRouter([
    { path: '/login', element: <LoginPage apiBaseUrl={resolvedApiBaseUrl} /> },
    {
      element: <AppLayout />,
      children: [
        { path: '/', element: <Navigate to="/dashboard" replace /> },
        { path: '/dashboard', element: <DashboardPage /> },
        { path: '/orders', element: <OrderListPage /> },
        { path: '/orders/:orderId', element: <OrderDetailPage /> },
        { path: '/inventory', element: <InventoryPage /> },
        { path: '/members', element: <MemberPage /> },
        { path: '/quality-docs', element: <QualityDocPage /> },
        { path: '/board', element: <BoardPage /> },
        { path: '/reports', element: <ReportPage /> },
      ],
    },
    { path: '*', element: <Navigate to="/dashboard" replace /> },
  ]);
}

export default function App() {
  const router = useMemo(() => createAppRouter(apiBaseUrl), []);

  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
    </QueryClientProvider>
  );
}

