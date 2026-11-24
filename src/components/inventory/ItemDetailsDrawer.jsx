import { useEffect, useState } from 'react'
import { ArrowDownToLine, ArrowLeftRight, ArrowUpFromLine, CalendarClock, Package, Pencil, X } from 'lucide-react'
import { isSupabaseConfigured, supabase } from '../../lib/supabase'

function movementIcon(type) {
  if (type === 'receipt' || type === 'return') return <ArrowDownToLine size={14} className="text-emerald-600" />
  if (type === 'transfer') return <ArrowLeftRight size={14} className="text-blue-600" />
  return <ArrowUpFromLine size={14} className="text-rose-600" />
}

export default function ItemDetailsDrawer({ item, warehouses, movements, currency, onClose, onEdit }) {
  const [history, setHistory] = useState([])
  const [loadingHistory, setLoadingHistory] = useState(false)
  const [historyError, setHistoryError] = useState('')

  useEffect(() => {
    let active = true

    async function loadHistory() {
      if (!item) return
      if (!isSupabaseConfigured || !supabase || item.id.startsWith('seed-') || item.id.startsWith('local-')) {
        setHistory(movements.filter((movement) => movement.itemId === item.id).slice(0, 5))
        return
      }
      setHistory([])
      setLoadingHistory(true)
      setHistoryError('')
      try {
        const { data, error } = await supabase
          .from('stock_movements')
          .select('id,movement_type,quantity,source_location_id,destination_location_id,reference,notes,occurred_at')
          .eq('item_id', item.id)
          .order('occurred_at', { ascending: false })
          .limit(5)
        if (error) throw error
        if (!active) return
        setHistory((data ?? []).map((movement) => {
          const source = warehouses.find((location) => location.id === movement.source_location_id)?.name
          const destination = warehouses.find((location) => location.id === movement.destination_location_id)?.name
          return {
            ...movement,
            type: movement.movement_type,
            occurredAt: movement.occurred_at,
            warehouseName: source && destination ? `${source} → ${destination}` : source ?? destination ?? '—',
          }
        }))
      } catch (error) {
        if (active) setHistoryError(error instanceof Error ? error.message : 'Unable to load movement history.')
      } finally {
        if (active) setLoadingHistory(false)
      }
    }

    void loadHistory()
    return () => {
      active = false
    }
  }, [item, movements, warehouses])

  if (!item) return null

  const locations = Object.entries(item.levels ?? {})

  return (
    <div className="fixed inset-0 z-[65] bg-slate-950/35" onMouseDown={(event) => {
      if (event.target === event.currentTarget) onClose()
    }}>
      <aside aria-labelledby="item-details-title" aria-modal="true" className="absolute inset-y-0 right-0 flex w-full max-w-[440px] flex-col bg-white shadow-2xl" role="dialog">
        <div className="flex items-start justify-between border-b border-slate-100 px-5 py-5 sm:px-6">
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.14em] text-teal-700">Inventory item</p>
            <h2 className="mt-1.5 text-lg font-bold text-slate-900" id="item-details-title">Item details</h2>
          </div>
          <button aria-label="Close item details" className="rounded-lg p-2 text-slate-400 hover:bg-slate-100" onClick={onClose} type="button"><X size={18} /></button>
        </div>

        <div className="flex-1 space-y-5 overflow-y-auto px-5 py-5 sm:px-6">
          <div className="flex items-center gap-3 rounded-xl border border-slate-200 p-4">
            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-teal-50 text-teal-700"><Package size={20} /></span>
            <div className="min-w-0 flex-1">
              <h3 className="truncate text-sm font-bold text-slate-900">{item.name}</h3>
              <p className="mt-1 text-[11px] text-slate-500">{item.sku}{item.barcode ? ` · ${item.barcode}` : ''}</p>
            </div>
            <button className="flex h-8 items-center gap-1.5 rounded-lg border border-slate-200 px-2.5 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" onClick={() => onEdit(item)} type="button"><Pencil size={12} />Edit</button>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {[
              ['Category', item.categoryName || 'Uncategorized'],
              ['Unit', `${item.unitName || 'Unit'} (${item.unitAbbreviation || 'ea'})`],
              ['Minimum stock', `${item.minimumStock} ${item.unitAbbreviation || ''}`],
              ['Unit price', currency(item.unitPrice)],
            ].map(([label, value]) => (
              <div className="rounded-xl bg-slate-50 p-3" key={label}>
                <p className="text-[10px] text-slate-500">{label}</p>
                <p className="mt-1 text-xs font-semibold text-slate-800">{value}</p>
              </div>
            ))}
          </div>

          <section>
            <div className="mb-2 flex items-center justify-between">
              <h3 className="text-xs font-bold text-slate-900">Stock distribution</h3>
              <span className="text-[10px] text-slate-500">{Number(item.quantity).toLocaleString()} total</span>
            </div>
            <div className="divide-y divide-slate-100 rounded-xl border border-slate-200 px-3">
              {locations.length === 0 ? <p className="py-3 text-xs text-slate-500">No stock has been assigned to a warehouse.</p> : locations.map(([locationId, quantity]) => {
                const warehouse = warehouses.find((location) => location.id === locationId)
                return (
                  <div className="flex items-center justify-between gap-3 py-3" key={locationId}>
                    <div className="min-w-0">
                      <p className="truncate text-xs font-medium text-slate-800">{warehouse?.name ?? 'Warehouse'}</p>
                      <p className="mt-0.5 text-[10px] text-slate-400">{item.binLocations?.[locationId] || warehouse?.code || '—'}</p>
                    </div>
                    <p className="text-xs font-semibold text-slate-800">{Number(quantity).toLocaleString()} {item.unitAbbreviation || 'units'}</p>
                  </div>
                )
              })}
            </div>
          </section>

          {item.notes && (
            <section>
              <h3 className="mb-2 text-xs font-bold text-slate-900">Notes</h3>
              <p className="rounded-xl bg-slate-50 p-3 text-xs leading-5 text-slate-600">{item.notes}</p>
            </section>
          )}

          <section>
            <div className="mb-2 flex items-center gap-2">
              <CalendarClock className="text-slate-400" size={14} />
              <h3 className="text-xs font-bold text-slate-900">Recent stock movements</h3>
            </div>
            {loadingHistory ? <p className="py-3 text-xs text-slate-500">Loading movement history…</p> : historyError ? (
              <p className="rounded-lg bg-amber-50 px-3 py-2 text-[10px] text-amber-800">{historyError}</p>
            ) : history.length === 0 ? (
              <p className="rounded-xl border border-dashed border-slate-200 px-3 py-5 text-center text-xs text-slate-500">No stock movements recorded yet.</p>
            ) : (
              <div className="divide-y divide-slate-100 rounded-xl border border-slate-200 px-3">
                {history.map((movement) => (
                  <div className="flex items-start gap-2.5 py-3" key={movement.id}>
                    <span className="mt-0.5 grid h-6 w-6 shrink-0 place-items-center rounded-md bg-slate-50">{movementIcon(movement.type)}</span>
                    <div className="min-w-0 flex-1">
                      <p className="text-[11px] font-semibold capitalize text-slate-800">{movement.type} · {Number(movement.quantity).toLocaleString()} {item.unitAbbreviation}</p>
                      <p className="mt-0.5 truncate text-[10px] text-slate-500">{movement.warehouseName || '—'}{movement.reference ? ` · ${movement.reference}` : ''}</p>
                    </div>
                    <time className="shrink-0 text-[9px] text-slate-400">{new Date(movement.occurredAt ?? movement.occurred_at).toLocaleDateString()}</time>
                  </div>
                ))}
              </div>
            )}
          </section>
        </div>
      </aside>
    </div>
  )
}
