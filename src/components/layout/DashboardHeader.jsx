import { useEffect, useState } from 'react'
import { Bell, Menu, Plus, Search, X } from 'lucide-react'

const pageTitles = {
  '/dashboard': ['Operations Dashboard', 'Real-time inventory health & warehouse telemetry'],
  '/inventory': ['Inventory', 'Browse and manage stock across your warehouses'],
  '/stock-adjustment': ['Stock Adjustment', 'Review and make controlled inventory changes'],
  '/activity-logs': ['Activity Logs', 'Track recent inventory and workspace activity'],
  '/telemetry': ['Telemetry & Sensors', 'Monitor sensor health and warehouse conditions'],
  '/alerts': ['Alerts', 'Review inventory and hardware alerts'],
  '/reports': ['Reports', 'Explore inventory and operations reporting'],
  '/users': ['User Management', 'Manage workspace access and roles'],
  '/settings': ['Settings', 'Configure your InvWise workspace'],
}

export default function DashboardHeader({
  alertCount,
  alerts,
  location,
  onMenu,
  onQuickAdjustment,
  onSearch,
  searchTerm,
}) {
  const [alertsOpen, setAlertsOpen] = useState(false)
  const [searchOpen, setSearchOpen] = useState(false)
  const [title, subtitle] = pageTitles[location.pathname] ?? pageTitles['/dashboard']

  useEffect(() => {
    document.title = `${title} | InvWise`
  }, [title])

  return (
    <header className="relative z-30 flex min-h-[72px] items-center justify-between gap-5 border-b border-slate-200 bg-white px-5 py-3 sm:px-7 lg:h-[82px] lg:px-7 lg:py-0">
      <div className="flex min-w-0 items-center gap-3">
        <button aria-label="Open navigation" className="rounded-md p-2 text-slate-500 hover:bg-slate-100 lg:hidden" onClick={onMenu} type="button">
          <Menu size={19} />
        </button>
        <div className="min-w-0">
          <h1 className="break-words text-[18px] font-bold leading-5 tracking-[-0.025em] text-slate-900 sm:truncate sm:text-2xl sm:leading-6">{title}</h1>
          <p className="mt-1 hidden text-[10px] text-slate-500 sm:block">{subtitle}</p>
        </div>
      </div>

      <div className="flex items-center gap-2.5">
        <div className={`${searchOpen ? 'flex' : 'hidden'} absolute left-4 right-4 top-[calc(100%+8px)] z-20 sm:static sm:flex`}>
          <div className="relative w-full sm:w-[200px] lg:w-[220px]">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
            <input
              aria-label="Search inventory, sensors, and alerts"
              className="h-9 w-full rounded-md border border-slate-200 bg-slate-50 pl-8 pr-8 text-[11px] text-slate-700 outline-none placeholder:text-slate-400 focus:border-teal-500 focus:bg-white"
              onChange={(event) => onSearch(event.target.value)}
              placeholder="Search inventory, sensors..."
              value={searchTerm}
            />
            {searchTerm && (
              <button aria-label="Clear search" className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" onClick={() => onSearch('')} type="button">
                <X size={12} />
              </button>
            )}
          </div>
        </div>
        <button aria-label="Toggle search" className="rounded-md border border-slate-200 p-2 text-slate-500 hover:bg-slate-50 sm:hidden" onClick={() => setSearchOpen((open) => !open)} type="button">
          <Search size={16} />
        </button>
        <div className="relative">
          <button
            aria-expanded={alertsOpen}
            aria-label={`Notifications${alertCount ? `, ${alertCount} unread` : ''}`}
            className="relative grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-600 hover:bg-slate-50"
            onClick={() => setAlertsOpen((open) => !open)}
            type="button"
          >
            <Bell size={15} />
            {alertCount > 0 && <span className="absolute right-[5px] top-[5px] h-1.5 w-1.5 rounded-full border border-white bg-rose-500" />}
          </button>
          {alertsOpen && (
            <div className="absolute right-0 top-[42px] z-50 w-[min(320px,calc(100vw-32px))] rounded-xl border border-slate-200 bg-white p-3 shadow-xl">
              <div className="mb-2 flex items-center justify-between">
                <p className="text-xs font-semibold text-slate-900">Notifications</p>
                <span className="text-[9px] text-slate-400">{alertCount} active</span>
              </div>
              <div className="max-h-64 space-y-1 overflow-y-auto">
                {alerts.length === 0 ? (
                  <p className="px-2 py-4 text-center text-xs text-slate-500">No active alerts.</p>
                ) : alerts.slice(0, 6).map((alert) => (
                  <div className="rounded-lg px-2 py-2 hover:bg-slate-50" key={alert.id}>
                    <p className="text-[10px] font-semibold text-slate-800">{alert.title}</p>
                    <p className="mt-1 text-[9px] text-slate-500">{alert.subtitle}</p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
        <button
          className="flex h-9 items-center gap-1.5 whitespace-nowrap rounded-md bg-teal-600 px-2.5 text-[10px] font-semibold text-white shadow-sm transition hover:bg-teal-700 sm:px-3.5 sm:text-[11px]"
          onClick={onQuickAdjustment}
          type="button"
        >
          <Plus size={14} />
          <span className="hidden sm:inline">Quick Adjustment</span>
          <span className="sm:hidden">Adjust</span>
        </button>
      </div>
    </header>
  )
}
