import { ChevronDown, Search, X } from 'lucide-react'

function FilterSelect({ label, value, onChange, children }) {
  return (
    <label className="relative min-w-0 flex-1">
      <span className="sr-only">{label}</span>
      <select
        aria-label={label}
        className="h-9 w-full appearance-none rounded-lg border border-slate-200 bg-white pl-3 pr-8 text-xs text-slate-600 outline-none transition focus:border-teal-500 focus:ring-2 focus:ring-teal-100"
        onChange={(event) => onChange(event.target.value)}
        value={value}
      >
        {children}
      </select>
      <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
    </label>
  )
}

export default function InventoryFilters({
  categories,
  onCategoryChange,
  onSearchChange,
  onStatusChange,
  onToggleDrawer,
  onWarehouseChange,
  onClear,
  search,
  categoryId,
  warehouseId,
  status,
  drawerOpen,
  warehouses,
}) {
  return (
    <section aria-label="Inventory filters" className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
        <div className="relative min-w-0 flex-1">
          <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={16} />
          <input
            aria-label="Search by item name, SKU, or barcode"
            className="h-10 w-full rounded-lg border border-slate-200 bg-slate-50 pl-9 pr-9 text-xs text-slate-700 outline-none transition placeholder:text-slate-400 focus:border-teal-500 focus:bg-white focus:ring-2 focus:ring-teal-100"
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="Search by item name, SKU, or barcode..."
            value={search}
          />
          {search && (
            <button aria-label="Clear search" className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-700" onClick={() => onSearchChange('')} type="button">
              <X size={14} />
            </button>
          )}
        </div>
        <button
          aria-checked={drawerOpen}
          className="flex h-10 shrink-0 items-center justify-between gap-3 rounded-lg border border-slate-200 px-3 text-xs font-medium text-slate-600 transition hover:border-teal-200 hover:bg-teal-50/50"
          onClick={onToggleDrawer}
          role="switch"
          type="button"
        >
          Stock Adjustment Drawer
          <span className={`relative h-5 w-9 rounded-full transition ${drawerOpen ? 'bg-teal-600' : 'bg-slate-300'}`}>
            <span className={`absolute top-0.5 h-4 w-4 rounded-full bg-white shadow-sm transition ${drawerOpen ? 'left-[18px]' : 'left-0.5'}`} />
          </span>
        </button>
      </div>

      <div className="mt-3 flex flex-col gap-2 border-t border-slate-100 pt-3 sm:flex-row sm:items-center">
        <FilterSelect label="Category" onChange={onCategoryChange} value={categoryId}>
          <option value="all">All Categories</option>
          {categories.filter((category) => category.is_active !== false).map((category) => (
            <option key={category.id} value={category.id}>{category.name}</option>
          ))}
        </FilterSelect>
        <FilterSelect label="Warehouse" onChange={onWarehouseChange} value={warehouseId}>
          <option value="all">All Warehouses</option>
          {warehouses.filter((warehouse) => warehouse.isActive !== false).map((warehouse) => (
            <option key={warehouse.id} value={warehouse.id}>{warehouse.name}</option>
          ))}
        </FilterSelect>
        <FilterSelect label="Stock status" onChange={onStatusChange} value={status}>
          <option value="all">All Stock Status</option>
          <option value="in">In Stock</option>
          <option value="low">Low Stock</option>
          <option value="out">Out of Stock</option>
        </FilterSelect>
        <button className="h-9 shrink-0 px-2 text-xs font-semibold text-teal-700 hover:text-teal-800" onClick={onClear} type="button">
          Clear filters
        </button>
      </div>
    </section>
  )
}
