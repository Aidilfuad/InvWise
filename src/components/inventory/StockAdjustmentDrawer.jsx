import { useMemo, useState } from 'react'
import { ArrowDownToLine, ArrowLeftRight, ArrowUpFromLine, Check, Minus, Package, Plus, X } from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'

const reasons = [
  'Purchase order received',
  'Customer order fulfillment',
  'Cycle count correction',
  'Damaged / Expired goods',
  'Warehouse transfer',
]

function QuantityField({ value, onChange }) {
  const parsed = Number(value)
  return (
    <div className="flex h-12 items-center overflow-hidden rounded-xl border border-slate-200 bg-white">
      <button aria-label="Decrease quantity" className="grid h-full w-12 place-items-center border-r border-slate-100 text-slate-500 hover:bg-slate-50" onClick={() => onChange(String(Math.max(0, (Number.isFinite(parsed) ? parsed : 0) - 1)))} type="button"><Minus size={15} /></button>
      <input aria-label="Adjustment quantity" className="h-full min-w-0 flex-1 border-0 bg-transparent text-center text-sm font-semibold text-slate-800 outline-none focus:ring-0" min="0" onChange={(event) => onChange(event.target.value)} step="1" type="number" value={value} />
      <span className="pr-3 text-[10px] text-slate-400">units</span>
      <button aria-label="Increase quantity" className="grid h-full w-12 place-items-center border-l border-slate-100 text-slate-500 hover:bg-slate-50" onClick={() => onChange(String((Number.isFinite(parsed) ? parsed : 0) + 1))} type="button"><Plus size={15} /></button>
    </div>
  )
}

function LocationSelect({ label, locations, value, onChange, excludeId }) {
  return (
    <label className="block text-xs font-medium text-slate-700">
      {label}
      <span className="mt-1.5 block">
        <SearchableSelect
          aria-label={label}
          className="modal-input h-10"
          onChange={onChange}
          options={[
            { value: '', label: 'Select warehouse' },
            ...locations.filter((location) => location.isActive !== false && location.id !== excludeId).map((location) => ({ value: location.id, label: location.name })),
          ]}
          value={value}
        />
      </span>
    </label>
  )
}

export default function StockAdjustmentDrawer({ items, locations, selectedItem, onClose, onSubmit }) {
  const [itemId, setItemId] = useState(selectedItem?.id ?? items[0]?.id ?? '')
  const [mode, setMode] = useState('stock-in')
  const [operation, setOperation] = useState('transfer')
  const [direction, setDirection] = useState('add')
  const [locationId, setLocationId] = useState(selectedItem?.locationId ?? locations[0]?.id ?? '')
  const [destinationLocationId, setDestinationLocationId] = useState('')
  const [quantity, setQuantity] = useState('1')
  const [reason, setReason] = useState(reasons[0])
  const [notes, setNotes] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')

  const activeItem = useMemo(() => items.find((item) => item.id === itemId) ?? null, [items, itemId])

  const transferMode = mode === 'transfer-adjust' && operation === 'transfer'
  const isDecrease = mode === 'stock-out' || (mode === 'transfer-adjust' && operation === 'adjust' && direction === 'remove')
  const sourceLocationId = mode === 'stock-out' || (mode === 'transfer-adjust' && operation === 'adjust' && direction === 'remove')
    ? locationId
    : transferMode ? locationId : null
  const targetLocationId = mode === 'stock-in' || (mode === 'transfer-adjust' && operation === 'adjust' && direction === 'add')
    ? locationId
    : transferMode ? destinationLocationId : null
  const currentAtLocation = Number(activeItem?.levels?.[locationId] ?? 0)
  const numericQuantity = Number(quantity)
  const totalAfter = activeItem
    ? Math.max(0, activeItem.quantity + (transferMode ? 0 : isDecrease ? -numericQuantity : numericQuantity))
    : 0
  const validQuantity = Number.isFinite(numericQuantity) && numericQuantity > 0
  const enoughStock = !isDecrease || numericQuantity <= currentAtLocation
  const validLocations = Boolean(locationId) && (!transferMode || Boolean(destinationLocationId && destinationLocationId !== locationId))

  async function submit(event) {
    event.preventDefault()
    if (!activeItem || !validQuantity || !validLocations) {
      setError('Choose an item and warehouse, then enter a quantity greater than zero.')
      return
    }
    if (!enoughStock) {
      setError(`Only ${currentAtLocation} units are available at this warehouse.`)
      return
    }

    setPending(true)
    setError('')
    try {
      await onSubmit({
        itemId: activeItem.id,
        mode: mode === 'transfer-adjust'
          ? operation === 'transfer' ? 'transfer' : 'adjustment'
          : mode,
        direction,
        quantity: numericQuantity,
        locationId: sourceLocationId ?? targetLocationId,
        destinationLocationId: transferMode ? destinationLocationId : null,
        reason,
        notes,
      })
      onClose()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to save this stock adjustment.')
    } finally {
      setPending(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[70] bg-slate-950/35" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !pending) onClose()
    }}>
      <aside aria-labelledby="stock-adjustment-title" aria-modal="true" className="absolute inset-y-0 right-0 flex w-full max-w-[440px] flex-col bg-white shadow-2xl" role="dialog">
        <div className="flex items-start justify-between border-b border-slate-100 px-5 py-5 sm:px-6">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-teal-700">Inventory operations</p>
            <h2 className="mt-1.5 text-lg font-bold text-slate-900" id="stock-adjustment-title">Quick Stock Adjustment</h2>
            <p className="mt-1 text-xs text-slate-500">Update stock without leaving your inventory.</p>
          </div>
          <button aria-label="Close adjustment drawer" className="rounded-lg p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-700" disabled={pending} onClick={onClose} type="button"><X size={18} /></button>
        </div>

        <form className="flex min-h-0 flex-1 flex-col" onSubmit={submit}>
          <div className="flex-1 space-y-5 overflow-y-auto px-5 py-5 sm:px-6">
            {!selectedItem && (
              <label className="block text-xs font-medium text-slate-700">
                Select inventory item
                <span className="mt-1.5 block">
                  <SearchableSelect
                    aria-label="Select inventory item"
                    className="modal-input h-10"
                    onChange={setItemId}
                    options={[
                      { value: '', label: 'Select an item' },
                      ...items.map((item) => ({ value: item.id, label: `${item.name} · ${item.sku}` })),
                    ]}
                    value={itemId}
                  />
                </span>
              </label>
            )}

            {activeItem && (
              <div className="flex items-center gap-3 rounded-xl border border-slate-200 bg-slate-50/80 p-3.5">
                <span className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-teal-50 text-teal-700"><Package size={19} /></span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-xs font-semibold text-slate-900">{activeItem.name}</p>
                  <p className="mt-0.5 text-[10px] text-slate-500">{activeItem.sku}</p>
                </div>
                <div className="text-right">
                  <p className="text-sm font-bold text-slate-900">{Number(activeItem.quantity).toLocaleString()}</p>
                  <p className="text-[9px] text-slate-500">on hand</p>
                </div>
              </div>
            )}

            <div className="grid grid-cols-3 gap-1 rounded-xl bg-slate-100 p-1">
              {[
                { id: 'stock-in', label: 'Stock In', Icon: ArrowDownToLine },
                { id: 'stock-out', label: 'Stock Out', Icon: ArrowUpFromLine },
                { id: 'transfer-adjust', label: 'Transfer / Adjust', Icon: ArrowLeftRight },
              ].map(({ id, label, Icon }) => (
                <button aria-pressed={mode === id} className={`flex h-9 items-center justify-center gap-1 rounded-lg px-1 text-[10px] font-semibold transition ${mode === id ? 'bg-white text-teal-700 shadow-sm' : 'text-slate-500 hover:text-slate-700'}`} key={id} onClick={() => { setMode(id); setError('') }} type="button">
                  <Icon size={13} />{label}
                </button>
              ))}
            </div>

            {mode === 'transfer-adjust' && (
              <div className="grid grid-cols-2 gap-2">
                <button aria-pressed={operation === 'transfer'} className={`h-9 rounded-lg border text-[11px] font-semibold ${operation === 'transfer' ? 'border-teal-200 bg-teal-50 text-teal-700' : 'border-slate-200 text-slate-500'}`} onClick={() => { setOperation('transfer'); setError('') }} type="button">Transfer</button>
                <button aria-pressed={operation === 'adjust'} className={`h-9 rounded-lg border text-[11px] font-semibold ${operation === 'adjust' ? 'border-teal-200 bg-teal-50 text-teal-700' : 'border-slate-200 text-slate-500'}`} onClick={() => { setOperation('adjust'); setError('') }} type="button">Cycle-count adjustment</button>
              </div>
            )}

            {mode === 'transfer-adjust' && operation === 'adjust' && (
              <div className="grid grid-cols-2 gap-2">
                <button aria-pressed={direction === 'add'} className={`flex h-9 items-center justify-center gap-1.5 rounded-lg border text-[11px] font-semibold ${direction === 'add' ? 'border-emerald-200 bg-emerald-50 text-emerald-700' : 'border-slate-200 text-slate-500'}`} onClick={() => setDirection('add')} type="button"><Plus size={13} />Add</button>
                <button aria-pressed={direction === 'remove'} className={`flex h-9 items-center justify-center gap-1.5 rounded-lg border text-[11px] font-semibold ${direction === 'remove' ? 'border-rose-200 bg-rose-50 text-rose-700' : 'border-slate-200 text-slate-500'}`} onClick={() => setDirection('remove')} type="button"><Minus size={13} />Remove</button>
              </div>
            )}

            <div>
              <p className="mb-1.5 text-xs font-medium text-slate-700">Quantity</p>
              <QuantityField onChange={setQuantity} value={quantity} />
            </div>

            {transferMode ? (
              <div className="grid gap-3">
                <LocationSelect label="Source warehouse" locations={locations} onChange={setLocationId} value={locationId} />
                <LocationSelect excludeId={locationId} label="Destination warehouse" locations={locations} onChange={setDestinationLocationId} value={destinationLocationId} />
                {activeItem && <p className="-mt-1 text-[10px] text-slate-500">Available at source: <span className="font-semibold text-slate-700">{currentAtLocation} {activeItem.unitAbbreviation}</span></p>}
              </div>
            ) : (
              <div>
                <LocationSelect label={mode === 'stock-out' || (mode === 'transfer-adjust' && direction === 'remove') ? 'Warehouse' : 'Destination warehouse'} locations={locations} onChange={setLocationId} value={locationId} />
                {activeItem && <p className="mt-1.5 text-[10px] text-slate-500">Available at this warehouse: <span className="font-semibold text-slate-700">{currentAtLocation} {activeItem.unitAbbreviation}</span></p>}
              </div>
            )}

            <label className="block text-xs font-medium text-slate-700">
              Reason code
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Reason code"
                  className="modal-input h-10"
                  onChange={setReason}
                  options={reasons.map((value) => ({ value, label: value }))}
                  value={reason}
                />
              </span>
            </label>

            <label className="block text-xs font-medium text-slate-700">
              Notes <span className="font-normal text-slate-400">(optional)</span>
              <textarea className="modal-input mt-1.5 min-h-20 resize-y" maxLength={500} onChange={(event) => setNotes(event.target.value)} placeholder="Add a reference or note..." value={notes} />
            </label>

            <div className="flex items-center justify-between gap-3 rounded-xl bg-teal-50/80 px-3.5 py-3">
              <span className="text-[11px] font-medium text-slate-600">Stock after adjustment</span>
              <span className="text-xs font-bold text-slate-900">
                {activeItem ? `${Number(activeItem.quantity).toLocaleString()} → ${totalAfter.toLocaleString()} ${activeItem.unitAbbreviation || 'units'}` : '—'}
              </span>
            </div>

            {isDecrease && validQuantity && !enoughStock && <p className="text-[11px] text-rose-700">This adjustment cannot exceed the available quantity at the selected warehouse.</p>}
            {error && <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2.5 text-xs text-rose-700" role="alert">{error}</p>}
          </div>

          <div className="border-t border-slate-100 px-5 py-4 sm:px-6">
            <button className="flex h-11 w-full items-center justify-center gap-2 rounded-xl bg-teal-600 text-xs font-semibold text-white transition hover:bg-teal-700 disabled:cursor-not-allowed disabled:opacity-50" disabled={pending || !activeItem || !validQuantity || !validLocations || !enoughStock} type="submit">
              {pending ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" /> : <Check size={15} />}
              {pending ? 'Saving adjustment…' : 'Confirm Adjustment'}
            </button>
            <p className="mt-2 text-center text-[10px] text-slate-400">All adjustments are saved to the activity log.</p>
          </div>
        </form>
      </aside>
    </div>
  )
}
