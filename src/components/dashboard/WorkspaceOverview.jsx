import SearchableSelect from '../common/SearchableSelect'

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
        <div className="w-[160px]">
          <SearchableSelect
            aria-label="Filter by warehouse"
            className="h-8 text-[10px] text-slate-600"
            onChange={onWarehouseChange}
            options={[
              { value: 'all', label: 'All warehouses' },
              ...warehouses.map((location) => ({ value: location.id, label: location.name })),
            ]}
            value={warehouseId}
          />
        </div>
        <div className="w-[160px]">
          <SearchableSelect
            aria-label="Select date range"
            className="h-8 text-[10px] text-slate-600"
            onChange={onDateRangeChange}
            options={[
              { value: 'Today, Oct 24, 2026', label: 'Today, Oct 24, 2026' },
              { value: 'Last 7 days', label: 'Last 7 days' },
              { value: 'Last 30 days', label: 'Last 30 days' },
            ]}
            value={dateRange}
          />
        </div>
      </div>
    </div>
  )
}
