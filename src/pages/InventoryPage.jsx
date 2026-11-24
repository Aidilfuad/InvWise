import { useEffect, useMemo, useState } from 'react'
import { useOutletContext } from 'react-router-dom'
import { Menu, Plus, Tag } from 'lucide-react'
import CategoriesUnitsModal from '../components/inventory/CategoriesUnitsModal'
import InventoryFilters from '../components/inventory/InventoryFilters'
import InventoryItemModal from '../components/inventory/InventoryItemModal'
import InventorySummary from '../components/inventory/InventorySummary'
import InventoryTable from '../components/inventory/InventoryTable'
import ItemDetailsDrawer from '../components/inventory/ItemDetailsDrawer'
import StockAdjustmentDrawer from '../components/inventory/StockAdjustmentDrawer'

const pageSize = 10

function stockStatus(item, quantity = item.quantity) {
  if (quantity <= 0) return 'out'
  if (quantity <= item.minimumStock) return 'low'
  return 'in'
}

function makeCurrencyFormatter(code, exchangeRateUsdMyr, live) {
  const currencyCode = code === 'USD' ? 'USD' : 'MYR'
  return (value, fractionDigits = 2) => {
    const converted = live && code === 'USD' && exchangeRateUsdMyr > 0 ? value / exchangeRateUsdMyr : value
    return new Intl.NumberFormat(currencyCode === 'USD' ? 'en-US' : 'en-MY', {
      style: 'currency',
      currency: currencyCode,
      minimumFractionDigits: fractionDigits,
      maximumFractionDigits: fractionDigits,
    }).format(converted)
  }
}

export default function InventoryPage({ mode = 'inventory' }) {
  const {
    data,
    loading,
    source,
    refresh,
    navigate,
    saveInventoryItem,
    archiveInventoryItem,
    recordStockMovement,
    saveCategory,
    setCategoryActive,
    saveUnit,
    setUnitActive,
    openMobileSidebar,
  } = useOutletContext()
  const [search, setSearch] = useState('')
  const [categoryId, setCategoryId] = useState('all')
  const [warehouseId, setWarehouseId] = useState('all')
  const [status, setStatus] = useState('all')
  const [page, setPage] = useState(1)
  const [selectedIds, setSelectedIds] = useState(() => new Set())
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [drawerItemId, setDrawerItemId] = useState('')
  const [modal, setModal] = useState(null)
  const [detailsItem, setDetailsItem] = useState(null)
  const [toast, setToast] = useState(null)
  const currency = useMemo(
    () => makeCurrencyFormatter(data.currencyCode, data.exchangeRateUsdMyr, data.live),
    [data.currencyCode, data.exchangeRateUsdMyr, data.live],
  )

  const isAdjustmentMode = mode === 'adjustment'
  const pageTitle = isAdjustmentMode ? 'Stock Adjustment' : 'Inventory Management'
  const pageDescription = isAdjustmentMode
    ? 'Record stock received, issued, transferred, or corrected without leaving your workspace.'
    : 'Manage stock levels, categories, warehouses, and item adjustments'

  useEffect(() => {
    document.title = `${pageTitle} | InvWise`
  }, [pageTitle])

  useEffect(() => {
    if (!toast) return undefined
    const timer = window.setTimeout(() => setToast(null), 4200)
    return () => window.clearTimeout(timer)
  }, [toast])

  const filteredItems = useMemo(() => {
    const normalizedSearch = search.trim().toLowerCase()
    return data.items.filter((item) => {
      const matchesSearch = !normalizedSearch ||
        `${item.name} ${item.sku} ${item.barcode ?? ''}`.toLowerCase().includes(normalizedSearch)
      const matchesCategory = categoryId === 'all' || item.categoryId === categoryId
      const matchesWarehouse = warehouseId === 'all' || Object.hasOwn(item.levels ?? {}, warehouseId)
      const currentQuantity = warehouseId === 'all' ? item.quantity : Number(item.levels?.[warehouseId] ?? 0)
      const matchesStatus = status === 'all' || stockStatus(item, currentQuantity) === status
      return matchesSearch && matchesCategory && matchesWarehouse && matchesStatus
    })
  }, [data.items, search, categoryId, warehouseId, status])
  const pageCount = Math.max(1, Math.ceil(filteredItems.length / pageSize))
  const visiblePage = Math.min(page, pageCount)
  const visibleItems = filteredItems.slice((visiblePage - 1) * pageSize, visiblePage * pageSize)
  const selectedItem = drawerItemId
    ? data.items.find((item) => item.id === drawerItemId) ?? null
    : null
  const showAdjustmentDrawer = drawerOpen || isAdjustmentMode
  const activeItems = data.items.filter((item) => item.isActive !== false)

  function showToast(message, tone = 'success') {
    setToast({ message, tone })
  }

  function openAdjustment(item) {
    const preferred = item ?? data.items.find((row) => selectedIds.has(row.id))
    setDrawerItemId(preferred?.id ?? '')
    setDrawerOpen(true)
  }

  function closeAdjustment() {
    setDrawerOpen(false)
    if (isAdjustmentMode) {
      navigate('/inventory', { replace: true })
    }
  }

  function toggleSelected(itemId, checked) {
    setSelectedIds((current) => {
      const next = new Set(current)
      if (checked) next.add(itemId)
      else next.delete(itemId)
      return next
    })
  }

  function selectVisible(items, checked) {
    setSelectedIds((current) => {
      const next = new Set(current)
      for (const item of items) {
        if (checked) next.add(item.id)
        else next.delete(item.id)
      }
      return next
    })
  }

  async function submitMovement(values) {
    const result = await recordStockMovement(values)
    showToast(result?.warning || 'Stock adjustment saved successfully.', result?.warning ? 'warning' : 'success')
  }

  async function submitItem(values) {
    const result = await saveInventoryItem(values)
    showToast(result?.warning || (values.itemId ? 'Inventory item updated successfully.' : 'Inventory item created successfully.'), result?.warning ? 'warning' : 'success')
  }

  async function archiveItem(item) {
    if (!window.confirm(`Archive "${item.name}"? It will be removed from active inventory but its stock history will be retained.`)) return
    try {
      await archiveInventoryItem(item.id)
      setSelectedIds((current) => {
        const next = new Set(current)
        next.delete(item.id)
        return next
      })
      showToast('Inventory item archived.')
    } catch (error) {
      showToast(error instanceof Error ? error.message : 'Unable to archive this item.', 'error')
    }
  }

  function clearFilters() {
    setPage(1)
    setSearch('')
    setCategoryId('all')
    setWarehouseId('all')
    setStatus('all')
  }

  function updateSearch(value) {
    setPage(1)
    setSearch(value)
  }

  function updateCategory(value) {
    setPage(1)
    setCategoryId(value)
  }

  function updateWarehouse(value) {
    setPage(1)
    setWarehouseId(value)
  }

  function updateStatus(value) {
    setPage(1)
    setStatus(value)
  }

  return (
    <main className="min-h-screen px-4 pb-5 pt-5 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-[1600px]">
        <header className="mb-5 flex flex-wrap items-center justify-between gap-4">
          <div className="flex min-w-0 items-center gap-3">
            <button aria-label="Open navigation" className="grid h-9 w-9 shrink-0 place-items-center rounded-lg border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 lg:hidden" onClick={openMobileSidebar} type="button"><Menu size={17} /></button>
            <div>
              <h1 className="text-xl font-bold tracking-[-0.03em] text-slate-900 sm:text-2xl">{pageTitle}</h1>
              <p className="mt-1 text-xs text-slate-500">{pageDescription}</p>
            </div>
          </div>
          <div className="flex w-full items-center gap-2 sm:w-auto">
            <button className="flex h-10 flex-1 items-center justify-center gap-2 rounded-lg border border-slate-200 bg-white px-3 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 sm:flex-none" onClick={() => setModal({ type: 'categories' })} type="button">
              <Tag size={15} className="text-slate-500" /> Categories & Units
            </button>
            <button className="flex h-10 flex-1 items-center justify-center gap-1.5 rounded-lg bg-teal-600 px-3.5 text-xs font-semibold text-white shadow-sm transition hover:bg-teal-700 sm:flex-none" onClick={() => setModal({ type: 'item', item: null })} type="button">
              <Plus size={15} /> Add New Item
            </button>
          </div>
        </header>

        {loading && <p className="mb-3 text-[11px] text-slate-400" role="status">Refreshing inventory data…</p>}
        {source === 'demo' && !loading && (
          <div className="mb-4 rounded-lg border border-amber-200 bg-amber-50 px-3.5 py-2.5 text-xs text-amber-800" role="status">
            Showing sample inventory. Sign in with a configured workspace to load and update live records.
            <button className="ml-2 font-semibold underline" onClick={refresh} type="button">Retry</button>
          </div>
        )}

        <div className="space-y-4">
          <InventorySummary currency={currency} data={{ ...data, source }} />
          <InventoryFilters
            categories={data.categories}
            categoryId={categoryId}
            drawerOpen={showAdjustmentDrawer}
            onCategoryChange={updateCategory}
            onClear={clearFilters}
            onSearchChange={updateSearch}
            onStatusChange={updateStatus}
            onToggleDrawer={() => {
              if (showAdjustmentDrawer) closeAdjustment()
              else openAdjustment()
            }}
            onWarehouseChange={updateWarehouse}
            search={search}
            status={status}
            warehouseId={warehouseId}
            warehouses={data.warehouses}
          />
          <InventoryTable
            currency={currency}
            items={visibleItems}
            onAdjust={openAdjustment}
            onArchive={archiveItem}
            onEdit={(item) => setModal({ type: 'item', item })}
            onPageChange={setPage}
            onSelect={toggleSelected}
            onSelectAll={selectVisible}
            onView={setDetailsItem}
            page={page}
            pageSize={pageSize}
            selectedIds={selectedIds}
            totalItems={filteredItems.length}
            warehouseId={warehouseId}
            warehouses={data.warehouses}
          />
        </div>

        <footer className="mt-5 flex flex-wrap items-center justify-between gap-2 text-[10px] text-slate-400">
          <span>InvWise Enterprise · All times in local timezone (UTC-04:00)</span>
          <span>{source === 'live' ? 'Live inventory data' : 'Sample data'}{loading ? ' · Syncing…' : ''}</span>
        </footer>
      </div>

      {showAdjustmentDrawer && (
        <StockAdjustmentDrawer
        key={`${drawerItemId || 'none'}-${activeItems[0]?.id ?? ''}`}
          items={activeItems}
          locations={data.warehouses}
          onClose={closeAdjustment}
          onSubmit={submitMovement}
          selectedItem={selectedItem}
        />
      )}
      {detailsItem && (
        <ItemDetailsDrawer
          currency={currency}
          item={detailsItem}
          movements={data.movements}
          onClose={() => setDetailsItem(null)}
          onEdit={(item) => {
            setDetailsItem(null)
            setModal({ type: 'item', item })
          }}
          warehouses={data.warehouses}
        />
      )}
      {modal?.type === 'item' && (
        <InventoryItemModal
          key={`${modal.item?.id ?? 'new-item'}-${data.units[0]?.id ?? ''}-${data.warehouses[0]?.id ?? ''}`}
          barcodeAvailable={data.barcodeFieldAvailable}
          binLocationAvailable={data.binLocationFieldAvailable}
          categories={data.categories}
          item={modal.item}
          onClose={() => setModal(null)}
          onSubmit={submitItem}
          units={data.units}
          warehouses={data.warehouses}
        />
      )}
      {modal?.type === 'categories' && (
        <CategoriesUnitsModal
          categories={data.categories}
          onCategoryActiveChange={setCategoryActive}
          onClose={() => setModal(null)}
          onCreateCategory={saveCategory}
          onCreateUnit={saveUnit}
          onUnitActiveChange={setUnitActive}
          units={data.units}
        />
      )}
      {toast && (
        <div className={`fixed bottom-5 right-5 z-[100] max-w-[min(420px,calc(100vw-40px))] rounded-xl border px-4 py-3 text-xs font-medium shadow-lg ${toast.tone === 'success' ? 'border-emerald-200 bg-white text-emerald-800' : toast.tone === 'warning' ? 'border-amber-200 bg-white text-amber-800' : 'border-rose-200 bg-white text-rose-800'}`} role={toast.tone === 'error' ? 'alert' : 'status'}>
          {toast.message}
        </div>
      )}
    </main>
  )
}
