import { useState } from 'react'
import { X } from 'lucide-react'

export default function ThresholdSettingsModal({ onClose, onSave, settings }) {
  const [values, setValues] = useState({
    voltage_warning_threshold: String(settings.voltage_warning_threshold),
    current_warning_threshold: String(settings.current_warning_threshold),
    offline_timeout_minutes: String(settings.offline_timeout_minutes),
    realtime_enabled: settings.realtime_enabled,
  })
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  function update(field, value) {
    setValues((current) => ({ ...current, [field]: value }))
  }

  async function submit(event) {
    event.preventDefault()
    setSaving(true)
    setError('')
    try {
      await onSave(values)
      onClose()
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to save telemetry settings.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[90] grid place-items-center bg-slate-950/45 p-4" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <section aria-labelledby="threshold-title" aria-modal="true" className="w-full max-w-[440px] rounded-xl border border-slate-200 bg-white p-5 shadow-2xl sm:p-6" role="dialog">
        <header className="flex items-start justify-between gap-4">
          <div>
            <p className="text-[9px] font-semibold uppercase tracking-[0.12em] text-teal-700">Telemetry configuration</p>
            <h2 className="mt-1 text-base font-bold text-slate-900" id="threshold-title">Configure Thresholds</h2>
            <p className="mt-1 text-[10px] leading-4 text-slate-500">Set alert limits for connected energy sensors.</p>
          </div>
          <button aria-label="Close threshold settings" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700" onClick={onClose} type="button"><X size={16} /></button>
        </header>

        <form className="mt-5 space-y-4" onSubmit={submit}>
          <label className="block text-[10px] font-semibold text-slate-700">
            Voltage warning threshold
            <div className="relative mt-1.5">
              <input className="h-9 w-full rounded-md border border-slate-200 px-3 pr-12 text-xs text-slate-800 outline-none focus:border-teal-500" min="1" onChange={(event) => update('voltage_warning_threshold', event.target.value)} required step="0.1" type="number" value={values.voltage_warning_threshold} />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] font-normal text-slate-400">V</span>
            </div>
          </label>
          <label className="block text-[10px] font-semibold text-slate-700">
            Current warning threshold
            <div className="relative mt-1.5">
              <input className="h-9 w-full rounded-md border border-slate-200 px-3 pr-12 text-xs text-slate-800 outline-none focus:border-teal-500" min="0.1" onChange={(event) => update('current_warning_threshold', event.target.value)} required step="0.1" type="number" value={values.current_warning_threshold} />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] font-normal text-slate-400">A</span>
            </div>
          </label>
          <label className="block text-[10px] font-semibold text-slate-700">
            Offline timeout
            <div className="relative mt-1.5">
              <input className="h-9 w-full rounded-md border border-slate-200 px-3 pr-16 text-xs text-slate-800 outline-none focus:border-teal-500" max="60" min="2" onChange={(event) => update('offline_timeout_minutes', event.target.value)} required step="1" type="number" value={values.offline_timeout_minutes} />
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] font-normal text-slate-400">minutes</span>
            </div>
          </label>
          <label className="flex items-center justify-between gap-3 rounded-md border border-slate-200 px-3 py-2.5 text-[10px] font-medium text-slate-700">
            Enable realtime monitoring
            <input checked={values.realtime_enabled} className="h-4 w-4 accent-teal-600" onChange={(event) => update('realtime_enabled', event.target.checked)} type="checkbox" />
          </label>

          {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}

          <div className="flex justify-end gap-2 pt-1">
            <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" onClick={onClose} type="button">Cancel</button>
            <button className="h-9 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={saving} type="submit">
              {saving ? 'Saving…' : 'Save thresholds'}
            </button>
          </div>
        </form>
      </section>
    </div>
  )
}
