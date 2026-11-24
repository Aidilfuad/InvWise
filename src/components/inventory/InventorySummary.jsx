import { AlertTriangle, Box, ChartNoAxesCombined, PackageCheck } from 'lucide-react'

function MetricCard({ Icon, label, value, detail, tone, badge }) {
  const tones = {
    teal: 'bg-teal-50 text-teal-700',
    blue: 'bg-blue-50 text-blue-700',
    amber: 'bg-amber-50 text-amber-700',
    rose: 'bg-rose-50 text-rose-700',
  }

  return (
    <article className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-medium text-slate-500">{label}</p>
          <p className="mt-2 text-[25px] font-bold leading-none tracking-[-0.04em] text-slate-900">{value}</p>
        </div>
        <span className={`grid h-10 w-10 shrink-0 place-items-center rounded-xl ${tones[tone]}`}>
          <Icon size={18} strokeWidth={1.8} />
        </span>
      </div>
      <div className="mt-3 flex items-center gap-2 text-[11px]">
        {badge && <span className={`rounded-full px-2 py-0.5 font-semibold ${tones[tone]}`}>{badge}</span>}
        <span className="text-slate-500">{detail}</span>
      </div>
    </article>
  )
}

export default function InventorySummary({ currency, data }) {
  const lowStock = data.items.filter((item) => item.quantity > 0 && item.quantity <= item.minimumStock).length
  const outOfStock = data.items.filter((item) => item.quantity <= 0).length

  return (
    <section aria-label="Inventory summary" className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <MetricCard
        Icon={Box}
        label="Total Catalog Items"
        value={Number(data.summary.totalSkus || data.items.length).toLocaleString()}
        detail={data.source === 'live' ? 'Active items in your catalog' : '+24 this month'}
        tone="teal"
      />
      <MetricCard
        Icon={ChartNoAxesCombined}
        label="Total Valuation"
        value={currency(data.summary.totalStockValue, 0)}
        detail="Across all warehouses"
        tone="blue"
      />
      <MetricCard
        Icon={AlertTriangle}
        label="Low Stock Items"
        value={Math.max(lowStock, data.source === 'live' ? 0 : data.summary.lowStockAlerts).toLocaleString()}
        detail="Needs replenishment"
        tone="amber"
        badge="Low"
      />
      <MetricCard
        Icon={PackageCheck}
        label="Out of Stock"
        value={outOfStock.toLocaleString()}
        detail="Action required"
        tone="rose"
        badge="Empty"
      />
    </section>
  )
}
