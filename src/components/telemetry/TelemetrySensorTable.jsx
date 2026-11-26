import {
  Activity,
  ChevronLeft,
  ChevronRight,
  Droplets,
  Search,
  Thermometer,
  Zap,
} from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'

const metricIcons = {
  temperature: Thermometer,
  humidity: Droplets,
  power: Zap,
  voltage: Activity,
  reading: Activity,
}

function relativeTime(value) {
  if (!value) return 'Unavailable'
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return 'Unavailable'
  const seconds = Math.max(0, Math.floor((Date.now() - date.getTime()) / 1000))
  if (seconds < 60) return `${seconds} seconds ago`
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes} minutes ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours} hours ago`
  return `${Math.floor(hours / 24)} days ago`
}

function formatReading(sensor) {
  if (sensor.reading == null) return '—'
  const digits = sensor.metric === 'humidity' ? 1 : sensor.metric === 'voltage' ? 1 : 1
  return `${Number(sensor.reading).toFixed(digits)}${sensor.unit ? ` ${sensor.unit}` : ''}`
}

const statusClass = {
  optimal: 'bg-teal-50 text-teal-700',
  warning: 'bg-amber-50 text-amber-700',
  offline: 'bg-slate-100 text-slate-600',
}

export default function TelemetrySensorTable({
  canManage = false,
  onInspect,
  onPageChange,
  onSearchChange,
  onStatusChange,
  onToggleMonitor,
  onWarehouseChange,
  page,
  pageCount,
  pageSize,
  search,
  sensors,
  status,
  statusCounts,
  totalItems,
  warehouse,
  warehouses,
}) {
  const firstItem = totalItems ? (page - 1) * pageSize + 1 : 0
  const lastItem = Math.min(page * pageSize, totalItems)

  return (
    <section aria-label="Live sensors" className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
      <header className="flex flex-wrap items-start justify-between gap-3 px-4 pb-3 pt-4 sm:px-5">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-sm font-bold text-slate-900">Live sensors</h2>
            <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[9px] font-semibold text-slate-600">{totalItems.toLocaleString()}</span>
          </div>
          <p className="mt-1 text-[9px] text-slate-500">Monitor readings, connectivity, and threshold alerts in one place.</p>
        </div>
        <span className="inline-flex items-center gap-1.5 text-[9px] text-slate-500">
          <span className="h-1.5 w-1.5 rounded-full bg-teal-500" />
          Auto-refresh on
        </span>
      </header>

      <div className="flex flex-wrap items-center gap-2 border-b border-slate-100 px-4 pb-3 sm:px-5">
        <label className="relative min-w-[200px] flex-1 sm:max-w-[300px]">
          <Search aria-hidden="true" className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={13} />
          <input
            aria-label="Search sensors by name or ID"
            className="h-8 w-full rounded-md border border-slate-200 bg-white pl-8 pr-3 text-[9px] outline-none placeholder:text-slate-400 focus:border-teal-500"
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="Search by sensor name or ID"
            value={search}
          />
        </label>
        <SearchableSelect
          aria-label="Filter sensors by warehouse"
          className="h-8 min-w-[125px] text-[9px] text-slate-700"
          onChange={onWarehouseChange}
          options={[
            { value: 'all', label: 'All warehouses' },
            ...warehouses.map((name) => ({ value: name, label: name })),
          ]}
          value={warehouse}
        />
        <SearchableSelect
          aria-label="Filter sensors by status"
          className="h-8 min-w-[115px] text-[9px] text-slate-700"
          onChange={onStatusChange}
          options={[
            { value: 'all', label: 'All statuses' },
            { value: 'optimal', label: 'Optimal' },
            { value: 'warning', label: 'Warning' },
            { value: 'offline', label: 'Offline' },
          ]}
          value={status}
        />
        <div aria-label="Sensor status counts" className="ml-auto flex flex-wrap items-center gap-x-3 gap-y-1 text-[8px]">
          <span className="text-teal-700">{statusCounts.optimal} optimal</span>
          <span className="text-amber-700">{statusCounts.warning} warnings</span>
          <span className="text-slate-500">{statusCounts.offline} offline</span>
        </div>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[830px] border-collapse text-left">
          <thead>
            <tr className="bg-slate-50 text-[8px] font-medium text-slate-500">
              <th className="px-4 py-2 font-medium">Sensor</th>
              <th className="px-3 py-2 font-medium">Warehouse / Zone</th>
              <th className="px-3 py-2 font-medium">Live reading</th>
              <th className="px-3 py-2 font-medium">Threshold status</th>
              <th className="px-3 py-2 font-medium">Last heartbeat</th>
                {canManage && <th className="px-3 py-2 text-center font-medium">Monitor</th>}
              <th className="px-3 py-2"><span className="sr-only">Inspect sensor</span></th>
            </tr>
          </thead>
          <tbody>
            {sensors.length === 0 ? (
              <tr><td className="px-4 py-10 text-center text-[10px] text-slate-400" colSpan={canManage ? 7 : 6}>No sensors match these filters.</td></tr>
            ) : sensors.map((sensor) => {
              const Icon = metricIcons[sensor.metric] ?? Activity
              return (
                <tr className={`border-t border-slate-100 transition-colors hover:bg-slate-50/80 ${sensor.status === 'warning' ? 'bg-amber-50/25' : ''}`} key={sensor.id}>
                  <td className="px-4 py-2">
                    <div className="flex items-center gap-2">
                      <span className={`grid h-6 w-6 shrink-0 place-items-center rounded-md ${sensor.status === 'offline' ? 'bg-slate-100 text-slate-500' : sensor.status === 'warning' ? 'bg-amber-50 text-amber-700' : 'bg-teal-50 text-teal-700'}`}>
                        <Icon size={13} />
                      </span>
                      <span className="min-w-0">
                        <span className="block truncate text-[9px] font-semibold text-slate-800">{sensor.name}</span>
                        <span className="mt-0.5 block text-[8px] text-slate-400">{sensor.code}</span>
                      </span>
                    </div>
                  </td>
                  <td className="px-3 py-2">
                    <span className="block truncate text-[9px] font-medium text-slate-700">{sensor.warehouse}</span>
                    <span className="mt-0.5 block truncate text-[8px] text-slate-400">{sensor.zone}</span>
                  </td>
                  <td className="px-3 py-2">
                    <span className={`block text-[9px] font-bold ${sensor.status === 'warning' ? 'text-amber-700' : 'text-slate-800'}`}>{formatReading(sensor)}</span>
                    <span className="mt-0.5 block text-[8px] text-slate-400">{sensor.threshold}</span>
                  </td>
                  <td className="px-3 py-2">
                    <span className={`inline-flex items-center gap-1 rounded px-1.5 py-1 text-[8px] font-semibold ${statusClass[sensor.status]}`}>
                      <span className={`h-1 w-1 rounded-full ${sensor.status === 'optimal' ? 'bg-teal-600' : sensor.status === 'warning' ? 'bg-amber-500' : 'bg-slate-500'}`} />
                      {sensor.status[0].toUpperCase()}{sensor.status.slice(1)}
                    </span>
                  </td>
                  <td className="whitespace-nowrap px-3 py-2 text-[8px] text-slate-500">{relativeTime(sensor.lastSeen)}</td>
                  {canManage && <td className="px-3 py-2 text-center">
                    <button
                      aria-checked={sensor.monitored}
                      aria-label={`Monitor ${sensor.name}`}
                      className={`relative inline-flex h-[18px] w-9 items-center rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-2 ${sensor.monitored ? 'bg-teal-600' : 'bg-slate-300'}`}
                      onClick={() => onToggleMonitor(sensor)}
                      role="switch"
                      type="button"
                    >
                      <span className={`h-3.5 w-3.5 rounded-full bg-white shadow transition-transform ${sensor.monitored ? 'translate-x-[18px]' : 'translate-x-[2px]'}`} />
                    </button>
                  </td>}
                  <td className="px-3 py-2">
                    <button aria-label={`Inspect ${sensor.name}`} className="rounded p-1 text-slate-400 hover:bg-teal-50 hover:text-teal-700" onClick={() => onInspect(sensor)} type="button">
                      <ChevronRight size={14} />
                    </button>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <footer className="flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 px-4 py-2.5 text-[8px] text-slate-500 sm:px-5">
        <span>Showing {firstItem}–{lastItem} of {totalItems.toLocaleString()} sensors</span>
        <div className="flex items-center gap-2">
          <span>{pageSize} per page</span>
          <button aria-label="Previous sensor page" className="rounded p-1 hover:bg-slate-100 disabled:opacity-30" disabled={page <= 1} onClick={() => onPageChange(page - 1)} type="button"><ChevronLeft size={13} /></button>
          <span className="rounded bg-teal-50 px-2 py-1 font-semibold text-teal-700">{page}</span>
          <button aria-label="Next sensor page" className="rounded p-1 hover:bg-slate-100 disabled:opacity-30" disabled={page >= pageCount} onClick={() => onPageChange(page + 1)} type="button"><ChevronRight size={13} /></button>
        </div>
      </footer>
    </section>
  )
}
