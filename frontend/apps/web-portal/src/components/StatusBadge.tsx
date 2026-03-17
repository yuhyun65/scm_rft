import clsx from 'clsx';

const STATUS_MAP: Record<string, string> = {
  PENDING:     'pending',
  CONFIRMED:   'confirmed',
  IN_PROGRESS: 'inprogress',
  COMPLETED:   'completed',
  CANCELED:    'canceled',
  ACTIVE:      'active',
  INACTIVE:    'inactive',
  EXPIRED:     'expired',
  ARCHIVED:    'archived',
  NOTICE:      'notice',
  GENERAL:     'general',
  QUALITY:     'quality',
};

const STATUS_LABEL: Record<string, string> = {
  PENDING:     '대기',
  CONFIRMED:   '확정',
  IN_PROGRESS: '진행중',
  COMPLETED:   '완료',
  CANCELED:    '취소',
  ACTIVE:      '활성',
  INACTIVE:    '비활성',
  EXPIRED:     '만료',
  ARCHIVED:    '보관',
  NOTICE:      '공지',
  GENERAL:     '일반',
  QUALITY:     '품질',
};

interface Props { status: string; }

export default function StatusBadge({ status }: Props) {
  const cls = STATUS_MAP[status] ?? 'general';
  const label = STATUS_LABEL[status] ?? status;
  return <span className={clsx('badge-status', cls)}>{label}</span>;
}
