interface Props {
  page: number;
  totalPages: number;
  onChange: (p: number) => void;
}

export default function Pagination({ page, totalPages, onChange }: Props) {
  if (totalPages <= 1) return null;
  const pages = Array.from({ length: Math.min(totalPages, 5) }, (_, i) => i);
  return (
    <div className="pagination">
      <div className="pg-btn" onClick={() => onChange(Math.max(0, page - 1))}>‹</div>
      {pages.map(p => (
        <div key={p} className={`pg-btn${p === page ? ' active' : ''}`} onClick={() => onChange(p)}>
          {p + 1}
        </div>
      ))}
      {totalPages > 5 && <div className="pg-btn">…</div>}
      <div className="pg-btn" onClick={() => onChange(Math.min(totalPages - 1, page + 1))}>›</div>
    </div>
  );
}
