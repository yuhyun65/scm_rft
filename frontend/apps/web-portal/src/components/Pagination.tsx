interface Props {
  page: number;
  totalPages: number;
  onChange: (page: number) => void;
}

export default function Pagination({ page, totalPages, onChange }: Props) {
  if (totalPages <= 1) return null;

  const pages = Array.from({ length: Math.min(totalPages, 5) }, (_, index) => index);

  return (
    <div className="pagination">
      <div className="pg-btn" onClick={() => onChange(Math.max(0, page - 1))}>
        이전
      </div>
      {pages.map((target) => (
        <div
          key={target}
          className={`pg-btn${target === page ? ' active' : ''}`}
          onClick={() => onChange(target)}
        >
          {target + 1}
        </div>
      ))}
      {totalPages > 5 && <div className="pg-btn">...</div>}
      <div className="pg-btn" onClick={() => onChange(Math.min(totalPages - 1, page + 1))}>
        다음
      </div>
    </div>
  );
}
