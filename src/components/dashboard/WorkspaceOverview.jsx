import { ChevronDown, Warehouse } from 'lucide-react'

export default function WorkspaceOverview({
  dateRange,
  live,
  onDateRangeChange,
  onWarehouseChange,
  warehouses,
  warehouseId,
}) {
  return (
    <div className="mb-4 flex flex-wrap items-center justify-between gap-3">
      <div>
        <div className="flex items-center gap-3">
          <h2 className="text-base font-semibold text-slate-800">Workspace overview</h2>
          <span className="flex items-center gap-1.5 text-[10px] text-slate-500">
            <span className={`h-1.5 w-1.5 rounded-full ${live ? 'bg-emerald-500' : 'bg-slate-400'}`} />
            {live ? 'Live updates' : 'Sample data'}
          </span>
        </div>
      </div>
      <div className="flex items-center gap-2">
        <label className="relative">
          <Warehouse className="pointer-events-none absolute left-2 top-1/2 -translate-y-1/2 text-slate-500" size={12} />
          <select
            aria-label="Filter by warehouse"
            className="h-8 w-[160px] appearance-none rounded-md border border-slate-200 bg-white pl-7 pr-7 text-[10px] text-slate-600 outline-none hover:border-slate-300 focus:border-teal-500"
            onChange={(event) => onWarehouseChange(event.target.value)}
            value={warehouseId}
          >
            <option value="all">All warehouses</option>
            {warehouses.map((location) => <option key={location.id} value={location.id}>{location.name}</option>)}
          </select>
          <ChevronDown className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" size={11} />
        </label>
        <label className="relative">
          <select
            aria-label="Select date range"
            className="h-8 w-[160px] appearance-none rounded-md border border-slate-200 bg-white px-2.5 pr-7 text-[10px] text-slate-600 outline-none hover:border-slate-300 focus:border-teal-500"
            onChange={(event) => onDateRangeChange(event.target.value)}
            value={dateRange}
          >
            <option>Today, Oct 24, 2026</option>
            <option>Last 7 days</option>
            <option>Last 30 days</option>
          </select>
          <ChevronDown className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" size={11} />
        </label>
      </div>
    </div>
  )
}
