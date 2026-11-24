function csvCell(value) {
  const text = value == null ? '' : String(value)
  return `"${text.replaceAll('"', '""')}"`
}

export function downloadCsv(filename, headers, rows) {
  const content = [
    headers.map(csvCell).join(','),
    ...rows.map((row) => row.map(csvCell).join(',')),
  ].join('\r\n')
  const blob = new Blob([`\uFEFF${content}`], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.append(link)
  link.click()
  link.remove()
  window.setTimeout(() => URL.revokeObjectURL(url), 1000)
}

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;')
}

export function printReport(title, subtitle, headers, rows) {
  const printWindow = window.open('', '_blank')
  if (!printWindow) throw new Error('Allow pop-ups to open the printable report.')
  printWindow.opener = null
  const tableRows = rows.map((row) => (
    `<tr>${row.map((cell) => `<td>${escapeHtml(cell)}</td>`).join('')}</tr>`
  )).join('')
  printWindow.document.write(`<!doctype html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>${escapeHtml(title)} | InvWise</title>
        <style>
          body{font:14px/1.5 Arial,sans-serif;color:#0f172a;margin:40px}
          h1{font-size:24px;margin:0 0 6px}
          p{color:#64748b;margin:0 0 24px}
          table{width:100%;border-collapse:collapse}
          th,td{border:1px solid #e2e8f0;padding:9px 10px;text-align:left}
          th{background:#f1f5f9;font-size:12px}
          @media print{body{margin:16mm}}
        </style>
      </head>
      <body>
        <h1>${escapeHtml(title)}</h1>
        <p>${escapeHtml(subtitle)}</p>
        <table>
          <thead><tr>${headers.map((header) => `<th>${escapeHtml(header)}</th>`).join('')}</tr></thead>
          <tbody>${tableRows}</tbody>
        </table>
        <script>window.addEventListener('load',()=>window.print())</script>
      </body>
    </html>`)
  printWindow.document.close()
}

export function formatLocalDate(value) {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat('en-US', { month: 'short', day: 'numeric', year: 'numeric' }).format(date)
}

export function formatLocalTime(value) {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat('en-US', { hour: 'numeric', minute: '2-digit', second: '2-digit' }).format(date)
}

export function relativeTime(value) {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  const minutes = Math.max(0, Math.floor((Date.now() - date.getTime()) / 60000))
  if (minutes < 1) return 'Just now'
  if (minutes < 60) return `${minutes} min ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours} hr ago`
  return `${Math.floor(hours / 24)} day${hours >= 48 ? 's' : ''} ago`
}

export function formatTimezone() {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone || 'Local time'
  const offset = -new Date().getTimezoneOffset()
  const sign = offset >= 0 ? '+' : '−'
  const hours = String(Math.floor(Math.abs(offset) / 60)).padStart(2, '0')
  const minutes = String(Math.abs(offset) % 60).padStart(2, '0')
  return `${timezone} · UTC${sign}${hours}:${minutes}`
}
