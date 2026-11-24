import { useState } from 'react'
import { Layers3, Ruler, X } from 'lucide-react'

export default function CategoriesUnitsModal({
  categories,
  units,
  onClose,
  onCreateCategory,
  onCreateUnit,
  onCategoryActiveChange,
  onUnitActiveChange,
}) {
  const [tab, setTab] = useState('categories')
  const [name, setName] = useState('')
  const [abbreviation, setAbbreviation] = useState('')
  const [description, setDescription] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')

  async function submit(event) {
    event.preventDefault()
    setPending(true)
    setError('')
    try {
      if (tab === 'categories') await onCreateCategory({ name, description })
      else await onCreateUnit({ name, abbreviation, description })
      setName('')
      setAbbreviation('')
      setDescription('')
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to save this entry.')
    } finally {
      setPending(false)
    }
  }

  async function toggleActive(kind, row) {
    setPending(true)
    setError('')
    try {
      if (kind === 'category') await onCategoryActiveChange({ id: row.id, active: row.is_active === false })
      else await onUnitActiveChange({ id: row.id, active: row.is_active === false })
    } catch (toggleError) {
      setError(toggleError instanceof Error ? toggleError.message : 'Unable to update this entry.')
    } finally {
      setPending(false)
    }
  }

  const list = tab === 'categories' ? categories : units

  return (
    <div className="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/45 p-3 sm:p-5" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !pending) onClose()
    }}>
      <section aria-labelledby="catalog-settings-title" aria-modal="true" className="flex max-h-[92vh] w-full max-w-xl flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <div className="flex items-start justify-between border-b border-slate-100 px-5 py-5 sm:px-6">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-teal-700">Catalog setup</p>
            <h2 className="mt-1.5 text-lg font-bold text-slate-900" id="catalog-settings-title">Categories & Units</h2>
            <p className="mt-1 text-xs text-slate-500">Manage the labels and measurements used by your inventory.</p>
          </div>
          <button aria-label="Close dialog" className="rounded-lg p-2 text-slate-400 hover:bg-slate-100" disabled={pending} onClick={onClose} type="button"><X size={17} /></button>
        </div>

        <div className="grid grid-cols-2 gap-1 border-b border-slate-100 bg-slate-50 p-1.5">
          <button aria-pressed={tab === 'categories'} className={`flex h-9 items-center justify-center gap-2 rounded-lg text-xs font-semibold ${tab === 'categories' ? 'bg-white text-teal-700 shadow-sm' : 'text-slate-500'}`} onClick={() => { setTab('categories'); setError('') }} type="button">
            <Layers3 size={14} /> Categories
          </button>
          <button aria-pressed={tab === 'units'} className={`flex h-9 items-center justify-center gap-2 rounded-lg text-xs font-semibold ${tab === 'units' ? 'bg-white text-teal-700 shadow-sm' : 'text-slate-500'}`} onClick={() => { setTab('units'); setError('') }} type="button">
            <Ruler size={14} /> Units
          </button>
        </div>

        <div className="overflow-y-auto px-5 py-4 sm:px-6">
          <form className="rounded-xl border border-slate-200 bg-slate-50/70 p-3.5" onSubmit={submit}>
            <div className="grid gap-2 sm:grid-cols-[1fr_1fr_auto]">
              <input aria-label={tab === 'categories' ? 'Category name' : 'Unit name'} className="modal-input h-9" maxLength={80} onChange={(event) => setName(event.target.value)} placeholder={tab === 'categories' ? 'New category name' : 'New unit name'} required value={name} />
              {tab === 'units' ? (
                <input aria-label="Unit abbreviation" className="modal-input h-9" maxLength={12} onChange={(event) => setAbbreviation(event.target.value)} placeholder="Abbreviation" required value={abbreviation} />
              ) : (
                <input aria-label="Category description" className="modal-input h-9" maxLength={160} onChange={(event) => setDescription(event.target.value)} placeholder="Description (optional)" value={description} />
              )}
              <button className="h-9 rounded-lg bg-teal-600 px-3 text-xs font-semibold text-white hover:bg-teal-700 disabled:opacity-50" disabled={pending} type="submit">Add</button>
            </div>
            {tab === 'units' && <input aria-label="Unit description" className="modal-input mt-2 h-9" maxLength={160} onChange={(event) => setDescription(event.target.value)} placeholder="Description (optional)" value={description} />}
          </form>

          {error && <p className="mt-3 rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-xs text-rose-700" role="alert">{error}</p>}

          <div className="mt-4 divide-y divide-slate-100">
            {list.length === 0 ? <p className="py-8 text-center text-xs text-slate-500">No {tab} have been added.</p> : list.map((row) => (
              <div className="flex items-center justify-between gap-3 py-3" key={row.id}>
                <div className="min-w-0">
                  <p className={`truncate text-xs font-semibold ${row.is_active === false ? 'text-slate-400' : 'text-slate-800'}`}>{row.name}{tab === 'units' && row.abbreviation ? ` (${row.abbreviation})` : ''}</p>
                  {row.description && <p className="mt-0.5 truncate text-[10px] text-slate-400">{row.description}</p>}
                </div>
                <button className={`shrink-0 rounded-full px-2.5 py-1 text-[10px] font-semibold ${row.is_active === false ? 'bg-slate-100 text-slate-500' : 'bg-emerald-50 text-emerald-700'}`} disabled={pending} onClick={() => toggleActive(tab === 'categories' ? 'category' : 'unit', row)} type="button">
                  {row.is_active === false ? 'Inactive · Activate' : 'Active · Deactivate'}
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>
    </div>
  )
}
