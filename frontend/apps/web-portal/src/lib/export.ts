export type CsvColumn<T> = {
  header: string;
  render: (row: T) => string | number | boolean | null | undefined;
};

function escapeCsvCell(value: string | number | boolean | null | undefined) {
  if (value === null || value === undefined) {
    return "";
  }

  const text = String(value).replace(/"/g, "\"\"");
  return `"${text}"`;
}

function timestampPart(value: number) {
  return String(value).padStart(2, "0");
}

export function buildExportFileName(prefix: string) {
  const now = new Date();
  const date = [
    now.getFullYear(),
    timestampPart(now.getMonth() + 1),
    timestampPart(now.getDate()),
  ].join("");
  const time = [timestampPart(now.getHours()), timestampPart(now.getMinutes())].join("");
  return `${prefix}-${date}-${time}.csv`;
}

export function downloadCsv<T>(fileName: string, columns: CsvColumn<T>[], rows: T[]) {
  const headerLine = columns.map((column) => escapeCsvCell(column.header)).join(",");
  const rowLines = rows.map((row) =>
    columns.map((column) => escapeCsvCell(column.render(row))).join(",")
  );
  const payload = ["\uFEFF", headerLine, "\r\n", rowLines.join("\r\n")].join("");
  const blob = new Blob([payload], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");

  link.href = url;
  link.download = fileName;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  URL.revokeObjectURL(url);
}
