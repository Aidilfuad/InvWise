import { useState } from 'react'
import {
  Activity,
  ArrowDownToLine,
  ArrowRightLeft,
  CalendarDays,
  ChevronDown,
  Clock3,
  FileText,
  PackageOpen,
  PackageSearch,
} from 'lucide-react'
import { formatLocalDate, formatLocalTime } from './exportUtils'

const reportDefinitions = [
  {
    id: 'valuation',
    title: 'Inventory Valuation',
    description: 'Understand inventory value by item, category, and warehouse.',
    Icon: PackageOpen,
    tone: 'teal',
  },
  {
    id: 'movements',
    title: 'Stock Movement Summary',
    description: 'Track stock received, dispatched, transferred, and adjusted.',
    Icon: ArrowRightLeft,
    tone: 'blue',
  },
  {
    id: 'replenishment',
    title: 'Low-Stock Replenishment',
    description: 'Plan purchasing with minimum levels and reorder quantities.',
    Icon: PackageSearch,
    tone: 'amber',
  },
  {
    id: 'telemetry',
    title: 'Telemetry & Sensor Health',
    description: 'Review device uptime, sensor readings, and threshold breaches.',
    Icon: Activity,
    tone: 'purple',
  },
]

const initialExports = [
  { id: 'sample-export-1', reportId: 'valuation', title: 'Inventory Valuation', format: 'PDF', scope: 'All warehouses · Nov 1–23, 2026', actor: 'Alex Morgan', createdAt: new Date(Date.now() - 8 * 60 * 1000) },
  { id: 'sample-export-2', reportId: 'movements', title: 'Stock Movement Summary', format: 'CSV', scope: 'Main warehouse · Nov 16–22, 2026', actor: 'Priya Shah', createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000 - 20 * 60 * 1000) },
]
const displayedToday = formatLocalDate(new Date())

function currency(value, code) {
  try {
    return new Intl.NumberFormat('en', { style: 'currency', currency: code || 'USD', maximumFractionDigits: 0 }).format(value)
  } catch {
    return `${code || '$'} ${Number(value).toLocaleString()}`
  }
}

function scopeLabel(dateRange, warehouse) {
  const date = dateRange === 'today'
    ? formatLocalDate(new Date())
    : dateRange === '7d'
      ? 'Last 7 days'
      : dateRange === '30d'
        ? 'Last 30 days'
        : 'All dates'
  return `${warehouse === 'all' ? 'All warehouses' : warehouse} · ${date}`
}

function dateMatchesRange(value, range) {
  if (range === 'all') return true
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return false
  if (range === 'today') {
    const now = new Date()
    return date.getFullYear() === now.getFullYear() &&
      date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate()
  }
  const days = range === '7d' ? 7 : 30
  return date.getTime() >= Date.now() - days * 24 * 60 * 60 * 1000
}

export default function ReportsTab({
  alertCount,
  currencyCode,
  globalSearch,
  items,
  movements,
  onGenerate,
  telemetry,
  warehouses,
}) {
  const [dateRange, setDateRange] = useState('30d')
  const [warehouse, setWarehouse] = useState('all')
  const [formats, setFormats] = useState(Object.fromEntries(reportDefinitions.map((report) => [report.id, 'CSV'])))
  const [recentExports, setRecentExports] = useState(initialExports)
  const [error, setError] = useState('')

  const search = globalSearch.trim().toLowerCase()
  const visibleItems = items.filter((item) => {
    const matchesSearch = !search || `${item.name} ${item.sku} ${item.categoryName} ${item.locationName}`.toLowerCase().includes(search)
    const matchesWarehouse = warehouse === 'all' || item.locationName === warehouse || Object.keys(item.levels || {}).some((id) => warehouses.find((row) => row.id === id)?.name === warehouse)
    return matchesSearch && matchesWarehouse
  })
  const visibleMovements = movements.filter((movement) => {
    const matchesSearch = !search || `${movement.event || ''} ${movement.description || ''} ${movement.detail || ''} ${movement.actor || ''}`.toLowerCase().includes(search)
    return matchesSearch &&
      dateMatchesRange(movement.occurredAt || movement.occurred_at, dateRange) &&
      (warehouse === 'all' || movement.warehouse?.includes(warehouse))
  })
  const lowStock = visibleItems.filter((item) => item.quantity > 0 && item.quantity <= item.minimumStock)
  const valuation = visibleItems.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0)
  const reportMetrics = {
    valuation: `${currency(valuation, currencyCode)} total valuation · ${visibleItems.length.toLocaleString()} catalog items`,
    movements: `${visibleMovements.length.toLocaleString()} movements · Complete audit trail`,
    replenishment: `${lowStock.length.toLocaleString()} low-stock items · ${visibleItems.filter((item) => item.quantity <= 0).length} out of stock`,
    telemetry: `${Math.max(telemetry.length, 1) * 24} monitored devices · ${alertCount} active alerts`,
  }

  async function generate(reportId, format, requestedScope = scopeLabel(dateRange, warehouse)) {
    setError('')
    try {
      const scope = typeof requestedScope === 'string'
        ? { dateRange, warehouse, scope: requestedScope }
        : {
          ...requestedScope,
          dateRange: requestedScope.dateRange || dateRange,
          warehouse: requestedScope.warehouse || warehouse,
          scope: typeof requestedScope.scope === 'string' ? requestedScope.scope : scopeLabel(dateRange, warehouse),
        }
      const generated = await onGenerate(reportId, format, scope)
      setRecentExports((current) => [generated, ...current].slice(0, 6))
    } catch (generateError) {
      setError(generateError instanceof Error ? generateError.message : 'Unable to generate this report.')
    }
  }

  function setFormat(reportId, format) {
    setFormats((current) => ({ ...current, [reportId]: format }))
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-[17px] font-bold tracking-[-0.02em] text-slate-900">Reports</h2>
          <p className="mt-0.5 text-[10px] text-slate-500">Turn warehouse data into clear, actionable insights.</p>
        </div>
        <span className="inline-flex items-center gap-1.5 rounded-md border border-slate-200 bg-white px-2.5 py-1.5 text-[9px] text-slate-500">
          <Clock3 size={12} /> Ready to generate
        </span>
      </div>

      <section aria-label="Report scope" className="flex flex-wrap items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2.5">
        <span className="mr-1 text-[10px] font-semibold text-slate-800">Report scope</span>
        <label className="relative">
          <CalendarDays aria-hidden="true" className="pointer-events-none absolute left-2 top-1/2 -translate-y-1/2 text-slate-500" size={13} />
          <select aria-label="Report date range" className="h-8 min-w-[170px] appearance-none rounded-md border border-slate-200 bg-white pl-7 pr-7 text-[9px] text-slate-700 outline-none focus:border-teal-500" onChange={(event) => setDateRange(event.target.value)} value={dateRange}>
            <option value="30d">Nov 1 – {displayedToday.replace(/, \d{4}$/, '')}, 2026</option>
            <option value="today">Today</option>
            <option value="7d">Last 7 days</option>
            <option value="all">All dates</option>
          </select>
          <ChevronDown aria-hidden="true" className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" size={12} />
        </label>
        <label className="relative">
          <select aria-label="Report warehouse" className="h-8 min-w-[135px] appearance-none rounded-md border border-slate-200 bg-white pl-2.5 pr-7 text-[9px] text-slate-700 outline-none focus:border-teal-500" onChange={(event) => setWarehouse(event.target.value)} value={warehouse}>
            <option value="all">All warehouses</option>
            {warehouses.map((row) => <option key={row.id} value={row.name}>{row.name}</option>)}
          </select>
          <ChevronDown aria-hidden="true" className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" size={12} />
        </label>
        <span className="ml-auto hidden text-[8px] text-slate-400 md:inline">Applies to every report below</span>
      </section>

      <section aria-label="Available reports" className="grid gap-3 lg:grid-cols-2">
        {reportDefinitions.map(({ id, title, description, Icon, tone }) => {
          const iconTone = {
            teal: 'bg-teal-50 text-teal-700',
            blue: 'bg-blue-50 text-blue-700',
            amber: 'bg-amber-50 text-amber-700',
            purple: 'bg-violet-50 text-violet-700',
          }[tone]
          return (
            <article className="flex min-h-[142px] flex-col justify-between rounded-lg border border-slate-200 bg-white p-3.5 shadow-[0_1px_2px_rgba(15,23,42,0.02)] sm:p-4" key={id}>
              <div className="flex items-start gap-2.5">
                <span className={`grid h-7 w-7 shrink-0 place-items-center rounded-md ${iconTone}`}><Icon size={15} /></span>
                <div className="min-w-0">
                  <h3 className="text-[11px] font-semibold text-slate-800">{title}</h3>
                  <p className="mt-1 text-[9px] leading-4 text-slate-500">{description}</p>
                  <p className={`mt-2 text-[9px] font-medium ${tone === 'amber' ? 'text-amber-700' : tone === 'purple' ? 'text-violet-700' : 'text-teal-700'}`}>{reportMetrics[id]}</p>
                </div>
              </div>
              <div className="mt-3 flex flex-wrap items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <div aria-label={`${title} format`} className="flex rounded-md bg-slate-100 p-0.5" role="group">
                    {['CSV', 'PDF'].map((format) => (
                      <button aria-pressed={formats[id] === format} className={`rounded px-2.5 py-1 text-[8px] transition ${formats[id] === format ? 'bg-white font-semibold text-slate-700 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`} key={format} onClick={() => setFormat(id, format)} type="button">{format}</button>
                    ))}
                  </div>
                  <span className="hidden text-[8px] text-slate-400 sm:inline">Ready to generate</span>
                </div>
                <button className="inline-flex h-7 items-center gap-1.5 rounded-md bg-teal-600 px-2.5 text-[9px] font-semibold text-white transition hover:bg-teal-700" onClick={() => generate(id, formats[id])} type="button">
                  <ArrowDownToLine size={12} /> Generate report
                </button>
              </div>
            </article>
          )
        })}
      </section>

      {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}

      <section aria-label="Recent exports" className="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
        <header className="flex items-center justify-between border-b border-slate-100 px-3.5 py-2.5">
          <h3 className="text-[10px] font-semibold text-slate-800">Recent exports</h3>
          <span className="text-[8px] font-medium text-teal-700">Export history <span aria-hidden="true">→</span></span>
        </header>
        <div className="divide-y divide-slate-100">
          {recentExports.map((entry) => (
            <div className="flex flex-wrap items-center gap-x-3 gap-y-2 px-3.5 py-2" key={entry.id}>
              <FileText className="shrink-0 text-slate-400" size={13} />
              <div className="min-w-[155px] flex-1">
                <p className="text-[9px] font-medium text-slate-800">{entry.title}</p>
                <p className="mt-0.5 text-[8px] text-slate-400">{entry.scope || scopeLabel(dateRange, warehouse)}</p>
              </div>
              <p className="w-[110px] text-[8px] text-slate-500">{entry.actor || 'You'}</p>
              <p className="w-[95px] text-right text-[8px] text-slate-500">{formatLocalDate(entry.createdAt)} · {formatLocalTime(entry.createdAt)}</p>
              <span className="rounded bg-emerald-50 px-1.5 py-1 text-[8px] font-medium text-emerald-700">Ready</span>
              <button className="inline-flex h-7 items-center gap-1 rounded-md border border-slate-200 px-2 text-[8px] font-medium text-teal-700 hover:bg-teal-50" onClick={() => generate(entry.reportId, entry.format, entry.scope)} type="button">
                <ArrowDownToLine size={11} /> Download
              </button>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}
