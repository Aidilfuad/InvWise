import { useState } from 'react'
import { useOutletContext } from 'react-router-dom'
import InventoryHealthCard from '../components/dashboard/InventoryHealthCard'
import KpiCards from '../components/dashboard/KpiCards'
import OperationsPanel from '../components/dashboard/OperationsPanel'
import RecentMovements from '../components/dashboard/RecentMovements'
import TelemetryCard from '../components/dashboard/TelemetryCard'
import WorkspaceOverview from '../components/dashboard/WorkspaceOverview'

export default function DashboardPage() {
  const {
    data,
    loading,
    navigate,
    openAddInventory,
    openAdjustment,
    searchTerm,
    source,
  } = useOutletContext()
  const [warehouseId, setWarehouseId] = useState('all')
  const [dateRange, setDateRange] = useState('Today, Oct 24, 2026')
  const normalizedSearch = searchTerm.trim().toLowerCase()

  const visibleItems = data.items.filter((item) => {
    const matchesSearch = !normalizedSearch ||
      `${item.name} ${item.sku}`.toLowerCase().includes(normalizedSearch)
    const matchesWarehouse = warehouseId === 'all' ||
      Object.hasOwn(item.levels, warehouseId)
    return matchesSearch && matchesWarehouse
  })

  const visibleMovements = data.movements.filter((movement) => {
    const matchesSearch = !normalizedSearch ||
      `${movement.itemName} ${movement.sku} ${movement.warehouseName} ${movement.type}`.toLowerCase().includes(normalizedSearch)
    const warehouseName = data.warehouses.find((location) => location.id === warehouseId)?.name
    const matchesWarehouse = warehouseId === 'all' ||
      movement.warehouseName.includes(warehouseName ?? '')
    return matchesSearch && matchesWarehouse
  })

  const visibleAlerts = data.alerts.filter((alert) => (
    !normalizedSearch || `${alert.title} ${alert.subtitle} ${alert.message}`.toLowerCase().includes(normalizedSearch)
  ))

  return (
    <main className="flex min-h-[calc(100vh-82px)] flex-col px-4 pb-3 pt-4 sm:px-7">
      <div className="flex-1">
        <WorkspaceOverview
          dateRange={dateRange}
          live={source === 'live' && !loading}
          onDateRangeChange={setDateRange}
          onWarehouseChange={setWarehouseId}
          warehouses={data.warehouses}
          warehouseId={warehouseId}
        />

        {loading && (
          <p className="mb-3 text-[9px] text-slate-400" role="status">Refreshing workspace data…</p>
        )}

        <KpiCards data={data} warehouseId={warehouseId} />

        <div className="mt-4 grid grid-cols-1 items-stretch gap-4 xl:grid-cols-[1.5fr_1fr]">
          <TelemetryCard telemetry={data.telemetry} />
          <InventoryHealthCard
            data={data}
            items={visibleItems}
            onRestock={(item) => openAdjustment(item)}
          />
        </div>

        <div className="mt-4 grid grid-cols-1 items-start gap-4 xl:grid-cols-[1.85fr_1fr]">
          <RecentMovements movements={visibleMovements} onViewAll={() => navigate('/activity-logs')} />
          <OperationsPanel
            alerts={visibleAlerts}
            movements={visibleMovements}
            onAddInventory={openAddInventory}
            onAdjustStock={() => openAdjustment()}
            onViewSensors={() => navigate('/telemetry')}
          />
        </div>
      </div>

      <footer className="mt-4 flex flex-wrap items-center justify-between gap-2 text-[7px] text-slate-400">
        <span>InvWise Enterprise · All times in local timezone (UTC-04:00)</span>
        <span>Last updated just now</span>
      </footer>
    </main>
  )
}
