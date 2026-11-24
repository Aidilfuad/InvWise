import { useEffect, useMemo, useState } from 'react'
import {
  BarChart3,
  Bell,
  CheckCheck,
  ClipboardList,
  Download,
  Menu,
  Search,
  X,
} from 'lucide-react'
import { useLocation, useNavigate, useOutletContext } from 'react-router-dom'
import ActivityLogsTab from '../components/activity-reports/ActivityLogsTab'
import AlertsTab from '../components/activity-reports/AlertsTab'
import ManageRulesModal from '../components/activity-reports/ManageRulesModal'
import ReportsTab from '../components/activity-reports/ReportsTab'
import useActivityReportsData from '../components/activity-reports/useActivityReportsData'
import { downloadCsv, formatLocalDate, formatTimezone, printReport } from '../components/activity-reports/exportUtils'

const tabs = [
  { id: 'activity-logs', label: 'Activity Logs', path: '/activity-logs', Icon: ClipboardList },
  { id: 'alerts', label: 'Alerts', path: '/alerts', Icon: Bell },
  { id: 'reports', label: 'Reports', path: '/reports', Icon: BarChart3 },
]

const viewCopy = {
  'activity-logs': 'Review operational events, stock movements, and team activity.',
  alerts: 'Monitor and resolve inventory and telemetry alerts.',
  reports: 'Generate inventory, movement, replenishment, and telemetry reports.',
}

const reportNames = {
  valuation: 'Inventory Valuation',
  movements: 'Stock Movement Summary',
  replenishment: 'Low-Stock Replenishment',
  telemetry: 'Telemetry & Sensor Health',
}

function isWithinReportRange(value, range) {
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return range === 'all'
  if (range === 'all') return true
  if (range === 'today') {
    const now = new Date()
    return date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth() && date.getDate() === now.getDate()
  }
  const days = range === '7d' ? 7 : 30
  return date.getTime() >= Date.now() - days * 24 * 60 * 60 * 1000
}

function toMovementExport(row) {
  const type = String(row.type || row.movement_type || '').toLowerCase()
  const event = {
    receipt: 'Stock received',
    issue: 'Stock dispatched',
    transfer: 'Stock transferred',
    return: 'Stock returned',
    adjustment: 'Stock adjusted',
  }[type] || 'Stock movement'
  const quantity = Number(row.quantity)
  const value = Number.isFinite(quantity)
    ? `${type === 'issue' ? '−' : type === 'receipt' || type === 'return' ? '+' : ''}${quantity.toLocaleString()} units`
    : ''
  return {
    id: row.id,
    category: 'Stock Movements',
    event: row.event || event,
    description: row.description || row.itemName || '',
    detail: row.detail || row.sku || '',
    warehouse: row.warehouse || row.warehouseName || '',
    actor: row.actor || 'InvWise System',
    role: 'Stock movement',
    badge: type === 'issue' ? 'Stock Out' : type === 'transfer' ? 'Transfer' : 'Stock In',
    value,
    reference: row.reference || '',
    occurredAt: row.occurredAt || row.occurred_at || new Date(),
    sourceTable: 'dashboard_movements',
  }
}

export default function ActivityReportsPage() {
  const {
    data: dashboardData,
    searchTerm: globalSearch,
    setGlobalSearchTerm,
    openMobileSidebar,
    navigate: navigateFromLayout,
  } = useOutletContext()
  const hub = useActivityReportsData({
    items: dashboardData.items,
    warehouses: dashboardData.warehouses,
  })
  const location = useLocation()
  const routerNavigate = useNavigate()
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [exportOpen, setExportOpen] = useState(false)
  const [mobileSearchOpen, setMobileSearchOpen] = useState(false)
  const [rulesOpen, setRulesOpen] = useState(false)
  const [toast, setToast] = useState('')

  const currentPath = location.pathname.replace(/\/+$/, '') || '/'
  const activeView = tabs.find((tab) => tab.path === currentPath) || tabs[0]
  const activeTab = activeView.id
  const activeAlertCount = hub.alerts.filter((alert) => alert.status === 'active').length
  const activityRows = useMemo(() => {
    if (hub.activities.some((row) => row.category === 'Stock Movements')) return hub.activities
    const movementRows = dashboardData.movements.map(toMovementExport)
    return [...hub.activities, ...movementRows].sort((left, right) => new Date(right.occurredAt).getTime() - new Date(left.occurredAt).getTime())
  }, [dashboardData.movements, hub.activities])
  const activeAlerts = useMemo(() => hub.alerts
    .filter((alert) => alert.status === 'active')
    .sort((left, right) => new Date(right.detectedAt).getTime() - new Date(left.detectedAt).getTime()), [hub.alerts])
  const reportMovements = hub.movements.length > 0
    ? hub.movements
    : dashboardData.movements.map(toMovementExport)

  useEffect(() => {
    document.title = `${activeView.label} | InvWise`
  }, [activeView.label])

  function showToast(message) {
    setToast(message)
    window.setTimeout(() => setToast(''), 3500)
  }

  async function updateAlert(alert, status) {
    try {
      await hub.updateAlert(alert.id, status)
      showToast(status === 'resolved' ? 'Alert resolved.' : 'Alert acknowledged.')
    } catch (error) {
      showToast(error instanceof Error ? error.message : 'Unable to update this alert.')
    }
  }

  async function saveRules(values) {
    await hub.saveRules(values)
    showToast('Alert rules saved.')
  }

  function exportRows(reportId, scope) {
    const items = dashboardData.items.filter((item) => {
      const byWarehouse = !scope || scope.warehouse === 'all' || item.locationName === scope.warehouse ||
        Object.keys(item.levels || {}).some((id) => dashboardData.warehouses.find((warehouse) => warehouse.id === id)?.name === scope.warehouse)
      const bySearch = !globalSearch.trim() || `${item.name} ${item.sku} ${item.categoryName} ${item.locationName}`.toLowerCase().includes(globalSearch.trim().toLowerCase())
      return byWarehouse && bySearch
    })
    const movements = (hub.movements.length > 0
      ? hub.movements
      : dashboardData.movements.map(toMovementExport))
      .filter((movement) => {
        const byWarehouse = !scope || scope.warehouse === 'all' || movement.warehouse?.includes(scope.warehouse)
        const byDate = !scope || isWithinReportRange(movement.occurredAt, scope.dateRange)
        const bySearch = !globalSearch.trim() || `${movement.event} ${movement.description} ${movement.detail} ${movement.actor}`.toLowerCase().includes(globalSearch.trim().toLowerCase())
        return byWarehouse && byDate && bySearch
      })

    if (reportId === 'valuation') {
      return {
        headers: ['Item', 'SKU', 'Category', 'Warehouse', 'Quantity', 'Unit price', 'Total value'],
        rows: items.map((item) => [
          item.name,
          item.sku,
          item.categoryName,
          item.locationName,
          item.quantity,
          item.unitPrice,
          Number(item.quantity) * Number(item.unitPrice),
        ]),
      }
    }
    if (reportId === 'movements') {
      return {
        headers: ['Event', 'Item', 'Reference', 'Actor', 'Warehouse', 'Timestamp'],
        rows: movements.map((movement) => [
          movement.event,
          movement.description,
          movement.reference || movement.detail,
          movement.actor,
          movement.warehouse,
          movement.occurredAt instanceof Date ? movement.occurredAt.toISOString() : movement.occurredAt,
        ]),
      }
    }
    if (reportId === 'replenishment') {
      const lowStock = items.filter((item) => item.quantity <= item.minimumStock)
      return {
        headers: ['Item', 'SKU', 'Warehouse', 'Current quantity', 'Minimum stock', 'Reorder quantity'],
        rows: lowStock.map((item) => [
          item.name,
          item.sku,
          item.locationName,
          item.quantity,
          item.minimumStock,
          Math.max(0, item.minimumStock * 2 - item.quantity),
        ]),
      }
    }
    const alerts = hub.alerts.filter((alert) => (
      (!scope || scope.warehouse === 'all' || alert.warehouse === scope.warehouse) &&
      (!globalSearch.trim() || `${alert.title} ${alert.detail} ${alert.warehouse}`.toLowerCase().includes(globalSearch.trim().toLowerCase()))
    ))
    return {
      headers: ['Alert', 'Type', 'Severity', 'Status', 'Warehouse', 'Detected at'],
      rows: alerts.map((alert) => [
        alert.title,
        alert.type,
        alert.severity,
        alert.status,
        alert.warehouse,
        alert.detectedAt instanceof Date ? alert.detectedAt.toISOString() : alert.detectedAt,
      ]),
    }
  }

  async function generateReport(reportId, format, scope) {
    const title = reportNames[reportId]
    if (!title) throw new Error('Choose a valid report.')
    const { headers, rows } = exportRows(reportId, scope)
    if (format === 'PDF') {
      printReport(title, `${scope.scope} · Generated ${formatLocalDate(new Date())}`, headers, rows)
    } else {
      downloadCsv(`invwise-${reportId}-${new Date().toISOString().slice(0, 10)}.csv`, headers, rows)
    }
    return {
      id: `export-${Date.now()}`,
      reportId,
      title,
      format,
      scope: scope.scope,
      actor: dashboardData.profile?.full_name || 'You',
      createdAt: new Date(),
    }
  }

  const activityExportRows = activityRows.filter((row) => (
    !globalSearch.trim() ||
    `${row.event} ${row.description} ${row.detail} ${row.actor} ${row.reference} ${row.warehouse}`.toLowerCase().includes(globalSearch.trim().toLowerCase())
  ))
  const alertExportRows = activeAlerts.filter((row) => (
    !globalSearch.trim() ||
    `${row.title} ${row.detail} ${row.warehouse} ${row.type}`.toLowerCase().includes(globalSearch.trim().toLowerCase())
  ))

  function exportCurrentTab(format) {
    try {
      let title
      let headers
      let rows
      if (activeTab === 'alerts') {
        title = 'InvWise Alerts'
        headers = ['Alert', 'Type', 'Severity', 'Status', 'Warehouse', 'Detected at']
        rows = alertExportRows.map((alert) => [alert.title, alert.type, alert.severity, alert.status, alert.warehouse, alert.detectedAt])
      } else if (activeTab === 'reports') {
        title = reportNames.valuation
        const report = exportRows('valuation')
        headers = report.headers
        rows = report.rows
      } else {
        title = 'InvWise Activity Logs'
        headers = ['Event', 'Category', 'Detail', 'Actor', 'Role', 'Warehouse', 'Reference', 'Timestamp']
        rows = activityExportRows.map((row) => [row.event, row.category, `${row.description} ${row.detail}`, row.actor, row.role, row.warehouse, row.reference, row.occurredAt])
      }
      if (format === 'PDF') {
        printReport(title, `Exported ${formatLocalDate(new Date())}`, headers, rows)
      } else {
        downloadCsv(`invwise-${activeTab}-${new Date().toISOString().slice(0, 10)}.csv`, headers, rows)
      }
      showToast(`${title} ${format} export is ready.`)
    } catch (error) {
      showToast(error instanceof Error ? error.message : 'Unable to export this view.')
    }
    setExportOpen(false)
  }

  return (
    <div className="min-h-screen bg-[#f8fafc]">
      <header className="relative z-30 flex min-h-[76px] items-center justify-between gap-4 border-b border-slate-200 bg-white px-4 py-3 sm:px-6 lg:min-h-[78px] lg:px-7">
        <div className="flex min-w-0 items-center gap-2.5">
          <button aria-label="Open navigation" className="rounded-md p-2 text-slate-500 hover:bg-slate-100 lg:hidden" onClick={openMobileSidebar} type="button"><Menu size={18} /></button>
          <div className="min-w-0">
            <h1 className="truncate text-[17px] font-bold tracking-[-0.025em] text-slate-900 sm:text-[20px]">{activeView.label}</h1>
            <p className="mt-0.5 hidden text-[9px] text-slate-500 sm:block">{viewCopy[activeTab]}</p>
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <label className="relative hidden w-[190px] sm:block lg:w-[220px]">
            <Search aria-hidden="true" className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={13} />
            <input aria-label="Search anything in activity and reports" className="h-8 w-full rounded-md border border-slate-200 bg-slate-50 pl-8 pr-12 text-[9px] outline-none placeholder:text-slate-400 focus:border-teal-500 focus:bg-white" onChange={(event) => setGlobalSearchTerm(event.target.value)} placeholder="Search anything..." value={globalSearch} />
            {globalSearch && <button aria-label="Clear global search" className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" onClick={() => setGlobalSearchTerm('')} type="button"><X size={12} /></button>}
            {!globalSearch && <span className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-[8px] text-slate-400">⌘ K</span>}
          </label>
          <div className="relative sm:hidden">
            <button aria-expanded={mobileSearchOpen} aria-label="Search" className="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-slate-600" onClick={() => setMobileSearchOpen((open) => !open)} type="button"><Search size={14} /></button>
          </div>
          <div className="relative">
            <button aria-expanded={notificationsOpen} aria-label={`Notifications, ${activeAlertCount} active`} className="relative grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-slate-600 hover:bg-slate-50" onClick={() => setNotificationsOpen((open) => !open)} type="button">
              <Bell size={14} />
              {activeAlertCount > 0 && <span className="absolute right-[5px] top-[4px] h-1.5 w-1.5 rounded-full bg-rose-500 ring-2 ring-white" />}
            </button>
            {notificationsOpen && (
              <div className="absolute right-0 top-10 z-50 w-[min(320px,calc(100vw-24px))] rounded-lg border border-slate-200 bg-white p-3 shadow-xl">
                <div className="mb-2 flex items-center justify-between">
                  <p className="text-[11px] font-semibold text-slate-900">Active alerts</p>
                  <span className="text-[9px] text-slate-400">{activeAlertCount} open</span>
                </div>
                <div className="max-h-60 space-y-1 overflow-y-auto">
                  {activeAlerts.slice(0, 5).map((alert) => (
                    <button className="block w-full rounded-md px-2 py-2 text-left hover:bg-slate-50" key={alert.id} onClick={() => { routerNavigate('/alerts'); setNotificationsOpen(false) }} type="button">
                      <p className="truncate text-[9px] font-medium text-slate-800">{alert.title}</p>
                      <p className="mt-0.5 text-[8px] text-slate-500">{alert.warehouse} · {alert.severity}</p>
                    </button>
                  ))}
                  {activeAlerts.length === 0 && <p className="py-4 text-center text-[9px] text-slate-500">No active alerts.</p>}
                </div>
                <button className="mt-2 w-full border-t border-slate-100 pt-2 text-center text-[9px] font-semibold text-teal-700" onClick={() => { routerNavigate('/alerts'); setNotificationsOpen(false) }} type="button">View all alerts</button>
              </div>
            )}
          </div>
          <div className="relative">
            <button aria-expanded={exportOpen} className="inline-flex h-8 items-center gap-1.5 whitespace-nowrap rounded-md bg-teal-600 px-2.5 text-[9px] font-semibold text-white shadow-sm transition hover:bg-teal-700 sm:px-3" onClick={() => setExportOpen((open) => !open)} type="button">
              <Download size={12} /><span>Export CSV / PDF</span>
            </button>
            {exportOpen && (
              <div className="absolute right-0 top-10 z-50 w-40 rounded-lg border border-slate-200 bg-white p-1.5 shadow-xl">
                <button className="flex w-full items-center gap-2 rounded-md px-2.5 py-2 text-left text-[9px] text-slate-700 hover:bg-slate-50" onClick={() => exportCurrentTab('CSV')} type="button"><Download size={12} /> Download CSV</button>
                <button className="flex w-full items-center gap-2 rounded-md px-2.5 py-2 text-left text-[9px] text-slate-700 hover:bg-slate-50" onClick={() => exportCurrentTab('PDF')} type="button"><ClipboardList size={12} /> Print / Save PDF</button>
              </div>
            )}
          </div>
        </div>
        {mobileSearchOpen && (
          <label className="absolute left-4 right-4 top-[calc(100%+6px)] z-40 sm:hidden">
            <span className="sr-only">Search anything</span>
            <Search aria-hidden="true" className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={13} />
            <input autoFocus className="h-9 w-full rounded-md border border-slate-200 bg-white pl-8 pr-8 text-[10px] shadow-lg outline-none focus:border-teal-500" onChange={(event) => setGlobalSearchTerm(event.target.value)} placeholder="Search anything..." value={globalSearch} />
            <button aria-label="Close mobile search" className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" onClick={() => setMobileSearchOpen(false)} type="button"><X size={12} /></button>
          </label>
        )}
      </header>

      <nav aria-label="Activity and reports sections" className="flex items-center justify-between gap-3 border-b border-slate-200 bg-white px-4 sm:px-6 lg:px-7">
        <div className="flex min-w-0 items-center gap-4 sm:gap-6">
          {tabs.map(({ id, label, path, Icon }) => (
            <button aria-current={activeTab === id ? 'page' : undefined} className={`relative flex h-10 shrink-0 items-center gap-1.5 border-b-2 px-1 text-[9px] transition sm:text-[10px] ${activeTab === id ? 'border-teal-600 font-semibold text-teal-700' : 'border-transparent text-slate-500 hover:text-slate-800'}`} key={id} onClick={() => { navigateFromLayout(path); setNotificationsOpen(false) }} type="button">
              <Icon size={13} />
              {label}
              {id === 'alerts' && activeAlertCount > 0 && <span className="rounded bg-rose-50 px-1 py-0.5 text-[8px] font-semibold text-rose-600">{activeAlertCount}</span>}
            </button>
          ))}
        </div>
        <span className="hidden shrink-0 text-[8px] text-slate-400 sm:inline">{formatTimezone()}</span>
      </nav>

      <main className="mx-auto max-w-[1500px] space-y-3 px-4 py-4 sm:px-6 lg:px-7">
        {hub.error && <p className="rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-[9px] text-amber-800" role="status">{hub.error}</p>}
        {activeTab === 'activity-logs' && (
          <ActivityLogsTab
              activities={activityRows}
            alertCount={activeAlertCount}
            globalSearch={globalSearch}
            source={hub.source}
            warehouses={dashboardData.warehouses}
          />
        )}
        {activeTab === 'alerts' && (
          <AlertsTab
            alerts={hub.alerts}
            globalSearch={globalSearch}
            onAcknowledge={(alert) => updateAlert(alert, 'acknowledged')}
            onManageRules={() => setRulesOpen(true)}
            onResolve={(alert) => updateAlert(alert, 'resolved')}
            onViewInventory={() => routerNavigate('/inventory')}
            source={hub.source}
            warehouses={dashboardData.warehouses}
          />
        )}
        {activeTab === 'reports' && (
          <ReportsTab
            alertCount={activeAlertCount}
            currencyCode={dashboardData.currencyCode}
            globalSearch={globalSearch}
            items={dashboardData.items}
            movements={reportMovements}
            onGenerate={generateReport}
            telemetry={dashboardData.telemetry}
            warehouses={dashboardData.warehouses}
          />
        )}
      </main>

      {rulesOpen && <ManageRulesModal onClose={() => setRulesOpen(false)} onSave={saveRules} rules={hub.rules} />}
      {toast && (
        <div className="fixed bottom-4 right-4 z-[90] flex max-w-[min(420px,calc(100vw-32px))] items-start gap-2 rounded-lg border border-slate-200 bg-white px-3.5 py-3 text-[10px] text-slate-700 shadow-xl" role="status">
          <CheckCheck className="mt-0.5 shrink-0 text-teal-600" size={14} />{toast}
        </div>
      )}
    </div>
  )
}
