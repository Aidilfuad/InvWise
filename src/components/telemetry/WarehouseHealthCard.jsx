import { AlertTriangle, ChevronRight } from 'lucide-react'

export default function WarehouseHealthCard({ sensors, onShowAttention }) {
  const locations = [...new Set(sensors.map((sensor) => sensor.warehouse))]
    .map((name) => {
      const locationSensors = sensors.filter((sensor) => sensor.warehouse === name)
      return {
        name,
        total: locationSensors.length,
        offline: locationSensors.filter((sensor) => sensor.status === 'offline').length,
        online: locationSensors.filter((sensor) => sensor.status !== 'offline').length,
      }
    })
    .sort((left, right) => left.name.localeCompare(right.name))
    .slice(0, 4)
  const attentionCount = sensors.filter((sensor) => sensor.status === 'warning' || sensor.status === 'offline').length

  return (
    <section aria-label="Warehouse health" className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5">
      <div>
        <h2 className="text-sm font-bold text-slate-900">Warehouse health</h2>
        <p className="mt-1 text-[10px] text-slate-500">{locations.length} locations · {sensors.length.toLocaleString()} sensors</p>
      </div>

      <div className="mt-4 space-y-3">
        {locations.map((location) => {
          const progress = location.total ? (location.online / location.total) * 100 : 0
          return (
            <div key={location.name}>
              <div className="flex items-center justify-between gap-2 text-[10px]">
                <span className="truncate font-semibold text-slate-800">{location.name}</span>
                <span className="shrink-0 text-[8px] text-slate-400">{location.total} sensors</span>
              </div>
              <div className="mt-1 flex items-center gap-2">
                <div aria-label={`${progress.toFixed(0)} percent online`} className="h-1.5 flex-1 overflow-hidden rounded-full bg-slate-100">
                  <div className="h-full rounded-full bg-teal-600 transition-all" style={{ width: `${progress}%` }} />
                </div>
                <span className="w-[100px] shrink-0 text-right text-[8px] text-slate-500">
                  {location.online} online · {location.offline} offline
                </span>
              </div>
            </div>
          )
        })}
        {locations.length === 0 && <p className="py-5 text-center text-[10px] text-slate-400">No warehouse sensor data available.</p>}
      </div>

      <button
        className="mt-4 flex w-full items-center gap-2 rounded-md border border-amber-100 bg-amber-50 px-2.5 py-2 text-left text-[9px] font-semibold text-amber-800 transition hover:bg-amber-100"
        onClick={onShowAttention}
        type="button"
      >
        <AlertTriangle className="shrink-0 text-amber-600" size={13} />
        <span className="flex-1">{attentionCount} sensors need attention</span>
        <ChevronRight className="shrink-0" size={12} />
      </button>
    </section>
  )
}
