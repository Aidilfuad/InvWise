import { useState } from 'react'
import { Check, CircleDot } from 'lucide-react'

function Sparkline({ values, color, fill }) {
  const max = Math.max(...values, 1)
  const min = Math.min(...values, 0)
  const span = max - min || 1
  const coordinates = values.map((value, index) => {
    const x = values.length < 2 ? 0 : (index / (values.length - 1)) * 160
    const y = 33 - ((value - min) / span) * 23
    return `${x},${y}`
  })
  const line = coordinates.join(' ')
  const area = `0,38 ${line} 160,38`

  return (
    <svg aria-hidden="true" className="mt-2 h-9 w-full overflow-visible" preserveAspectRatio="none" viewBox="0 0 160 40">
      <polygon fill={fill} points={area} />
      <polyline fill="none" points={line} stroke={color} strokeLinecap="round" strokeLinejoin="round" strokeWidth="1.7" />
    </svg>
  )
}

export default function TelemetryCard({ telemetry }) {
  const [activeZoneName, setActiveZoneName] = useState('Cold Storage A')
  const activeZone = telemetry.find((zone) => zone.name === activeZoneName) ?? telemetry[0]
  const secondaryZone = telemetry.find((zone) => zone.name !== activeZone?.name) ?? telemetry[1]

  if (!activeZone || !secondaryZone) return null

  const metrics = [
    { label: 'Temperature', value: `${Number(activeZone.temperature).toFixed(1)} °C`, target: 'Target 2–6°C', values: activeZone.temperatureSeries, color: '#0f9f8f', fill: 'rgba(15,159,143,0.08)' },
    { label: 'Humidity', value: `${Math.round(activeZone.humidity)} %`, target: 'Target 45–65%', values: activeZone.humiditySeries, color: '#4385f5', fill: 'rgba(67,133,245,0.08)' },
    { label: 'Energy draw', value: `${Number(activeZone.energy).toFixed(1)} kW`, target: 'Stable load', values: activeZone.energySeries, color: '#8b5cf6', fill: 'rgba(139,92,246,0.08)' },
  ]

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-3.5 shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h2 className="text-[13px] font-semibold text-slate-800">Real-Time Sensor Telemetry</h2>
        <div className="flex items-center gap-1.5">
          <span className="rounded bg-emerald-50 px-3 py-1 text-[9px] font-semibold text-emerald-700">Optimal</span>
          <span className="flex items-center gap-1 rounded bg-emerald-50 px-2 py-1 text-[9px] font-semibold text-emerald-700">
            <CircleDot size={8} fill="currentColor" />
            Live
          </span>
        </div>
      </div>

      <div className="mt-3 flex items-center gap-1 border-b border-slate-100 pb-2">
        {telemetry.map((zone) => (
          <button
            aria-pressed={zone.name === activeZoneName}
            className={`rounded px-3 py-1.5 text-[9px] transition ${
              zone.name === activeZoneName
                ? 'border border-slate-200 bg-white font-semibold text-teal-700 shadow-sm'
                : 'text-slate-500 hover:bg-slate-50'
            }`}
            key={zone.name}
            onClick={() => setActiveZoneName(zone.name)}
            type="button"
          >
            {zone.name}
          </button>
        ))}
        <span className="ml-auto whitespace-nowrap text-[9px] text-slate-400">Last 60 min</span>
      </div>

      <div className="mt-3 grid grid-cols-3 divide-x divide-slate-100">
        {metrics.map((metric) => (
          <div className="min-w-0 px-2 first:pl-0 last:pr-0" key={metric.label}>
            <p className="truncate text-[10px] text-slate-500">{metric.label}</p>
            <p className="mt-1 text-[21px] font-bold leading-6 tracking-[-0.03em] text-slate-900">{metric.value}</p>
            <p className="mt-0.5 text-[9px] text-slate-400">{metric.target}</p>
            <Sparkline color={metric.color} fill={metric.fill} values={metric.values} />
          </div>
        ))}
      </div>

      <div className="mt-2 flex flex-wrap items-center gap-2 rounded-md bg-slate-50 px-2.5 py-2 text-[9px]">
        <span className="font-medium text-slate-700">{secondaryZone.name}</span>
        <span className="text-slate-400">{Number(secondaryZone.temperature).toFixed(1)}°C</span>
        <span className="text-slate-300">·</span>
        <span className="text-slate-400">{Math.round(secondaryZone.humidity)}% RH</span>
        <span className="text-slate-300">·</span>
        <span className="text-slate-400">{Number(secondaryZone.energy).toFixed(1)} kW</span>
        <span className="ml-auto flex items-center gap-1 rounded bg-emerald-50 px-2 py-1 font-semibold text-emerald-700">
          <Check size={9} /> Optimal
        </span>
      </div>
    </section>
  )
}
