import { useMemo, useState } from 'react'
import {
  AlertTriangle,
  BatteryLow,
  Check,
  CheckCircle2,
  ChevronDown,
  CircleAlert,
  Info,
  Search,
  Settings2,
  ShieldAlert,
  WifiOff,
} from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'
import HubSummaryCards from './HubSummaryCards'
import { relativeTime } from './exportUtils'

const filters = [
  { id: 'active', label: 'All active' },
  { id: 'critical', label: 'Critical' },
  { id: 'warning', label: 'Warning' },
  { id: 'info', label: 'Info' },
  { id: 'acknowledged', label: 'Acknowledged' },
]

function alertIcon(alert) {
  const text = `${alert.title} ${alert.detail}`.toLowerCase()
  if (text.includes('offline') || text.includes('gateway')) return WifiOff
  if (text.includes('battery')) return BatteryLow
  if (alert.type === 'Inventory') return AlertTriangle
  return alert.severity === 'critical' ? ShieldAlert : CircleAlert
}

function severityStyle(severity) {
  const normalized = severity.toLowerCase()
  if (normalized === 'critical') return { label: 'Critical', icon: 'bg-rose-50 text-rose-600', badge: 'bg-rose-50 text-rose-700' }
  if (normalized === 'warning') return { label: 'Warning', icon: 'bg-amber-50 text-amber-700', badge: 'bg-amber-50 text-amber-800' }
  return { label: 'Info', icon: 'bg-blue-50 text-blue-700', badge: 'bg-blue-50 text-blue-700' }
}

export default function AlertsTab({
  alerts,
  canManage = false,
  globalSearch,
  onAcknowledge,
  onManageRules,
  onResolve,
  onViewInventory,
  source,
  warehouses,
}) {
  const [search, setSearch] = useState('')
  const [warehouse, setWarehouse] = useState('all')
  const [type, setType] = useState('all')
  const [statusFilter, setStatusFilter] = useState('active')
  const [page, setPage] = useState(0)
  const pageSize = 6

  const activeAlerts = alerts.filter((alert) => alert.status === 'active')
  const summary = {
    critical: activeAlerts.filter((alert) => alert.severity === 'critical').length,
    warning: activeAlerts.filter((alert) => alert.severity === 'warning').length,
    info: activeAlerts.filter((alert) => alert.severity === 'info').length,
    resolved: alerts.filter((alert) => alert.status === 'resolved' && alert.resolvedAt && new Date(alert.resolvedAt).toDateString() === new Date().toDateString()).length,
  }
  const visible = useMemo(() => {
    const needle = `${globalSearch} ${search}`.trim().toLowerCase()
    return alerts.filter((alert) => {
      const byStatus = statusFilter === 'acknowledged'
        ? alert.status === 'acknowledged'
        : statusFilter === 'active'
          ? alert.status === 'active'
          : alert.status === 'active' && alert.severity === statusFilter
      const byWarehouse = warehouse === 'all' || alert.warehouse === warehouse
      const byType = type === 'all' || alert.type === type
      const haystack = `${alert.title} ${alert.detail} ${alert.warehouse} ${alert.location} ${alert.type}`.toLowerCase()
      return byStatus && byWarehouse && byType && (!needle || haystack.includes(needle))
    }).sort((left, right) => new Date(right.detectedAt).getTime() - new Date(left.detectedAt).getTime())
  }, [alerts, globalSearch, search, statusFilter, type, warehouse])
  const visibleRows = visible.slice(page * pageSize, page * pageSize + pageSize)
  const pageCount = Math.max(1, Math.ceil(visible.length / pageSize))
  const filterCounts = {
    active: activeAlerts.length,
    critical: summary.critical,
    warning: summary.warning,
    info: summary.info,
    acknowledged: alerts.filter((alert) => alert.status === 'acknowledged').length,
  }
  const warehouseOptions = [...new Set([...warehouses.map((row) => row.name), ...alerts.map((row) => row.warehouse)])]
    .filter((name) => name && name !== 'All warehouses')

  function changeFilter(value) {
    setStatusFilter(value)
    setPage(0)
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <h2 className="text-[17px] font-bold tracking-[-0.02em] text-slate-900">Alerts</h2>
          <p className="mt-0.5 text-[10px] text-slate-500">Prioritize stock risks and keep every connected device healthy.</p>
        </div>
        {canManage && <button className="inline-flex h-8 items-center gap-2 rounded-md border border-slate-200 bg-white px-3 text-[10px] font-medium text-slate-600 transition hover:border-teal-200 hover:text-teal-700" onClick={onManageRules} type="button">
          <Settings2 size={13} /> Manage rules
        </button>}
      </div>

      <HubSummaryCards cards={[
        { label: 'Critical', value: summary.critical, note: 'Requires immediate action', Icon: ShieldAlert, tone: 'red' },
        { label: 'Warning', value: summary.warning, note: 'Review and take action', Icon: AlertTriangle, tone: 'amber' },
        { label: 'Info', value: summary.info, note: 'Keep your team informed', Icon: Info, tone: 'blue' },
        { label: 'Resolved today', value: source === 'sample' ? 28 : summary.resolved, note: 'Median response: 8 min', Icon: CheckCircle2, tone: 'green' },
      ]} />

      <section aria-label="Alert filters and results" className="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
        <div className="flex flex-wrap items-center justify-between gap-2.5 border-b border-slate-100 px-3 py-2.5 sm:px-3.5">
          <label className="relative min-w-[220px] flex-1 sm:max-w-[350px]">
            <Search aria-hidden="true" className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
            <input aria-label="Search alerts" className="h-8 w-full rounded-md border border-slate-200 pl-8 pr-3 text-[10px] outline-none placeholder:text-slate-400 focus:border-teal-500" onChange={(event) => { setSearch(event.target.value); setPage(0) }} placeholder="Search alerts, items, or devices..." value={search} />
          </label>
          <div className="flex flex-wrap items-center gap-2">
            <div className="min-w-[130px]">
              <SearchableSelect
                aria-label="Filter alerts by warehouse"
                className="h-8 text-[10px] text-slate-700"
                onChange={(value) => { setWarehouse(value); setPage(0) }}
                options={[
                  { value: 'all', label: 'All warehouses' },
                  ...warehouseOptions.map((name) => ({ value: name, label: name })),
                ]}
                value={warehouse}
              />
            </div>
            <div className="min-w-[120px]">
              <SearchableSelect
                aria-label="Filter alerts by type"
                className="h-8 text-[10px] text-slate-700"
                onChange={(value) => { setType(value); setPage(0) }}
                options={[
                  { value: 'all', label: 'Stock & devices' },
                  { value: 'Inventory', label: 'Inventory' },
                  { value: 'Telemetry', label: 'Telemetry' },
                ]}
                value={type}
              />
            </div>
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-100 px-3 py-2 sm:px-3.5">
          <div aria-label="Filter alert status or severity" className="flex gap-1 overflow-x-auto" role="group">
            {filters.map((filter) => (
              <button aria-pressed={statusFilter === filter.id} className={`inline-flex shrink-0 items-center gap-1 rounded-md px-2 py-1 text-[9px] transition ${statusFilter === filter.id ? 'border border-teal-200 bg-teal-50 font-semibold text-teal-700' : 'text-slate-500 hover:bg-slate-50'}`} key={filter.id} onClick={() => changeFilter(filter.id)} type="button">
                {filter.label}<span className={statusFilter === filter.id ? 'text-teal-600' : 'text-slate-400'}>{filterCounts[filter.id]}</span>
              </button>
            ))}
          </div>
          <span className="text-[8px] text-slate-400">Newest first</span>
        </div>

        <div className="divide-y divide-slate-100">
          {visibleRows.length === 0 ? (
            <p className="px-4 py-10 text-center text-[11px] text-slate-400">No alerts match these filters.</p>
          ) : visibleRows.map((alert) => {
            const Icon = alertIcon(alert)
            const tone = severityStyle(alert.severity)
            const canUpdate = alert.sourceTable !== 'inventory_alerts'
            return (
              <article className="flex flex-wrap items-center gap-x-3 gap-y-2 px-3 py-2.5 sm:px-3.5" key={alert.id}>
                <span className={`grid h-6 w-6 shrink-0 place-items-center rounded-md ${tone.icon}`}><Icon size={13} /></span>
                <div className="min-w-[220px] flex-1">
                  <div className="flex flex-wrap items-center gap-1.5">
                    <span className={`rounded px-1.5 py-0.5 text-[8px] font-semibold ${tone.badge}`}>{tone.label}</span>
                    <h3 className="text-[10px] font-semibold text-slate-800">{alert.title}</h3>
                    {alert.status === 'acknowledged' && <span className="inline-flex items-center gap-1 text-[8px] font-medium text-teal-700"><Check size={10} /> Acknowledged</span>}
                  </div>
                  <p className="mt-1 text-[9px] text-slate-500">{alert.detail}</p>
                </div>
                <div className="w-[150px]">
                  <p className="text-[9px] font-medium text-slate-700">{alert.warehouse}</p>
                  <p className="mt-0.5 text-[8px] text-slate-400">{alert.location || alert.type}</p>
                </div>
                <p className="w-[55px] text-[8px] text-slate-400">{relativeTime(alert.detectedAt)}</p>
                <div className="ml-auto flex items-center gap-1.5">
                  {canUpdate && canManage ? (
                    <>
                      {alert.status === 'active' && (
                        <button className="h-7 rounded-md border border-slate-200 px-2.5 text-[9px] font-medium text-teal-700 hover:border-teal-300 hover:bg-teal-50" onClick={() => onAcknowledge(alert)} type="button">Acknowledge</button>
                      )}
                      {alert.status !== 'resolved' && (
                        <button className="h-7 rounded-md bg-teal-600 px-2.5 text-[9px] font-semibold text-white hover:bg-teal-700" onClick={() => onResolve(alert)} type="button">Resolve</button>
                      )}
                    </>
                  ) : alert.sourceTable === 'inventory_alerts' ? (
                    <button className="h-7 rounded-md border border-slate-200 px-2.5 text-[9px] font-medium text-teal-700 hover:border-teal-300 hover:bg-teal-50" onClick={onViewInventory} type="button">View stock</button>
                  ) : null}
                </div>
              </article>
            )
          })}
        </div>

        <footer className="flex items-center justify-between border-t border-slate-100 px-3.5 py-2.5 text-[9px] text-slate-400">
          <span>Showing {visible.length ? page * pageSize + 1 : 0}–{Math.min((page + 1) * pageSize, visible.length)} of {visible.length} active alerts</span>
          <div className="flex items-center gap-2">
            <button aria-label="Previous alerts page" className="rounded p-1 hover:bg-slate-100 disabled:opacity-30" disabled={page === 0} onClick={() => setPage((value) => Math.max(0, value - 1))} type="button"><ChevronDown className="rotate-90" size={12} /></button>
            <span className="rounded bg-teal-50 px-2 py-1 font-semibold text-teal-700">{page + 1}</span>
            <button aria-label="Next alerts page" className="rounded p-1 hover:bg-slate-100 disabled:opacity-30" disabled={page + 1 >= pageCount} onClick={() => setPage((value) => Math.min(pageCount - 1, value + 1))} type="button"><ChevronDown className="-rotate-90" size={12} /></button>
          </div>
        </footer>
      </section>
    </div>
  )
}
