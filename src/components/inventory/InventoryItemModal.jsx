import { useState } from 'react'
import { X } from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'

function initialValues(item, units, warehouses) {
  const locationId = item?.locationId ?? warehouses[0]?.id ?? ''
  return {
    name: item?.name ?? '',
    sku: item?.sku ?? '',
    barcode: item?.barcode ?? '',
    categoryId: item?.categoryId ?? '',
    unitId: item?.unitId ?? units.find((unit) => unit.is_active !== false)?.id ?? '',
    locationId,
    binLocation: item?.binLocations?.[locationId] ?? item?.binLocation ?? '',
    quantity: String(item?.levels?.[locationId] ?? 0),
    minimumStock: String(item?.minimumStock ?? 0),
    unitPrice: String(item?.unitPrice ?? 0),
    notes: item?.notes ?? '',
  }
}

export default function InventoryItemModal({
  item,
  categories,
  units,
  warehouses,
  barcodeAvailable,
  binLocationAvailable,
  onClose,
  onSubmit,
}) {
  const [form, setForm] = useState(() => initialValues(item, units, warehouses))
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')

  function update(event) {
    const { name, value } = event.target
    if (name === 'locationId' && item) {
      setForm((current) => ({
        ...current,
        locationId: value,
        quantity: String(item.levels?.[value] ?? 0),
        binLocation: item.binLocations?.[value] ?? '',
      }))
      return
    }
    setForm((current) => ({ ...current, [name]: value }))
  }

  async function submit(event) {
    event.preventDefault()
    const numeric = [form.quantity, form.minimumStock, form.unitPrice].map(Number)
    if (!form.name.trim() || !form.sku.trim() || !form.unitId || !form.locationId) {
      setError('Enter an item name and SKU, and choose a unit and warehouse.')
      return
    }
    if (numeric.some((value) => !Number.isFinite(value) || value < 0)) {
      setError('Quantity, minimum stock, and unit price must be zero or greater.')
      return
    }

    setPending(true)
    setError('')
    try {
      await onSubmit({
        itemId: item?.id,
        name: form.name,
        sku: form.sku,
        barcode: form.barcode,
        categoryId: form.categoryId,
        unitId: form.unitId,
        locationId: form.locationId,
        binLocation: form.binLocation,
        quantity: numeric[0],
        minimumStock: numeric[1],
        unitPrice: numeric[2],
        notes: form.notes,
      })
      onClose()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to save this inventory item.')
    } finally {
      setPending(false)
    }
  }

  return (
    <div
      className="fixed inset-0 z-[80] flex items-center justify-center bg-slate-950/45 p-3 sm:p-5"
      onMouseDown={(event) => {
        if (event.target === event.currentTarget && !pending) onClose()
      }}
    >
      <section aria-labelledby="inventory-item-modal-title" aria-modal="true" className="max-h-[94vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-slate-200 bg-white p-5 shadow-2xl sm:p-7" role="dialog">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-teal-700">Inventory catalog</p>
            <h2 className="mt-1.5 text-xl font-bold tracking-tight text-slate-900" id="inventory-item-modal-title">{item ? 'Edit inventory item' : 'Add new item'}</h2>
            <p className="mt-1 text-xs text-slate-500">{item ? 'Update item details and its stock at a warehouse.' : 'Create an item and set its opening warehouse quantity.'}</p>
          </div>
          <button aria-label="Close dialog" className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700" disabled={pending} onClick={onClose} type="button"><X size={18} /></button>
        </div>

        <form className="mt-6 space-y-4" onSubmit={submit}>
          <div className="grid gap-4 sm:grid-cols-2">
            <label className="block text-xs font-medium text-slate-700 sm:col-span-2">
              Item name
              <input autoFocus className="modal-input mt-1.5" maxLength={120} name="name" onChange={update} placeholder="e.g. Thermal labels 4×6" required value={form.name} />
            </label>
            <label className="block text-xs font-medium text-slate-700">
              SKU
              <input className="modal-input mt-1.5" maxLength={64} name="sku" onChange={update} placeholder="SKU-LBL-042" required value={form.sku} />
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Barcode <span className="font-normal text-slate-400">(optional)</span>
              <input className="modal-input mt-1.5" maxLength={128} name="barcode" onChange={update} placeholder="Scan or enter barcode" value={form.barcode} />
              {!barcodeAvailable && <span className="mt-1 block text-[10px] font-normal text-amber-700">Barcode persistence requires the inventory metadata migration.</span>}
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Category
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Category"
                  className="modal-input"
                  onChange={(categoryId) => setForm((current) => ({ ...current, categoryId }))}
                  options={[
                    { value: '', label: 'Uncategorized' },
                    ...categories.filter((category) => category.is_active !== false).map((category) => ({ value: category.id, label: category.name })),
                  ]}
                  value={form.categoryId}
                />
              </span>
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Unit
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Unit"
                  className="modal-input"
                  onChange={(unitId) => setForm((current) => ({ ...current, unitId }))}
                  options={[
                    { value: '', label: 'Select unit' },
                    ...units.filter((unit) => unit.is_active !== false).map((unit) => ({ value: unit.id, label: `${unit.name} (${unit.abbreviation})` })),
                  ]}
                  value={form.unitId}
                />
              </span>
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Warehouse location
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Warehouse location"
                  className="modal-input"
                  onChange={(locationId) => setForm((current) => ({ ...current, locationId }))}
                  options={[
                    { value: '', label: 'Select warehouse' },
                    ...warehouses.filter((warehouse) => warehouse.isActive !== false).map((warehouse) => ({ value: warehouse.id, label: warehouse.name })),
                  ]}
                  value={form.locationId}
                />
              </span>
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Bin / zone <span className="font-normal text-slate-400">(optional)</span>
              <input className="modal-input mt-1.5" maxLength={80} name="binLocation" onChange={update} placeholder="e.g. A-02 · Bin 04" value={form.binLocation} />
              {!binLocationAvailable && <span className="mt-1 block text-[10px] font-normal text-amber-700">Bin and zone persistence requires the inventory metadata migration.</span>}
            </label>
            <label className="block text-xs font-medium text-slate-700">
              {item ? 'Current quantity at selected location' : 'Initial quantity'}
              <input className="modal-input mt-1.5" min="0" name="quantity" onChange={update} required step="0.01" type="number" value={form.quantity} />
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Minimum stock threshold
              <input className="modal-input mt-1.5" min="0" name="minimumStock" onChange={update} required step="0.01" type="number" value={form.minimumStock} />
            </label>
            <label className="block text-xs font-medium text-slate-700">
              Unit price
              <input className="modal-input mt-1.5" min="0" name="unitPrice" onChange={update} required step="0.01" type="number" value={form.unitPrice} />
            </label>
            <label className="block text-xs font-medium text-slate-700 sm:col-span-2">
              Notes <span className="font-normal text-slate-400">(optional)</span>
              <textarea className="modal-input mt-1.5 min-h-20 resize-y" maxLength={1000} name="notes" onChange={update} placeholder="Add helpful item details..." value={form.notes} />
            </label>
          </div>

          {error && <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2.5 text-xs text-rose-700" role="alert">{error}</p>}
          {units.filter((unit) => unit.is_active !== false).length === 0 && <p className="text-xs text-amber-700">No active units are available. Add a unit before saving inventory.</p>}
          <div className="flex flex-col-reverse gap-2 border-t border-slate-100 pt-4 sm:flex-row sm:justify-end">
            <button className="h-10 rounded-lg border border-slate-200 px-4 text-xs font-semibold text-slate-600 hover:bg-slate-50 disabled:opacity-50" disabled={pending} onClick={onClose} type="button">Cancel</button>
            <button className="h-10 rounded-lg bg-teal-600 px-5 text-xs font-semibold text-white transition hover:bg-teal-700 disabled:opacity-60" disabled={pending || !units.some((unit) => unit.is_active !== false) || !warehouses.some((warehouse) => warehouse.isActive !== false)} type="submit">
              {pending ? 'Saving…' : item ? 'Save changes' : 'Create inventory item'}
            </button>
          </div>
        </form>
      </section>
    </div>
  )
}
