import { useMemo, useState } from 'react'
import SearchableSelect from '../common/SearchableSelect'

const metrics = {
  temperature: { label: 'Temperature', unit: '°C', range: [18, 26], domain: [0, 35], color: '#0d9488' },
  humidity: { label: 'Humidity', unit: '%', range: [35, 65], domain: [0, 100], color: '#2563eb' },
  power: { label: 'Power', unit: 'kW', range: [0, 60], domain: [0, 80], color: '#7c3aed' },
  voltage: { label: 'Voltage', unit: 'V', range: [220, 250], domain: [180, 270], color: '#d97706' },
}

function formatValue(value, unit) {
  return `${Number(value).toFixed(1)} ${unit}`
}

function rangeDuration(range) {
  return range === '30d' ? 30 * 24 : range === '7d' ? 7 * 24 : 24
}

export default function TelemetryTrendCard({
  metric,
  onMetricChange,
  range,
  sensors,
  warehouse,
  warehouses,
  onWarehouseChange,
}) {
  const [hoverIndex, setHoverIndex] = useState(null)
  const selectedMetric = metrics[metric]
  const matchingSensors = sensors.filter((sensor) => (
    sensor.metric === metric && (warehouse === 'all' || sensor.warehouse === warehouse)
  ))
  const latestSensor = matchingSensors
    .filter((sensor) => Number.isFinite(sensor.reading))
    .sort((left, right) => (right.lastSeen?.getTime() ?? 0) - (left.lastSeen?.getTime() ?? 0))[0]
  const values = useMemo(() => {
    const available = matchingSensors.filter((sensor) => sensor.trend.length > 0)
    if (!available.length) return []
    const length = Math.max(...available.map((sensor) => sensor.trend.length))
    return Array.from({ length }, (_, index) => {
      const current = available
        .map((sensor) => sensor.trend[Math.min(index, sensor.trend.length - 1)])
        .filter((value) => Number.isFinite(value))
      return current.length ? current.reduce((sum, value) => sum + value, 0) / current.length : null
    })
  }, [matchingSensors])

  const chart = useMemo(() => {
    if (!values.length) return { line: '', area: '', points: [] }
    const [min, max] = selectedMetric.domain
    const points = values.map((value, index) => {
      const x = 42 + (index / Math.max(values.length - 1, 1)) * 576
      const y = 172 - ((value - min) / (max - min)) * 132
      return { x, y, value }
    })
    const line = points.map((point, index) => `${index ? 'L' : 'M'} ${point.x} ${point.y}`).join(' ')
    return {
      line,
      area: `${line} L 618 178 L 42 178 Z`,
      points,
    }
  }, [selectedMetric, values])

  function handlePointerMove(event) {
    if (!chart.points.length) return
    const rect = event.currentTarget.getBoundingClientRect()
    const ratio = Math.max(0, Math.min(1, (event.clientX - rect.left) / rect.width))
    setHoverIndex(Math.round(ratio * (chart.points.length - 1)))
  }

  function timestampAt(index) {
    const hours = rangeDuration(range)
    const elapsed = hours * (index / Math.max(values.length - 1, 1))
    const ago = Math.max(0, hours - elapsed)
    if (ago < 24) return `${Math.round(ago)}h ago`
    return `${Math.max(1, Math.round(ago / 24))}d ago`
  }

  const hoverPoint = hoverIndex == null ? null : chart.points[hoverIndex]
  const bandTop = 172 - ((selectedMetric.range[1] - selectedMetric.domain[0]) / (selectedMetric.domain[1] - selectedMetric.domain[0])) * 132
  const bandBottom = 172 - ((selectedMetric.range[0] - selectedMetric.domain[0]) / (selectedMetric.domain[1] - selectedMetric.domain[0])) * 132

  return (
    <section aria-label="Sensor trends" className="min-w-0 rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-sm font-bold text-slate-900">Sensor trends</h2>
          <p className="mt-1 text-[10px] text-slate-500">Average readings across connected sensors</p>
        </div>
        <SearchableSelect
          aria-label="Trend warehouse"
          className="h-8 min-w-[142px] text-[10px] text-slate-700"
          onChange={onWarehouseChange}
          options={[
            { value: 'all', label: 'All warehouses' },
            ...warehouses.map((name) => ({ value: name, label: name })),
          ]}
          value={warehouse}
        />
      </div>

      <div className="mt-4 flex flex-wrap items-center justify-between gap-2">
        <div aria-label="Trend metric" className="grid grid-cols-4 rounded-md bg-slate-100 p-0.5" role="group">
          {Object.entries(metrics).map(([id, option]) => (
            <button
              aria-pressed={metric === id}
              className={`rounded px-2.5 py-1.5 text-[9px] transition sm:px-3 ${metric === id ? 'bg-white font-semibold text-teal-700 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`}
              key={id}
              onClick={() => { onMetricChange(id); setHoverIndex(null) }}
              type="button"
            >
              {option.label}
            </button>
          ))}
        </div>
        <span className="inline-flex items-center gap-1.5 text-[9px] text-slate-500">
          <span className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: selectedMetric.color }} />
          {selectedMetric.label}
        </span>
      </div>

      <div className="relative mt-3">
        {hoverPoint && (
          <div
            className="pointer-events-none absolute top-2 z-10 rounded-md border border-slate-200 bg-white px-2 py-1.5 text-[9px] shadow-lg"
            style={{ left: `${Math.min(78, Math.max(8, (hoverPoint.x / 660) * 100))}%` }}
          >
            <p className="text-slate-500">{timestampAt(hoverIndex)}</p>
            <p className="mt-0.5 font-bold text-slate-900">{formatValue(hoverPoint.value, selectedMetric.unit)}</p>
          </div>
        )}
        {values.length ? (
          <svg
            aria-label={`${selectedMetric.label} trend chart. Move the pointer across the chart to inspect readings.`}
            className="h-[184px] w-full touch-none"
            onPointerLeave={() => setHoverIndex(null)}
            onPointerMove={handlePointerMove}
            preserveAspectRatio="none"
            role="img"
            viewBox="0 0 660 200"
          >
            <rect fill="#ecfdf5" height={Math.max(0, bandBottom - bandTop)} opacity="0.8" width="576" x="42" y={bandTop} />
            {[40, 84, 128, 172].map((y) => (
              <line key={y} stroke="#e8eef3" strokeDasharray={y === 172 ? undefined : '3 4'} x1="42" x2="618" y1={y} y2={y} />
            ))}
            <path d={chart.area} fill={selectedMetric.color} fillOpacity="0.08" />
            <path d={chart.line} fill="none" stroke={selectedMetric.color} strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
            {hoverPoint && (
              <>
                <line stroke="#94a3b8" strokeDasharray="3 3" x1={hoverPoint.x} x2={hoverPoint.x} y1="30" y2="178" />
                <circle cx={hoverPoint.x} cy={hoverPoint.y} fill="white" r="4.5" stroke={selectedMetric.color} strokeWidth="2.5" />
              </>
            )}
            <text fill="#94a3b8" fontSize="9" x="4" y="43">{selectedMetric.range[1]}{selectedMetric.unit}</text>
            <text fill="#94a3b8" fontSize="9" x="4" y="176">{selectedMetric.range[0]}{selectedMetric.unit}</text>
            <text fill="#94a3b8" fontSize="9" x="42" y="196">00:00</text>
            <text fill="#94a3b8" fontSize="9" textAnchor="middle" x="330" y="196">{range === '24h' ? '12:00' : range === '7d' ? '4 days ago' : '15 days ago'}</text>
            <text fill="#94a3b8" fontSize="9" textAnchor="end" x="618" y="196">Now</text>
          </svg>
        ) : (
          latestSensor ? (
            <div className="flex min-h-[184px] flex-col justify-center rounded-lg border border-slate-100 bg-slate-50/70 px-5 py-4">
              <p className="text-[9px] font-semibold uppercase tracking-wide text-slate-500">Most recent {selectedMetric.label.toLowerCase()} reading</p>
              <p className="mt-2 text-2xl font-bold text-slate-900">{formatValue(latestSensor.reading, latestSensor.unit || selectedMetric.unit)}</p>
              <p className="mt-2 text-[10px] font-semibold text-slate-700">{latestSensor.name} <span className="font-normal text-slate-400">· {latestSensor.code}</span></p>
              <p className="mt-1 text-[9px] text-slate-500">{latestSensor.warehouse}{latestSensor.zone ? ` · ${latestSensor.zone}` : ''}</p>
              <p className="mt-1 text-[9px] text-slate-400">{latestSensor.lastSeen ? new Date(latestSensor.lastSeen).toLocaleString() : 'Timestamp unavailable'}</p>
            </div>
          ) : (
            <div className="grid h-[184px] place-items-center text-[11px] text-slate-400">No {selectedMetric.label.toLowerCase()} readings for this selection.</div>
          )
        )}
      </div>

      <div className="mt-2 flex flex-wrap items-center justify-between gap-2 text-[9px] text-slate-500">
        <span className="inline-flex items-center gap-1.5">
          <span className="h-1.5 w-1.5 rounded-full bg-teal-600" />
          Within optimal range
        </span>
        <span>Optimal: {selectedMetric.range[0]}–{selectedMetric.range[1]} {selectedMetric.unit}</span>
      </div>
    </section>
  )
}
