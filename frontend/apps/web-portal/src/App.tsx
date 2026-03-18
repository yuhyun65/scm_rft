import { useMemo } from 'react';
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import AppLayout from './layouts/AppLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import OrderListPage from './pages/OrderListPage';
import OrderDetailPage from './pages/OrderDetailPage';
import InventoryPage from './pages/InventoryPage';
import InventoryDetailPage from './pages/InventoryDetailPage';
import MemberPage from './pages/MemberPage';
import MemberDetailPage from './pages/MemberDetailPage';
import QualityDocPage from './pages/QualityDocPage';
import QualityDocDetailPage from './pages/QualityDocDetailPage';
import BoardPage from './pages/BoardPage';
import BoardDetailPage from './pages/BoardDetailPage';
import ReportPage from './pages/ReportPage';
import ReportDetailPage from './pages/ReportDetailPage';

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
        { path: '/inventory/:itemCode/:warehouseCode', element: <InventoryDetailPage /> },
        { path: '/members', element: <MemberPage /> },
        { path: '/members/:memberId', element: <MemberDetailPage /> },
        { path: '/quality-docs', element: <QualityDocPage /> },
        { path: '/quality-docs/:documentId', element: <QualityDocDetailPage /> },
        { path: '/board', element: <BoardPage /> },
        { path: '/board/:postId', element: <BoardDetailPage /> },
        { path: '/reports', element: <ReportPage /> },
        { path: '/reports/:jobId', element: <ReportDetailPage /> },
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

