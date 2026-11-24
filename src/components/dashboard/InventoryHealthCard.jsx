import { ArrowUpRight } from 'lucide-react'

const circumference = 2 * Math.PI * 35

function DonutChart({ inStock, lowStock, outOfStock }) {
  const inLength = (circumference * inStock) / 100
  const lowLength = (circumference * lowStock) / 100
  const outLength = (circumference * outOfStock) / 100

  return (
    <svg aria-label={`${inStock}% in stock, ${lowStock}% low stock, ${outOfStock}% out of stock`} className="h-[92px] w-[92px] -rotate-90" role="img" viewBox="0 0 84 84">
      <circle cx="42" cy="42" fill="none" r="35" stroke="#f1f5f9" strokeWidth="9" />
      <circle cx="42" cy="42" fill="none" r="35" stroke="#0f9f8f" strokeDasharray={`${inLength} ${circumference}`} strokeWidth="9" />
      <circle cx="42" cy="42" fill="none" r="35" stroke="#f59e0b" strokeDasharray={`${lowLength} ${circumference}`} strokeDashoffset={-inLength} strokeWidth="9" />
      <circle cx="42" cy="42" fill="none" r="35" stroke="#f43f5e" strokeDasharray={`${outLength} ${circumference}`} strokeDashoffset={-(inLength + lowLength)} strokeWidth="9" />
    </svg>
  )
}

export default function InventoryHealthCard({ data, items, onRestock }) {
  const { inStock, lowStock, outOfStock } = data.summary
  const topItems = items
    .filter((item) => item.quantity <= 0 || (item.minimumStock > 0 && item.quantity <= item.minimumStock))
    .sort((a, b) => a.quantity - b.quantity)
    .slice(0, 3)

  return (
    <section className="rounded-lg border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.02)]">
      <h2 className="text-[13px] font-semibold text-slate-800">Inventory Health &amp; Attention Required</h2>
      <p className="mt-1 text-[10px] text-slate-500">Stock distribution across all locations</p>

      <div className="mt-2 flex items-center gap-4">
        <div className="relative grid h-[100px] w-[100px] shrink-0 place-items-center">
          <DonutChart inStock={inStock} lowStock={lowStock} outOfStock={outOfStock} />
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-[20px] font-bold leading-5 text-slate-900">{inStock}%</span>
            <span className="mt-0.5 text-[8px] text-slate-500">In stock</span>
          </div>
        </div>
        <div className="min-w-0 flex-1 space-y-2">
          {[
            ['In Stock', inStock, 'bg-teal-600', 'text-slate-700'],
            ['Low Stock', lowStock, 'bg-amber-500', 'text-slate-700'],
            ['Out of Stock', outOfStock, 'bg-rose-500', 'text-slate-700'],
          ].map(([label, percent, swatch, color]) => (
            <div className="flex items-center gap-2 text-[10px]" key={label}>
              <span className={`h-1.5 w-1.5 rounded-[2px] ${swatch}`} />
              <span className={`flex-1 ${color}`}>{label}</span>
              <span className="font-semibold text-slate-800">{percent}%</span>
            </div>
          ))}
        </div>
      </div>

      <div className="mt-2 border-t border-slate-100 pt-2">
        <p className="mb-1.5 text-[8px] font-semibold uppercase tracking-wide text-slate-400">Top low-stock items</p>
        {topItems.length === 0 ? (
          <p className="py-2 text-[10px] text-slate-400">No low-stock items require attention.</p>
        ) : topItems.map((item) => (
          <div className="flex items-center gap-2 py-1 text-[9px]" key={item.id}>
            <span className="min-w-0 flex-1 truncate text-slate-700">{item.name}</span>
            <span className="whitespace-nowrap text-amber-700">{item.quantity} left</span>
            <button
              className="flex items-center gap-0.5 rounded bg-amber-50 px-1.5 py-1 font-semibold text-amber-700 hover:bg-amber-100"
              onClick={() => onRestock(item)}
              type="button"
            >
              Restock <ArrowUpRight size={9} />
            </button>
          </div>
        ))}
      </div>
    </section>
  )
}
