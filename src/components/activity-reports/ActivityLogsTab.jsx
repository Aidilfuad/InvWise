import { useMemo, useState } from 'react'
import {
  Activity,
  ArrowLeft,
  ArrowRight,
  ArrowRightLeft,
  Boxes,
  CheckCircle2,
  ClipboardList,
  Search,
  ShieldCheck,
  UserRound,
} from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'
import HubSummaryCards from './HubSummaryCards'
import { formatLocalDate, formatLocalTime, relativeTime } from './exportUtils'

const categories = ['All', 'Inventory', 'Stock Movements', 'Telemetry', 'User/System']
const displayedToday = formatLocalDate(new Date())

function isWithinRange(date, range) {
  const timestamp = date.getTime()
  if (range === 'all') return true
  const now = new Date()
  if (range === 'today') {
    return date.getFullYear() === now.getFullYear() &&
      date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate()
  }
  const days = range === '7d' ? 7 : 30
  return timestamp >= Date.now() - days * 24 * 60 * 60 * 1000
}

function categoryIcon(category) {
  if (category === 'Stock Movements') return ArrowRightLeft
  if (category === 'Telemetry') return Activity
  if (category === 'User/System') return UserRound
  return Boxes
}

function categoryTone(category) {
  if (category === 'Stock Movements') return 'bg-emerald-50 text-emerald-700'
  if (category === 'Telemetry') return 'bg-orange-50 text-orange-700'
  if (category === 'User/System') return 'bg-slate-100 text-slate-600'
  return 'bg-blue-50 text-blue-700'
}

function eventTone(label) {
  const normalized = label.toLowerCase()
  if (normalized.includes('out')) return 'bg-violet-50 text-violet-700'
  if (normalized.includes('sensor')) return 'bg-orange-50 text-orange-700'
  if (normalized.includes('transfer') || normalized.includes('in')) return 'bg-emerald-50 text-emerald-700'
  if (normalized.includes('update')) return 'bg-blue-50 text-blue-700'
  return 'bg-slate-100 text-slate-600'
}

export default function ActivityLogsTab({ activities, alertCount, globalSearch, warehouses, source }) {
  const [search, setSearch] = useState('')
  const [dateRange, setDateRange] = useState('today')
  const [warehouse, setWarehouse] = useState('all')
  const [category, setCategory] = useState('All')
  const [page, setPage] = useState(0)
  const pageSize = 6

  const rangeLabel = dateRange === 'today'
    ? `Today, ${displayedToday.replace(/, \d{4}$/, '')}`
    : dateRange === '7d' ? 'Last 7 days' : dateRange === '30d' ? 'Last 30 days' : 'All dates'

  const inRangeAndWarehouse = useMemo(() => activities.filter((row) => {
    const date = row.occurredAt instanceof Date ? row.occurredAt : new Date(row.occurredAt)
    return isWithinRange(date, dateRange) && (warehouse === 'all' || row.warehouse === warehouse)
  }), [activities, dateRange, warehouse])

  const filtered = useMemo(() => {
    const needle = `${globalSearch} ${search}`.trim().toLowerCase()
    return inRangeAndWarehouse.filter((row) => {
      const matchesCategory = category === 'All' || row.category === category
      const haystack = `${row.event} ${row.description} ${row.detail} ${row.actor} ${row.reference} ${row.warehouse}`.toLowerCase()
      return matchesCategory && (!needle || haystack.includes(needle))
    })
  }, [category, globalSearch, inRangeAndWarehouse, search])

  const counts = useMemo(() => Object.fromEntries([
    ['All', inRangeAndWarehouse.length],
    ...categories.slice(1).map((name) => [name, inRangeAndWarehouse.filter((row) => row.category === name).length]),
  ]), [inRangeAndWarehouse])
  const todayCount = activities.filter((row) => isWithinRange(row.occurredAt, 'today')).length
  const stockCount = activities.filter((row) => row.category === 'Stock Movements' && isWithinRange(row.occurredAt, 'today')).length
  const teamActors = new Set(activities.filter((row) => row.category === 'User/System').map((row) => row.actor))
  const visibleRows = filtered.slice(page * pageSize, page * pageSize + pageSize)
  const pageCount = Math.max(1, Math.ceil(filtered.length / pageSize))

  function setFilter(update, value) {
    update(value)
    setPage(0)
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-end justify-between gap-2">
        <div>
          <h2 className="text-[17px] font-bold tracking-[-0.02em] text-slate-900">Activity logs</h2>
          <p className="mt-0.5 text-[10px] text-slate-500">A traceable history of every movement, update, and decision.</p>
        </div>
        <div className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-[9px] font-medium text-emerald-700">
          <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-500" />
          {source === 'live' ? 'Live updates on' : 'Sample activity'}
        </div>
      </div>

      <HubSummaryCards cards={[
        { label: 'Events today', value: todayCount.toLocaleString(), note: '+12% vs. yesterday', Icon: ClipboardList, tone: 'teal' },
        { label: 'Stock movements', value: stockCount.toLocaleString(), note: `${new Set(activities.filter((row) => row.category === 'Stock Movements').map((row) => row.warehouse)).size} warehouses`, Icon: ArrowRightLeft, tone: 'blue' },
        { label: 'Active alerts', value: alertCount.toLocaleString(), note: 'Across inventory & telemetry', Icon: Activity, tone: 'amber' },
        { label: 'Team actions', value: activities.filter((row) => row.category === 'User/System').length.toLocaleString(), note: `${teamActors.size} active team members`, Icon: ShieldCheck, tone: 'green' },
      ]} />

      <section aria-label="Activity log filters and events" className="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
        <div className="flex flex-wrap items-center justify-between gap-2.5 border-b border-slate-100 px-3 py-2.5 sm:px-3.5">
          <label className="relative min-w-[220px] flex-1 sm:max-w-[350px]">
            <Search aria-hidden="true" className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
            <input
              aria-label="Search activity by item, actor, or reference"
              className="h-8 w-full rounded-md border border-slate-200 bg-white pl-8 pr-3 text-[10px] outline-none placeholder:text-slate-400 focus:border-teal-500"
              onChange={(event) => setFilter(setSearch, event.target.value)}
              placeholder="Search by item, actor, or reference..."
              value={search}
            />
          </label>
          <div className="flex flex-wrap items-center gap-2">
            {globalSearch.trim() && <span className="hidden text-[9px] text-slate-400 sm:inline">Global: “{globalSearch}”</span>}
            <div className="w-[140px]">
              <SearchableSelect
                aria-label="Activity date range"
                className="h-8 text-[10px] text-slate-700"
                onChange={(value) => setFilter(setDateRange, value)}
                options={[
                  { value: 'today', label: rangeLabel },
                  { value: '7d', label: 'Last 7 days' },
                  { value: '30d', label: 'Last 30 days' },
                  { value: 'all', label: 'All dates' },
                ]}
                value={dateRange}
              />
            </div>
            <div className="min-w-[130px]">
              <SearchableSelect
                aria-label="Filter by warehouse"
                className="h-8 text-[10px] text-slate-700"
                onChange={(value) => setFilter(setWarehouse, value)}
                options={[
                  { value: 'all', label: 'All warehouses' },
                  ...warehouses.map((row) => ({ value: row.name, label: row.name })),
                ]}
                value={warehouse}
              />
            </div>
          </div>
        </div>

        <div aria-label="Filter by event category" className="flex gap-1 overflow-x-auto px-3 py-2 sm:px-3.5" role="group">
          {categories.map((name) => (
            <button
              aria-pressed={category === name}
              className={`inline-flex shrink-0 items-center gap-1.5 rounded-md px-2 py-1 text-[9px] transition ${
                category === name ? 'border border-teal-200 bg-teal-50 font-semibold text-teal-700' : 'text-slate-500 hover:bg-slate-50'
              }`}
              key={name}
              onClick={() => setFilter(setCategory, name)}
              type="button"
            >
              {name}
              <span className={category === name ? 'text-teal-600' : 'text-slate-400'}>{counts[name]?.toLocaleString() ?? 0}</span>
            </button>
          ))}
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-[700px] border-collapse text-left">
            <thead>
              <tr className="bg-slate-50 text-[9px] font-medium text-slate-500">
                <th className="px-3.5 py-2 font-medium">Event / reference</th>
                <th className="px-3 py-2 font-medium">Actor</th>
                <th className="px-3 py-2 font-medium">Warehouse / location</th>
                <th className="px-3.5 py-2 text-right font-medium">Time</th>
              </tr>
            </thead>
            <tbody>
              {visibleRows.length === 0 ? (
                <tr><td className="px-4 py-10 text-center text-[11px] text-slate-400" colSpan={4}>No events match these filters.</td></tr>
              ) : visibleRows.map((row) => {
                const Icon = categoryIcon(row.category)
                return (
                  <tr className="border-t border-slate-100 align-middle" key={row.id}>
                    <td className="max-w-[360px] px-3.5 py-2.5">
                      <div className="flex min-w-0 items-start gap-2">
                        <span className={`mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-md ${categoryTone(row.category)}`}>
                          <Icon size={13} />
                        </span>
                        <div className="min-w-0">
                          <div className="flex flex-wrap items-center gap-1.5">
                            <p className="truncate text-[10px] font-semibold text-slate-800">{row.event}</p>
                            {row.value && <span className="text-[9px] font-medium text-emerald-700">{row.value}</span>}
                            <span className={`rounded px-1.5 py-0.5 text-[8px] font-medium ${eventTone(row.badge || row.category)}`}>{row.badge || row.category}</span>
                          </div>
                          <p className="mt-1 truncate text-[9px] text-slate-500">{row.description} {row.detail && `· ${row.detail}`}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-3 py-2.5">
                      <p className="text-[10px] font-medium text-slate-700">{row.actor}</p>
                      <p className="mt-0.5 text-[8px] text-slate-400">{row.role}</p>
                    </td>
                    <td className="px-3 py-2.5">
                      <p className="text-[10px] font-medium text-slate-700">{row.warehouse}</p>
                      <p className="mt-0.5 text-[8px] text-slate-400">{row.location || '—'}</p>
                    </td>
                    <td className="whitespace-nowrap px-3.5 py-2.5 text-right">
                      <p className="text-[9px] font-medium text-slate-700">{formatLocalTime(row.occurredAt)}</p>
                      <p className="mt-0.5 text-[8px] text-slate-400">{relativeTime(row.occurredAt)}</p>
                    </td>
                  </tr>
                )
              })}
            </tbody>
          </table>
        </div>

        <footer className="flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 px-3.5 py-2.5 text-[9px] text-slate-400">
          <span className="inline-flex items-center gap-1.5"><CheckCircle2 className="text-teal-600" size={12} /> Audit-ready · Retained for 365 days</span>
          <div className="flex items-center gap-2">
            <span>Showing {filtered.length ? page * pageSize + 1 : 0}–{Math.min((page + 1) * pageSize, filtered.length)} of {filtered.length.toLocaleString()} events</span>
            <button aria-label="Previous page" className="rounded p-1 text-slate-500 hover:bg-slate-100 disabled:opacity-30" disabled={page === 0} onClick={() => setPage((value) => Math.max(0, value - 1))} type="button"><ArrowLeft size={12} /></button>
            <span className="rounded bg-teal-50 px-2 py-1 font-semibold text-teal-700">{page + 1}</span>
            <button aria-label="Next page" className="rounded p-1 text-slate-500 hover:bg-slate-100 disabled:opacity-30" disabled={page + 1 >= pageCount} onClick={() => setPage((value) => Math.min(pageCount - 1, value + 1))} type="button"><ArrowRight size={12} /></button>
          </div>
        </footer>
      </section>
    </div>
  )
}
