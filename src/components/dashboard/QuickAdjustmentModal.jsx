import { useState } from 'react'
import { ArrowDownToLine, ArrowUpFromLine, X } from 'lucide-react'

export default function QuickAdjustmentModal({
  items,
  locations,
  onClose,
  onSubmit,
  presetItem,
}) {
  const [itemId, setItemId] = useState(presetItem?.id ?? items[0]?.id ?? '')
  const [locationId, setLocationId] = useState('')
  const [direction, setDirection] = useState('add')
  const [quantity, setQuantity] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const activeItemId = items.some((item) => item.id === itemId)
    ? itemId
    : items.some((item) => item.id === presetItem?.id)
      ? presetItem.id
      : items[0]?.id ?? ''
  const selectedItem = items.find((item) => item.id === activeItemId)
  const activeLocationId = locations.some((location) => location.id === locationId)
    ? locationId
    : (selectedItem
      ? locations.find((location) => Object.hasOwn(selectedItem.levels, location.id))?.id
      : null) ?? locations[0]?.id ?? ''

  async function submit(event) {
    event.preventDefault()
    const numericQuantity = Number(quantity)
    if (!activeItemId || !activeLocationId || !Number.isFinite(numericQuantity) || numericQuantity <= 0) {
      setError('Choose an item and warehouse, then enter a quantity greater than zero.')
      return
    }
    const currentQuantity = Number(selectedItem?.levels[activeLocationId] ?? 0)
    if (direction === 'remove' && numericQuantity > currentQuantity) {
      setError(`Only ${currentQuantity} units are available at this warehouse.`)
      return
    }

    setLoading(true)
    setError('')
    try {
      await onSubmit({
        itemId: activeItemId,
        locationId: activeLocationId,
        quantity: numericQuantity,
        add: direction === 'add',
        notes,
      })
      onClose()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to save the stock adjustment.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[70] flex items-center justify-center bg-slate-950/45 p-4" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !loading) onClose()
    }}>
      <section aria-labelledby="quick-adjustment-title" aria-modal="true" className="w-full max-w-md rounded-xl border border-slate-200 bg-white p-5 shadow-2xl sm:p-6" role="dialog">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-[9px] font-semibold uppercase tracking-[0.14em] text-teal-700">Inventory operations</p>
            <h2 className="mt-1.5 text-lg font-bold text-slate-900" id="quick-adjustment-title">Quick Stock Adjustment</h2>
            <p className="mt-1 text-[11px] text-slate-500">Record stock received or issued from a warehouse.</p>
          </div>
          <button aria-label="Close dialog" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700" onClick={onClose} type="button"><X size={16} /></button>
        </div>

        <form className="mt-5 space-y-3.5" onSubmit={submit}>
          <label className="block text-[10px] font-medium text-slate-700">
            Inventory item
            <select className="modal-input mt-1.5" onChange={(event) => setItemId(event.target.value)} required value={activeItemId}>
              <option disabled value="">Select an item</option>
              {items.map((item) => <option key={item.id} value={item.id}>{item.name} · {item.sku}</option>)}
            </select>
          </label>

          <label className="block text-[10px] font-medium text-slate-700">
            Warehouse
            <select className="modal-input mt-1.5" onChange={(event) => setLocationId(event.target.value)} required value={activeLocationId}>
              <option disabled value="">Select a warehouse</option>
              {locations.map((location) => <option key={location.id} value={location.id}>{location.name}</option>)}
            </select>
          </label>

          <div>
            <p className="mb-1.5 text-[10px] font-medium text-slate-700">Adjustment type</p>
            <div className="grid grid-cols-2 gap-2">
              <button
                aria-pressed={direction === 'add'}
                className={`flex h-9 items-center justify-center gap-1.5 rounded-md border text-[10px] font-semibold ${
                  direction === 'add' ? 'border-emerald-200 bg-emerald-50 text-emerald-700' : 'border-slate-200 text-slate-500'
                }`}
                onClick={() => setDirection('add')}
                type="button"
              >
                <ArrowDownToLine size={13} /> Add stock
              </button>
              <button
                aria-pressed={direction === 'remove'}
                className={`flex h-9 items-center justify-center gap-1.5 rounded-md border text-[10px] font-semibold ${
                  direction === 'remove' ? 'border-rose-200 bg-rose-50 text-rose-700' : 'border-slate-200 text-slate-500'
                }`}
                onClick={() => setDirection('remove')}
                type="button"
              >
                <ArrowUpFromLine size={13} /> Remove stock
              </button>
            </div>
          </div>

          {selectedItem && activeLocationId && (
            <p className="text-[9px] text-slate-500">
              Available at this warehouse: <span className="font-semibold text-slate-700">{selectedItem.levels[activeLocationId] ?? 0}</span>
            </p>
          )}

          <label className="block text-[10px] font-medium text-slate-700">
            Quantity
            <input autoFocus className="modal-input mt-1.5" min="0.01" onChange={(event) => setQuantity(event.target.value)} placeholder="Enter quantity" required step="0.01" type="number" value={quantity} />
          </label>
          <label className="block text-[10px] font-medium text-slate-700">
            Notes <span className="font-normal text-slate-400">(optional)</span>
            <input className="modal-input mt-1.5" maxLength={240} onChange={(event) => setNotes(event.target.value)} placeholder="Reason or reference" value={notes} />
          </label>

          {error && <p className="rounded-md border border-rose-100 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          <div className="flex gap-2 pt-1">
            <button className="h-9 flex-1 rounded-md border border-slate-200 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" disabled={loading} onClick={onClose} type="button">Cancel</button>
            <button className="h-9 flex-1 rounded-md bg-teal-600 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={loading || items.length === 0 || locations.length === 0} type="submit">
              {loading ? 'Saving...' : 'Save adjustment'}
            </button>
          </div>
        </form>
      </section>
    </div>
  )
}
