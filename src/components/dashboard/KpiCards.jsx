import { Boxes, DollarSign, TriangleAlert, Warehouse } from 'lucide-react'

function formatCurrency(value, currencyCode, exchangeRateUsdMyr, live) {
  const code = currencyCode || 'USD'
  const rate = exchangeRateUsdMyr > 0 ? exchangeRateUsdMyr : 4.25
  const converted = live && code === 'USD' ? value / rate : value
  const locale = code === 'MYR' ? 'en-MY' : 'en-US'
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: code,
      maximumFractionDigits: 0,
    }).format(converted)
  } catch (error) {
    if (!(error instanceof RangeError)) throw error
    return `${code} ${Math.round(converted).toLocaleString('en-US')}`
  }
}

export default function KpiCards({ data, warehouseId }) {
  const filteredItems = warehouseId === 'all'
    ? data.items
    : data.items.filter((item) => Number(item.levels[warehouseId] ?? 0) > 0)
  const stockValue = warehouseId === 'all'
    ? data.summary.totalStockValue
    : filteredItems.reduce((sum, item) => sum + Number(item.levels[warehouseId] ?? 0) * item.unitPrice, 0)
  const lowStock = warehouseId === 'all'
    ? data.summary.lowStockAlerts
    : filteredItems.filter((item) => Number(item.levels[warehouseId] ?? 0) <= item.minimumStock).length

  const cards = [
    {
      label: 'Total Stock Value',
      value: formatCurrency(stockValue, data.currencyCode, data.exchangeRateUsdMyr, data.live),
      icon: DollarSign,
      iconColor: 'text-emerald-600',
      iconBg: 'bg-emerald-50',
      footer: <><span className="rounded bg-emerald-50 px-1.5 py-0.5 text-[9px] font-semibold text-emerald-700">+12.4%</span><span className="text-[9px] text-slate-400">vs. last month</span></>,
    },
    {
      label: 'Total SKUs',
      value: warehouseId === 'all' ? data.summary.totalSkus.toLocaleString('en-US') : filteredItems.length.toLocaleString('en-US'),
      icon: Boxes,
      iconColor: 'text-blue-600',
      iconBg: 'bg-blue-50',
      footer: <><span className="text-[10px] font-medium text-slate-700">items</span><span className="text-[9px] text-slate-400">Across all warehouses</span></>,
    },
    {
      label: 'Low Stock Alerts',
      value: lowStock.toLocaleString('en-US'),
      icon: TriangleAlert,
      iconColor: 'text-amber-600',
      iconBg: 'bg-amber-50',
      footer: <><span className="rounded bg-amber-50 px-1.5 py-0.5 text-[9px] font-semibold text-amber-700">items</span><span className="text-[9px] text-slate-400">Need replenishment</span></>,
    },
    {
      label: 'Active Warehouses',
      value: data.summary.activeWarehouses.toLocaleString('en-US'),
      icon: Warehouse,
      iconColor: 'text-teal-600',
      iconBg: 'bg-teal-50',
      footer: <><span className="h-1.5 w-1.5 rounded-full bg-emerald-500" /><span className="text-[9px] font-medium text-emerald-700">All locations connected</span></>,
      suffix: <span className="text-[10px] font-medium text-emerald-600">online</span>,
    },
  ]

  return (
    <section aria-label="Inventory key performance indicators" className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
      {cards.map(({ label, value, icon: Icon, iconColor, iconBg, footer, suffix }) => (
        <article className="min-h-[104px] rounded-lg border border-slate-200 bg-white px-4 py-3.5 shadow-[0_1px_2px_rgba(15,23,42,0.02)]" key={label}>
          <div className="flex items-start justify-between">
            <p className="text-[10px] font-medium text-slate-500">{label}</p>
            <span className={`grid h-8 w-8 place-items-center rounded-md ${iconBg} ${iconColor}`}>
              <Icon size={16} strokeWidth={2} />
            </span>
          </div>
          <div className="mt-[-3px] flex items-baseline gap-2">
            <p className="text-[24px] font-bold leading-8 tracking-[-0.03em] text-slate-900">{value}</p>
            {suffix}
          </div>
          <div className="mt-0.5 flex items-center gap-1.5">{footer}</div>
        </article>
      ))}
    </section>
  )
}
