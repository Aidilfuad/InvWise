import { Archive, ArrowUpDown, Eye, Package, Pencil, SlidersHorizontal } from 'lucide-react'

function getStatus(item, quantity = item.quantity) {
  if (quantity <= 0) return { label: 'Out of Stock', tone: 'rose', key: 'out' }
  if (quantity <= item.minimumStock) return { label: 'Low Stock', tone: 'amber', key: 'low' }
  return { label: 'In Stock', tone: 'emerald', key: 'in' }
}

function StatusBadge({ item, quantity }) {
  const status = getStatus(item, quantity)
  const tones = {
    rose: 'bg-rose-50 text-rose-700 ring-rose-100',
    amber: 'bg-amber-50 text-amber-700 ring-amber-100',
    emerald: 'bg-emerald-50 text-emerald-700 ring-emerald-100',
  }
  return <span className={`inline-flex items-center rounded-full px-2.5 py-1 text-[10px] font-semibold ring-1 ring-inset ${tones[status.tone]}`}>{status.label}</span>
}

function ProgressBar({ item, quantity }) {
  const status = getStatus(item, quantity)
  const percent = quantity <= 0
    ? 0
    : Math.min(100, Math.max(8, item.minimumStock > 0 ? (quantity / (item.minimumStock * 2)) * 100 : 100))
  const color = status.key === 'in' ? 'bg-emerald-500' : status.key === 'low' ? 'bg-amber-500' : 'bg-rose-400'
  return (
    <div aria-label={`${Math.round(percent)}% stock level`} className="mt-2 h-1.5 w-24 overflow-hidden rounded-full bg-slate-100">
      <span className={`block h-full rounded-full ${color}`} style={{ width: `${percent}%` }} />
    </div>
  )
}

function ItemMark({ item }) {
  const color = item.categoryName?.toLowerCase().includes('safety')
    ? 'bg-orange-50 text-orange-600'
    : item.categoryName?.toLowerCase().includes('hardware')
      ? 'bg-blue-50 text-blue-600'
      : item.categoryName?.toLowerCase().includes('clean')
        ? 'bg-violet-50 text-violet-600'
        : 'bg-teal-50 text-teal-700'
  return <span className={`grid h-9 w-9 shrink-0 place-items-center rounded-lg ${color}`}><Package size={16} strokeWidth={1.8} /></span>
}

function ActionButton({ label, onClick, children, danger = false }) {
  return (
    <button
      aria-label={label}
      className={`grid h-8 w-8 place-items-center rounded-lg transition ${danger ? 'text-slate-400 hover:bg-rose-50 hover:text-rose-600' : 'text-slate-500 hover:bg-teal-50 hover:text-teal-700'}`}
      onClick={(event) => {
        event.stopPropagation()
        onClick()
      }}
      title={label}
      type="button"
    >
      {children}
    </button>
  )
}

export default function InventoryTable({
  items,
  selectedIds,
  onSelect,
  onSelectAll,
  onAdjust,
  onView,
  onEdit,
  onArchive,
  currency,
  page,
  pageSize,
  totalItems,
  onPageChange,
  warehouseId,
  warehouses,
}) {
  const pageCount = Math.max(1, Math.ceil(totalItems / pageSize))
  const firstItem = totalItems === 0 ? 0 : (page - 1) * pageSize + 1
  const lastItem = Math.min(page * pageSize, totalItems)
  const allSelected = items.length > 0 && items.every((item) => selectedIds.has(item.id))

  return (
    <section className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 px-4 py-4 sm:px-5">
        <div className="flex items-center gap-2">
          <h2 className="text-sm font-bold text-slate-900">All inventory</h2>
          <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-semibold text-slate-600">{totalItems.toLocaleString()}</span>
        </div>
        <span className="flex items-center gap-1.5 text-[10px] text-slate-400"><span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />Updated just now</span>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[980px] text-left">
          <thead className="bg-slate-50/80">
            <tr className="text-[9px] font-semibold uppercase tracking-[0.08em] text-slate-500">
              <th className="w-10 px-4 py-3">
                <input aria-label="Select all items on this page" checked={allSelected} className="h-3.5 w-3.5 rounded border-slate-300 text-teal-600 focus:ring-teal-500" onChange={(event) => onSelectAll(items, event.target.checked)} type="checkbox" />
              </th>
              <th className="px-3 py-3">Item name / SKU</th>
              <th className="px-3 py-3">Category</th>
              <th className="px-3 py-3">Warehouse</th>
              <th className="px-3 py-3">Current stock</th>
              <th className="px-3 py-3">Unit price</th>
              <th className="px-3 py-3">Status</th>
              <th className="px-3 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {items.length === 0 ? (
              <tr><td className="px-6 py-12 text-center text-xs text-slate-500" colSpan={8}>No inventory items match these filters.</td></tr>
            ) : items.map((item) => {
              const selected = selectedIds.has(item.id)
              const quantity = warehouseId === 'all' ? item.quantity : Number(item.levels?.[warehouseId] ?? 0)
              const selectedWarehouse = warehouses.find((location) => location.id === warehouseId)
              const locationName = warehouseId === 'all' ? item.locationName || '—' : selectedWarehouse?.name || '—'
              const locationCode = warehouseId === 'all'
                ? item.binLocation || item.locationCode || ''
                : item.binLocations?.[warehouseId] || selectedWarehouse?.code || ''
              return (
                <tr className={`cursor-pointer transition hover:bg-slate-50/70 ${selected ? 'bg-teal-50/70' : ''}`} key={item.id} onClick={() => onAdjust(item)}>
                  <td className="px-4 py-3.5" onClick={(event) => event.stopPropagation()}>
                    <input
                      aria-label={`Select ${item.name} for adjustment`}
                      checked={selected}
                      className="h-3.5 w-3.5 rounded border-slate-300 text-teal-600 focus:ring-teal-500"
                      onChange={(event) => onSelect(item.id, event.target.checked)}
                      type="checkbox"
                    />
                  </td>
                  <td className="px-3 py-3.5">
                    <div className="flex min-w-[210px] items-center gap-3">
                      <ItemMark item={item} />
                      <div className="min-w-0">
                        <button className="block max-w-[220px] truncate text-left text-xs font-semibold text-slate-800 hover:text-teal-700" onClick={(event) => { event.stopPropagation(); onAdjust(item) }} type="button">{item.name}</button>
                        <p className="mt-0.5 text-[10px] text-slate-400">{item.sku}{item.barcode ? ` · ${item.barcode}` : ''}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-3 py-3.5"><span className="rounded-full bg-slate-100 px-2.5 py-1 text-[10px] text-slate-600">{item.categoryName || 'Uncategorized'}</span></td>
                  <td className="px-3 py-3.5">
                    <p className="text-xs font-medium text-slate-700">{locationName}</p>
                    <p className="mt-0.5 text-[10px] text-slate-400">{locationCode || '—'}</p>
                  </td>
                  <td className="px-3 py-3.5">
                    <p className="text-xs font-semibold text-slate-800">{Number(quantity).toLocaleString()} <span className="font-normal text-slate-500">{item.unitAbbreviation || 'units'}</span></p>
                    <ProgressBar item={item} quantity={quantity} />
                  </td>
                  <td className="px-3 py-3.5 text-xs font-medium text-slate-700">{currency(item.unitPrice)}</td>
                  <td className="px-3 py-3.5"><StatusBadge item={item} quantity={quantity} /></td>
                  <td className="px-3 py-3.5">
                    <div className="flex justify-end gap-0.5">
                      <ActionButton label={`Adjust ${item.name}`} onClick={() => onAdjust(item)}><SlidersHorizontal size={15} /></ActionButton>
                      <ActionButton label={`View ${item.name}`} onClick={() => onView(item)}><Eye size={15} /></ActionButton>
                      <ActionButton label={`Edit ${item.name}`} onClick={() => onEdit(item)}><Pencil size={14} /></ActionButton>
                      <ActionButton danger label={`Archive ${item.name}`} onClick={() => onArchive(item)}><Archive size={14} /></ActionButton>
                    </div>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      <footer className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 px-4 py-3.5 sm:px-5">
        <p className="text-[10px] text-slate-500">Showing <span className="font-semibold text-slate-700">{firstItem}–{lastItem}</span> of <span className="font-semibold text-slate-700">{totalItems.toLocaleString()}</span> items</p>
        <div aria-label="Inventory pagination" className="flex items-center gap-1">
          <button className="h-8 rounded-md border border-slate-200 px-2.5 text-[10px] font-medium text-slate-600 disabled:cursor-not-allowed disabled:opacity-40" disabled={page <= 1} onClick={() => onPageChange(page - 1)} type="button">Previous</button>
          <span className="px-2 text-[10px] text-slate-500"><ArrowUpDown className="mr-1 inline-block" size={11} />Page {page} of {pageCount}</span>
          <button className="h-8 rounded-md border border-slate-200 px-2.5 text-[10px] font-medium text-slate-600 disabled:cursor-not-allowed disabled:opacity-40" disabled={page >= pageCount} onClick={() => onPageChange(page + 1)} type="button">Next</button>
        </div>
      </footer>
    </section>
  )
}
