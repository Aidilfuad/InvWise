import { useState } from 'react'
import { Activity, X } from 'lucide-react'

export default function ManageRulesModal({ rules, onClose, onSave }) {
  const [values, setValues] = useState(rules)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  async function submit(event) {
    event.preventDefault()
    setSaving(true)
    setError('')
    try {
      await onSave(values)
      onClose()
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to save alert rules.')
    } finally {
      setSaving(false)
    }
  }

  function update(key, value) {
    setValues((current) => ({ ...current, [key]: value }))
  }

  return (
    <div className="fixed inset-0 z-[80] grid place-items-center overflow-y-auto bg-slate-950/45 p-4" onMouseDown={(event) => {
      if (event.target === event.currentTarget) onClose()
    }}>
      <section aria-labelledby="manage-rules-title" aria-modal="true" className="my-auto w-full max-w-[440px] rounded-xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-50 text-teal-700"><Activity size={17} /></span>
            <div>
              <h2 className="text-sm font-semibold text-slate-900" id="manage-rules-title">Manage alert rules</h2>
              <p className="mt-1 text-[10px] text-slate-500">Set thresholds used by telemetry monitoring.</p>
            </div>
          </div>
          <button aria-label="Close alert rules" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100" onClick={onClose} type="button"><X size={16} /></button>
        </header>
        <form className="space-y-4 p-5" onSubmit={submit}>
          <label className="block text-[10px] font-medium text-slate-700">
            Voltage warning threshold
            <div className="mt-1 flex items-center rounded-md border border-slate-200 focus-within:border-teal-500">
              <input className="h-9 min-w-0 flex-1 bg-transparent px-3 text-xs outline-none" min="1" onChange={(event) => update('voltage_warning_threshold', event.target.value)} required step="1" type="number" value={values.voltage_warning_threshold} />
              <span className="pr-3 text-[10px] text-slate-400">volts</span>
            </div>
          </label>
          <label className="block text-[10px] font-medium text-slate-700">
            Current warning threshold
            <div className="mt-1 flex items-center rounded-md border border-slate-200 focus-within:border-teal-500">
              <input className="h-9 min-w-0 flex-1 bg-transparent px-3 text-xs outline-none" min="0.1" onChange={(event) => update('current_warning_threshold', event.target.value)} required step="0.1" type="number" value={values.current_warning_threshold} />
              <span className="pr-3 text-[10px] text-slate-400">amps</span>
            </div>
          </label>
          <label className="block text-[10px] font-medium text-slate-700">
            Sensor offline after
            <div className="mt-1 flex items-center rounded-md border border-slate-200 focus-within:border-teal-500">
              <input className="h-9 min-w-0 flex-1 bg-transparent px-3 text-xs outline-none" max="60" min="2" onChange={(event) => update('offline_timeout_minutes', event.target.value)} required step="1" type="number" value={values.offline_timeout_minutes} />
              <span className="pr-3 text-[10px] text-slate-400">minutes</span>
            </div>
          </label>
          {error && <p className="rounded-md bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          <div className="flex justify-end gap-2 pt-1">
            <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-medium text-slate-600 hover:bg-slate-50" onClick={onClose} type="button">Cancel</button>
            <button className="h-9 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-50" disabled={saving} type="submit">{saving ? 'Saving…' : 'Save rules'}</button>
          </div>
        </form>
      </section>
    </div>
  )
}
