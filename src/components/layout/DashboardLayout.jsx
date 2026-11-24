import { useMemo, useState } from 'react'
import { Outlet, useLocation, useNavigate } from 'react-router-dom'
import AddInventoryModal from '../dashboard/AddInventoryModal'
import QuickAdjustmentModal from '../dashboard/QuickAdjustmentModal'
import useDashboardData from '../dashboard/useDashboardData'
import DashboardHeader from './DashboardHeader'
import WorkspaceSidebar from './WorkspaceSidebar'
import { supabase } from '../../lib/supabase'
import { useWorkspaceName } from '../../lib/workspaceName'

const roleLabels = {
  admin: 'Administrator',
  super_admin: 'Super Admin',
  manager: 'Manager',
  warehouse_manager: 'Warehouse Manager',
  inventory_manager: 'Inventory Manager',
  staff: 'Staff',
  user: 'Staff',
  viewer: 'Viewer',
}

function formatRole(role) {
  const normalized = String(role ?? '').trim().toLowerCase().replace(/[\s-]+/g, '_')
  if (!normalized) return 'Super Admin'
  return roleLabels[normalized] ?? normalized.replace(/_/g, ' ').replace(/\b\w/g, (letter) => letter.toUpperCase())
}

export default function DashboardLayout({ session }) {
  const dashboard = useDashboardData(session)
  const [mobileSidebarOpen, setMobileSidebarOpen] = useState(false)
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false)
  const [searchTerm, setSearchTerm] = useState('')
  const [modal, setModal] = useState(null)
  const [signOutPending, setSignOutPending] = useState(false)
  const [layoutError, setLayoutError] = useState('')
  const [workspaceName] = useWorkspaceName()
  const location = useLocation()
  const navigate = useNavigate()
  const currentPath = location.pathname.replace(/\/+$/, '') || '/'
  const isActivityHub = ['/activity-logs', '/alerts', '/reports'].includes(currentPath)
  const hideGlobalHeader = currentPath === '/inventory' || currentPath === '/stock-adjustment' || currentPath === '/telemetry' || currentPath === '/users' || currentPath === '/settings' || isActivityHub

  const profile = useMemo(() => ({
    full_name: dashboard.data.profile?.full_name || 'Alex Mercer',
    role: formatRole(dashboard.data.profile?.role),
    avatar_url: dashboard.data.profile?.avatar_url || '',
  }), [dashboard.data.profile])
  const visibleAlerts = dashboard.data.alerts.filter((alert) => (
    !searchTerm.trim() ||
    `${alert.title} ${alert.subtitle} ${alert.message}`.toLowerCase().includes(searchTerm.trim().toLowerCase())
  ))

  async function signOut() {
    if (signOutPending) return
    setSignOutPending(true)
    setLayoutError('')
    try {
      if (supabase) {
        const { error } = await supabase.auth.signOut()
        if (error) throw error
      }
      navigate('/login', { replace: true })
    } catch (error) {
      setLayoutError(error instanceof Error ? error.message : 'Unable to sign out. Please try again.')
    } finally {
      setSignOutPending(false)
    }
  }

  const outletContext = {
    session,
    data: dashboard.data,
    workspaceName,
    source: dashboard.source,
    loading: dashboard.loading,
    refresh: dashboard.refresh,
    searchTerm,
    setGlobalSearchTerm: setSearchTerm,
    openAdjustment: (item) => setModal({ type: 'adjustment', item }),
    openAddInventory: () => setModal({ type: 'add-inventory' }),
    openMobileSidebar: () => setMobileSidebarOpen(true),
    recordStockMovement: dashboard.recordStockMovement,
    saveInventoryItem: dashboard.saveInventoryItem,
    archiveInventoryItem: dashboard.archiveInventoryItem,
    saveCategory: dashboard.saveCategory,
    setCategoryActive: dashboard.setCategoryActive,
    saveUnit: dashboard.saveUnit,
    setUnitActive: dashboard.setUnitActive,
    navigate,
  }

  return (
    <div className="min-h-screen bg-[#f7f9fc] text-slate-800">
      <WorkspaceSidebar
        alertCount={dashboard.data.activeAlertCount}
        collapsed={sidebarCollapsed}
        mobileOpen={mobileSidebarOpen}
        onClose={() => setMobileSidebarOpen(false)}
        onSignOut={signOut}
        onToggleCollapse={() => setSidebarCollapsed((value) => !value)}
        profile={profile}
        signOutPending={signOutPending}
        warehouses={dashboard.data.warehouses}
      />
      <div className={`min-h-screen transition-[margin] duration-200 ${sidebarCollapsed ? 'lg:ml-16' : 'lg:ml-60'}`}>
        {!hideGlobalHeader && (
          <DashboardHeader
            alertCount={dashboard.data.activeAlertCount}
            alerts={visibleAlerts}
            location={location}
            onMenu={() => setMobileSidebarOpen(true)}
            onQuickAdjustment={() => setModal({ type: 'adjustment' })}
            onSearch={setSearchTerm}
            profile={profile}
            searchTerm={searchTerm}
          />
        )}
        {(dashboard.error || layoutError) && (
          <div className="mx-4 mt-3 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-[10px] text-amber-800 sm:mx-7" role="status">
            {layoutError || dashboard.error}
          </div>
        )}
        <Outlet context={outletContext} />
      </div>

      {modal?.type === 'adjustment' && (
        <QuickAdjustmentModal
          items={dashboard.data.items}
          locations={dashboard.data.warehouses}
          onClose={() => setModal(null)}
          onSubmit={dashboard.adjustStock}
          presetItem={modal.item}
        />
      )}
      {modal?.type === 'add-inventory' && (
        <AddInventoryModal
          categories={dashboard.data.categories}
          items={dashboard.data.items}
          locations={dashboard.data.warehouses}
          onClose={() => setModal(null)}
          onSubmit={dashboard.addInventory}
          units={dashboard.data.units}
        />
      )}
    </div>
  )
}
