import { useState } from 'react'
import { X } from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'

const initialForm = {
  name: '',
  sku: '',
  categoryId: '',
  unitId: '',
  locationId: '',
  quantity: '0',
  minimumStock: '0',
  unitPrice: '0',
  notes: '',
}

export default function AddInventoryModal({
  categories,
  items,
  locations,
  onClose,
  onSubmit,
  units,
}) {
  const [form, setForm] = useState(initialForm)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  function update(event) {
    setForm((current) => ({ ...current, [event.target.name]: event.target.value }))
  }

  async function submit(event) {
    event.preventDefault()
    const sku = form.sku.trim()
    const name = form.name.trim()
    const unitId = units.some((unit) => unit.id === form.unitId) ? form.unitId : units[0]?.id || ''
    const locationId = locations.some((location) => location.id === form.locationId)
      ? form.locationId
      : locations[0]?.id || ''
    const categoryId = categories.some((category) => category.id === form.categoryId) ? form.categoryId : ''
    const duplicate = items.some((item) => item.sku.toLowerCase() === sku.toLowerCase())
    if (!name || !sku || !unitId || !locationId) {
      setError('Enter an item name and SKU, and choose a unit and warehouse.')
      return
    }
    if (duplicate) {
      setError('That SKU is already in use. Enter a unique SKU.')
      return
    }
    const numericValues = [form.quantity, form.minimumStock, form.unitPrice].map(Number)
    if (numericValues.some((value) => !Number.isFinite(value) || value < 0)) {
      setError('Initial quantity, minimum stock, and unit price must be zero or greater.')
      return
    }

    setLoading(true)
    setError('')
    try {
      await onSubmit({
        name,
        sku,
        categoryId,
        unitId,
        locationId,
        quantity: numericValues[0],
        minimumStock: numericValues[1],
        unitPrice: numericValues[2],
        notes: form.notes,
      })
      onClose()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to add this inventory item.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center bg-slate-950/45 p-4" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !loading) onClose()
    }}>
      <section aria-labelledby="add-inventory-title" aria-modal="true" className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-xl border border-slate-200 bg-white p-5 shadow-2xl sm:p-6" role="dialog">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-[9px] font-semibold uppercase tracking-[0.14em] text-teal-700">Inventory operations</p>
            <h2 className="mt-1.5 text-lg font-bold text-slate-900" id="add-inventory-title">Add inventory</h2>
            <p className="mt-1 text-[11px] text-slate-500">Create an item and assign its opening stock to a warehouse.</p>
          </div>
          <button aria-label="Close dialog" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700" onClick={onClose} type="button"><X size={16} /></button>
        </div>

        <form className="mt-5 space-y-3" onSubmit={submit}>
          <div className="grid gap-3 sm:grid-cols-2">
            <label className="block text-[10px] font-medium text-slate-700 sm:col-span-2">
              Item name
              <input autoFocus className="modal-input mt-1.5" maxLength={120} name="name" onChange={update} placeholder="e.g. Thermal labels 4×6" required value={form.name} />
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              SKU
              <input className="modal-input mt-1.5" maxLength={64} name="sku" onChange={update} placeholder="SKU-LBL-042" required value={form.sku} />
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              Category
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Category"
                  className="modal-input"
                  onChange={(categoryId) => setForm((current) => ({ ...current, categoryId }))}
                  options={[
                    { value: '', label: 'Uncategorized' },
                    ...categories.map((category) => ({ value: category.id, label: category.name })),
                  ]}
                  value={categories.some((category) => category.id === form.categoryId) ? form.categoryId : ''}
                />
              </span>
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              Unit
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Unit"
                  className="modal-input"
                  onChange={(unitId) => setForm((current) => ({ ...current, unitId }))}
                  options={[
                    { value: '', label: 'Select unit' },
                    ...units.map((unit) => ({ value: unit.id, label: `${unit.name} (${unit.abbreviation})` })),
                  ]}
                  value={units.some((unit) => unit.id === form.unitId) ? form.unitId : units[0]?.id || ''}
                />
              </span>
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              Warehouse
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Warehouse"
                  className="modal-input"
                  onChange={(locationId) => setForm((current) => ({ ...current, locationId }))}
                  options={[
                    { value: '', label: 'Select warehouse' },
                    ...locations.map((location) => ({ value: location.id, label: location.name })),
                  ]}
                  value={locations.some((location) => location.id === form.locationId) ? form.locationId : locations[0]?.id || ''}
                />
              </span>
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              Initial quantity
              <input className="modal-input mt-1.5" min="0" name="quantity" onChange={update} required step="0.01" type="number" value={form.quantity} />
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              Minimum stock
              <input className="modal-input mt-1.5" min="0" name="minimumStock" onChange={update} required step="0.01" type="number" value={form.minimumStock} />
            </label>
            <label className="block text-[10px] font-medium text-slate-700">
              Unit price
              <input className="modal-input mt-1.5" min="0" name="unitPrice" onChange={update} required step="0.01" type="number" value={form.unitPrice} />
            </label>
            <label className="block text-[10px] font-medium text-slate-700 sm:col-span-2">
              Notes <span className="font-normal text-slate-400">(optional)</span>
              <textarea className="modal-input mt-1.5 min-h-16 resize-y" maxLength={240} name="notes" onChange={update} value={form.notes} />
            </label>
          </div>

          {error && <p className="rounded-md border border-rose-100 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          {units.length === 0 && <p className="text-[9px] text-amber-700">No units are available in this workspace. Add a unit before creating inventory.</p>}
          <div className="flex gap-2 pt-1">
            <button className="h-9 flex-1 rounded-md border border-slate-200 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" disabled={loading} onClick={onClose} type="button">Cancel</button>
            <button className="h-9 flex-1 rounded-md bg-teal-600 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={loading || units.length === 0 || locations.length === 0} type="submit">
              {loading ? 'Saving...' : 'Create inventory item'}
            </button>
          </div>
        </form>
      </section>
    </div>
  )
}
