import { Activity, Clock3, MapPin, Thermometer, X } from 'lucide-react'

export default function SensorDetailsDrawer({ onClose, sensor }) {
  if (!sensor) return null

  const statusLabel = sensor.status === 'optimal' ? 'Optimal' : sensor.status === 'warning' ? 'Warning' : 'Offline'

  return (
    <div className="fixed inset-0 z-[80] flex justify-end bg-slate-950/35" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <aside aria-labelledby="sensor-details-title" aria-modal="true" className="flex h-full w-full max-w-[410px] flex-col overflow-y-auto border-l border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div>
            <p className="text-[9px] font-semibold uppercase tracking-[0.12em] text-teal-700">Sensor details</p>
            <h2 className="mt-1 text-base font-bold text-slate-900" id="sensor-details-title">{sensor.name}</h2>
            <p className="mt-1 text-[10px] text-slate-500">{sensor.code}</p>
          </div>
          <button aria-label="Close sensor details" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700" onClick={onClose} type="button"><X size={16} /></button>
        </header>

        <div className="space-y-4 p-5">
          <section className="rounded-lg border border-slate-200 bg-slate-50 p-4">
            <div className="flex items-center justify-between gap-3">
              <span className="inline-flex items-center gap-2 text-[10px] font-medium text-slate-600"><Thermometer size={14} /> Current reading</span>
              <span className={`rounded px-2 py-1 text-[9px] font-semibold ${sensor.status === 'optimal' ? 'bg-teal-50 text-teal-700' : sensor.status === 'warning' ? 'bg-amber-50 text-amber-700' : 'bg-slate-200 text-slate-600'}`}>{statusLabel}</span>
            </div>
            <p className="mt-3 text-2xl font-bold text-slate-900">{sensor.reading == null ? '—' : `${Number(sensor.reading).toFixed(1)} ${sensor.unit}`}</p>
            <p className="mt-1 text-[9px] text-slate-500">Configured threshold: {sensor.threshold}</p>
          </section>

          <section className="space-y-3 rounded-lg border border-slate-200 p-4">
            <h3 className="text-[10px] font-bold text-slate-800">Sensor information</h3>
            <div className="flex items-start gap-2 text-[10px]">
              <MapPin className="mt-0.5 shrink-0 text-slate-400" size={13} />
              <div><p className="font-medium text-slate-700">{sensor.warehouse}</p><p className="mt-0.5 text-slate-500">{sensor.zone}</p></div>
            </div>
            <div className="flex items-start gap-2 text-[10px]">
              <Activity className="mt-0.5 shrink-0 text-slate-400" size={13} />
              <div><p className="font-medium capitalize text-slate-700">{sensor.metric} sensor</p><p className="mt-0.5 text-slate-500">Monitoring {sensor.monitored ? 'enabled' : 'paused'}</p></div>
            </div>
            <div className="flex items-start gap-2 text-[10px]">
              <Clock3 className="mt-0.5 shrink-0 text-slate-400" size={13} />
              <div><p className="font-medium text-slate-700">Last heartbeat</p><p className="mt-0.5 text-slate-500">{sensor.lastSeen ? new Date(sensor.lastSeen).toLocaleString() : 'No heartbeat recorded'}</p></div>
            </div>
          </section>

          <section className="rounded-lg border border-slate-200 p-4">
            <div className="flex items-center justify-between">
              <h3 className="text-[10px] font-bold text-slate-800">Recent readings</h3>
              <span className="text-[9px] text-slate-400">Latest 24 points</span>
            </div>
            {sensor.trend?.length ? (
              <div aria-label={`${sensor.name} recent sensor readings`} className="mt-4 flex h-16 items-end gap-1" role="img">
                {sensor.trend.slice(-24).map((value, index) => {
                  const min = Math.min(...sensor.trend)
                  const max = Math.max(...sensor.trend)
                  const height = max === min ? 50 : 18 + ((value - min) / (max - min)) * 72
                  return <span aria-hidden="true" className="flex-1 rounded-t-sm bg-teal-500/80" key={`${index}-${value}`} style={{ height: `${height}%` }} />
                })}
              </div>
            ) : <p className="mt-3 text-[10px] text-slate-400">No historical readings are available.</p>}
          </section>
        </div>
      </aside>
    </div>
  )
}
