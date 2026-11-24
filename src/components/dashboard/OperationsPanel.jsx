import { Activity, AlertTriangle, Download, Info, PackagePlus, SlidersHorizontal } from 'lucide-react'

function downloadCsv(movements) {
  const headers = ['Item', 'SKU', 'Type', 'Quantity', 'Warehouse', 'Timestamp']
  const rows = movements.map((movement) => [
    movement.itemName,
    movement.sku,
    movement.type,
    movement.quantity,
    movement.warehouseName,
    movement.occurredAt instanceof Date ? movement.occurredAt.toISOString() : movement.occurredAt,
  ])
  const escapeCell = (value) => `"${String(value ?? '').replaceAll('"', '""')}"`
  const csv = [headers, ...rows].map((row) => row.map(escapeCell).join(',')).join('\r\n')
  const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }))
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = 'invwise-stock-movements.csv'
  anchor.click()
  window.setTimeout(() => URL.revokeObjectURL(url), 1000)
}

export default function OperationsPanel({
  alerts,
  movements,
  onAddInventory,
  onAdjustStock,
  onViewSensors,
}) {
  return (
    <div className="space-y-3">
      <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
        <h2 className="text-[13px] font-semibold text-slate-800">Hardware &amp; System Alerts</h2>
        <div className="mt-2 space-y-1">
          {alerts.length === 0 ? (
            <p className="py-3 text-center text-[10px] text-slate-400">No active hardware alerts.</p>
          ) : alerts.slice(0, 3).map((alert) => {
            const warning = alert.severity === 'Warning'
            const Icon = warning ? AlertTriangle : Info
            return (
              <div className="flex items-center gap-2 rounded-md px-1 py-2" key={alert.id}>
                <span className={`grid h-6 w-6 shrink-0 place-items-center rounded-md ${warning ? 'bg-amber-50 text-amber-600' : 'bg-blue-50 text-blue-600'}`}>
                  <Icon size={13} />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="truncate text-[10px] font-medium text-slate-700">{alert.title}</p>
                  <p className="mt-0.5 truncate text-[9px] text-slate-400">{alert.subtitle}</p>
                </div>
                <span className={`rounded px-2 py-1 text-[8px] font-medium ${warning ? 'bg-amber-50 text-amber-700' : 'bg-blue-50 text-blue-700'}`}>
                  {alert.severity}
                </span>
              </div>
            )
          })}
        </div>
      </section>

      <section className="rounded-lg border border-slate-200 bg-white p-3.5 shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
        <h2 className="text-[12px] font-semibold text-slate-800">Quick Actions</h2>
        <div className="mt-2 grid grid-cols-2 gap-1.5">
          <button className="flex h-8 items-center gap-1.5 rounded border border-slate-200 px-2 text-left text-[9px] text-slate-600 hover:border-teal-300 hover:bg-teal-50/50" onClick={onAdjustStock} type="button">
            <SlidersHorizontal size={11} /> Adjust stock
          </button>
          <button className="flex h-8 items-center gap-1.5 rounded border border-slate-200 px-2 text-left text-[9px] text-slate-600 hover:border-teal-300 hover:bg-teal-50/50" onClick={onAddInventory} type="button">
            <PackagePlus size={11} /> Add inventory
          </button>
          <button className="flex h-8 items-center gap-1.5 rounded border border-slate-200 px-2 text-left text-[9px] text-slate-600 hover:border-teal-300 hover:bg-teal-50/50" onClick={() => downloadCsv(movements)} type="button">
            <Download size={11} /> Export report
          </button>
          <button className="flex h-8 items-center gap-1.5 rounded border border-slate-200 px-2 text-left text-[9px] text-slate-600 hover:border-teal-300 hover:bg-teal-50/50" onClick={onViewSensors} type="button">
            <Activity size={11} /> View sensors
          </button>
        </div>
      </section>
    </div>
  )
}
