import { ArrowRight } from 'lucide-react'

function movementPresentation(type) {
  const normalized = String(type).toLowerCase()
  if (normalized === 'receipt' || normalized === 'return') {
    return { label: 'In', badge: 'bg-emerald-50 text-emerald-700', prefix: '+' }
  }
  if (normalized === 'issue') {
    return { label: 'Out', badge: 'bg-rose-50 text-rose-600', prefix: '−' }
  }
  return { label: 'Adjust', badge: 'bg-blue-50 text-blue-600', prefix: '+' }
}

function timeLabel(value) {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return '—'
  const localTime = new Date(date.getTime() - 4 * 60 * 60 * 1000)
  return new Intl.DateTimeFormat('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    timeZone: 'UTC',
  }).format(localTime)
}

export default function RecentMovements({ movements, onViewAll }) {
  return (
    <section className="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
      <header className="flex items-center justify-between gap-3 px-3.5 py-3">
        <h2 className="text-[13px] font-semibold text-slate-800">Recent Stock Movements</h2>
        <button className="flex items-center gap-1 whitespace-nowrap text-[9px] font-semibold text-teal-700 hover:text-teal-800" onClick={onViewAll} type="button">
          View all movements <ArrowRight size={10} />
        </button>
      </header>

      <div className="overflow-x-auto">
        <table className="w-full min-w-[560px] border-collapse text-left">
          <thead>
            <tr className="bg-slate-50 text-[9px] font-medium text-slate-500">
              <th className="px-3.5 py-2 font-medium">Item</th>
              <th className="px-2 py-2 font-medium">Type</th>
              <th className="px-2 py-2 font-medium">Qty</th>
              <th className="px-2 py-2 font-medium">Warehouse</th>
              <th className="px-3.5 py-2 text-right font-medium">Timestamp</th>
            </tr>
          </thead>
          <tbody>
            {movements.length === 0 ? (
              <tr><td className="px-3.5 py-7 text-center text-[10px] text-slate-400" colSpan={5}>No stock movements found.</td></tr>
            ) : movements.slice(0, 5).map((movement) => {
              const style = movementPresentation(movement.type)
              return (
                <tr className="border-t border-slate-100 text-[9px]" key={movement.id}>
                  <td className="px-3.5 py-2">
                    <p className="max-w-[155px] truncate font-medium text-slate-700">{movement.itemName}</p>
                    <p className="mt-0.5 text-[8px] text-slate-400">{movement.sku}</p>
                  </td>
                  <td className="px-2 py-2">
                    <span className={`inline-flex min-w-11 justify-center rounded px-2 py-1 text-[8px] font-semibold ${style.badge}`}>{style.label}</span>
                  </td>
                  <td className="whitespace-nowrap px-2 py-2 font-semibold text-slate-700">
                    {style.prefix}{Number(movement.quantity).toLocaleString('en-US')}
                  </td>
                  <td className="max-w-[125px] truncate px-2 py-2 text-slate-500">{movement.warehouseName}</td>
                  <td className="whitespace-nowrap px-3.5 py-2 text-right text-slate-500">{timeLabel(movement.occurredAt)}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </section>
  )
}
