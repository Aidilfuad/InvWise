import { Link, useLocation } from 'react-router-dom'
import { useWorkspaceAccess } from '../../lib/workspaceAccess'
import { DEFAULT_WORKSPACE_NAME, useWorkspaceName } from '../../lib/workspaceName'
import { getProfileAvatarUrl } from '../../lib/profileAvatar'
import {
  Activity,
  Boxes,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  ClipboardList,
  Grid2X2,
  LogOut,
  Package,
  Settings,
  UsersRound,
  Warehouse,
  X,
} from 'lucide-react'

const navigationGroups = [
  {
    label: 'WORKSPACE',
    items: [
      { label: 'Dashboard', path: '/dashboard', Icon: Grid2X2 },
      { label: 'Inventory', path: '/inventory', Icon: Boxes },
      {
        label: 'Activity & Reports',
        path: '/activity-logs',
        activePaths: ['/activity-logs', '/alerts', '/reports'],
        Icon: ClipboardList,
        showAlertCount: true,
      },
      { label: 'Telemetry & Sensors', path: '/telemetry', Icon: Activity },
      { label: 'User Management', path: '/users', Icon: UsersRound },
      { label: 'Settings', path: '/settings', Icon: Settings },
    ],
  },
]

export default function WorkspaceSidebar({
  alertCount,
  collapsed,
  mobileOpen,
  onClose,
  onSignOut,
  onToggleCollapse,
  profile,
  signOutPending,
  warehouses,
}) {
  const [workspace, setWorkspaceName] = useWorkspaceName()
  const access = useWorkspaceAccess()
  const location = useLocation()
  const currentPath = location.pathname.replace(/\/+$/, '') || '/'

  const permissionByPath = {
    '/dashboard': 'view_dashboard',
    '/inventory': 'view_inventory',
    '/activity-logs': 'view_activity',
    '/telemetry': 'view_telemetry',
    '/users': 'manage_users',
    '/settings': 'manage_settings',
  }

  return (
    <>
      {mobileOpen && (
        <button
          aria-label="Close navigation"
          className="fixed inset-0 z-40 bg-slate-950/60 lg:hidden"
          onClick={onClose}
          type="button"
        />
      )}
      <aside
        className={`fixed inset-y-0 left-0 z-50 flex w-60 flex-col border-r border-slate-800 bg-[#0b1220] px-4 py-5 text-slate-300 transition-[width,transform,padding] duration-200 ${
          mobileOpen ? 'translate-x-0 visible' : '-translate-x-full invisible'
        } ${collapsed ? 'lg:w-16 lg:px-2' : 'lg:w-60'} lg:visible lg:translate-x-0`}
      >
        <div className={`flex items-center justify-between px-1.5 ${collapsed ? 'lg:justify-center lg:px-0' : ''}`}>
          <div className="flex items-center gap-2.5">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-600 text-white">
              <Package size={18} strokeWidth={2} />
            </span>
            <span className={`text-[21px] font-bold tracking-[-0.035em] text-white ${collapsed ? 'lg:hidden' : ''}`}>InvWise</span>
          </div>
          {!collapsed && <button aria-label="Collapse sidebar" className="hidden rounded-md p-1 text-slate-400 hover:bg-slate-800 lg:block" onClick={onToggleCollapse} title="Collapse sidebar" type="button">
            <ChevronLeft size={14} />
          </button>}
          <button aria-label="Close navigation" className="rounded-md p-1 text-slate-400 hover:bg-slate-800 lg:hidden" onClick={onClose} type="button">
            <X size={18} />
          </button>
        </div>

        {collapsed && <button aria-label="Expand sidebar" className="mx-auto mt-2 hidden rounded-md p-1 text-slate-400 hover:bg-slate-800 hover:text-white lg:block" onClick={onToggleCollapse} title="Expand sidebar" type="button"><ChevronRight size={14} /></button>}

        <div className={`mt-7 ${collapsed ? 'lg:hidden' : ''}`}>
          <label className="mb-2 block px-1.5 text-[9px] font-semibold uppercase tracking-[0.12em] text-slate-500" htmlFor="workspace-selector">
            Enterprise workspace
          </label>
          <div className="relative">
            <Warehouse className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={14} />
            <select
              className="h-9 w-full appearance-none rounded-md border border-slate-700/80 bg-[#131c31] pl-8 pr-8 text-[11px] text-slate-100 outline-none focus:border-teal-500"
              id="workspace-selector"
              onChange={(event) => setWorkspaceName(event.target.value)}
              value={workspace}
            >
              {workspace !== DEFAULT_WORKSPACE_NAME && !warehouses.some((location) => location.name === workspace) && (
                <option value={workspace}>{workspace || 'Unnamed workspace'}</option>
              )}
              <option value={DEFAULT_WORKSPACE_NAME}>{DEFAULT_WORKSPACE_NAME}</option>
              {warehouses.map((location) => (
                <option key={location.id} value={location.name}>{location.name}</option>
              ))}
            </select>
            <ChevronDown className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={12} />
          </div>
        </div>

        <nav aria-label="Primary navigation" className={`mt-5 space-y-3 ${collapsed ? 'lg:mt-4 lg:space-y-2' : ''}`}>
          {navigationGroups.map(({ items, label: groupLabel }, groupIndex) => (
            <section aria-label={groupLabel} className="space-y-1" key={groupLabel}>
              {groupIndex > 0 && <div aria-hidden="true" className="mx-2 mb-2 border-t border-slate-800 lg:mx-1" />}
              <p className={`px-2 pb-1 text-[9px] font-semibold uppercase tracking-[0.12em] text-slate-500 ${collapsed ? 'lg:hidden' : ''}`}>
                {groupLabel}
              </p>
              {items.filter(({ path }) => access.allows(permissionByPath[path])).map(({ Icon, label, path, activePaths, showAlertCount }) => {
                const active = activePaths
                  ? activePaths.includes(currentPath)
                  : currentPath === path
                return (
                  <Link
                    aria-current={active ? 'page' : undefined}
                    aria-description={showAlertCount && alertCount > 0 ? `${alertCount} active alerts` : undefined}
                    aria-label={label}
                    className={`group relative flex h-[38px] items-center rounded-md text-[11px] transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-400 ${
                      collapsed ? 'gap-2.5 px-2.5 lg:justify-center lg:px-0' : 'gap-2.5 px-2.5'
                    } ${
                      active
                        ? 'bg-[#0d9488] font-semibold text-white shadow-sm shadow-teal-950/20'
                        : 'text-slate-400 hover:bg-slate-800 hover:text-white'
                    }`}
                    key={path}
                    onClick={onClose}
                    title={collapsed ? `${label}${showAlertCount && alertCount > 0 ? ` · ${alertCount} active` : ''}` : undefined}
                    to={path}
                  >
                    <Icon className="shrink-0" size={15} strokeWidth={1.9} />
                    <span className={`flex-1 ${collapsed ? 'lg:hidden' : ''}`}>{label}</span>
                    {showAlertCount && alertCount > 0 && (
                      <span className={`grid h-4 min-w-4 place-items-center rounded bg-rose-500/20 px-1 text-[9px] font-semibold text-rose-300 ${collapsed ? 'lg:absolute lg:right-0.5 lg:top-0' : ''}`}>
                        {alertCount}
                      </span>
                    )}
                  </Link>
                )
              })}
            </section>
          ))}
        </nav>

        <a
          aria-label="Download InvWise app version 2.3.0 from GitHub Releases"
          className={`mt-4 inline-flex h-9 items-center rounded-md border border-slate-700/80 bg-[#131c31] text-[10px] font-semibold text-slate-200 transition-colors hover:border-slate-600 hover:bg-slate-800 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-400 ${
            collapsed ? 'justify-center gap-0 px-0 lg:mx-auto lg:w-10' : 'gap-2.5 px-2.5'
          }`}
          href="https://github.com/Aidilfuad/InvWise/releases/tag/v2.3.0"
          onClick={onClose}
          rel="noopener noreferrer"
          target="_blank"
          title={collapsed ? 'Download InvWise app v2.3.0' : undefined}
        >
          <svg aria-hidden="true" className="shrink-0" fill="currentColor" height="15" viewBox="0 0 24 24" width="15">
            <path d="M12 .8a11.2 11.2 0 0 0-3.54 21.83c.56.1.77-.24.77-.54v-2.1c-3.13.68-3.79-1.33-3.79-1.33-.51-1.3-1.25-1.65-1.25-1.65-1.02-.7.08-.69.08-.69 1.13.08 1.72 1.16 1.72 1.16 1 .1.56 2.44 3.42 1.71.1-.73.39-1.23.7-1.52-2.5-.29-5.13-1.25-5.13-5.56 0-1.23.44-2.23 1.16-3.02-.12-.29-.5-1.44.11-2.99 0 0 .95-.3 3.08 1.15a10.7 10.7 0 0 1 5.61 0c2.13-1.45 3.08-1.15 3.08-1.15.61 1.55.23 2.7.11 2.99.72.79 1.16 1.79 1.16 3.02 0 4.32-2.63 5.27-5.14 5.55.4.35.75 1.03.75 2.08v3.08c0 .3.2.65.78.54A11.2 11.2 0 0 0 12 .8Z" />
          </svg>
          <span className={collapsed ? 'lg:hidden' : ''}>Download app v2.3.0</span>
        </a>

        <div className="mt-auto">
          {!collapsed ? <div>
          <div className="flex items-center gap-2 px-1.5">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
            <span className="text-[10px] text-slate-400">All systems operational</span>
          </div>
          <p className="mt-1 pl-4 text-[9px] text-slate-500">Last synced just now</p>

          <div className="mt-4 flex items-center gap-2.5 border-t border-slate-800 pt-3">
            <span className="relative grid h-9 w-9 shrink-0 place-items-center overflow-hidden rounded-lg bg-[#131c31] text-[10px] font-semibold text-slate-100">
              {(profile?.full_name?.trim() || 'A').split(/\s+/).slice(0, 2).map((part) => part[0]).join('')}
              {profile?.avatar_url && <img alt="" className="absolute inset-0 h-full w-full object-cover" onError={(event) => { event.currentTarget.style.display = 'none' }} src={getProfileAvatarUrl(profile.avatar_url)} />}
            </span>
            <div className="min-w-0 flex-1 rounded-lg bg-[#131c31] px-3 py-2.5">
              <p className="truncate text-[11px] font-semibold text-slate-100">{profile?.full_name?.trim() || 'Alex Mercer'}</p>
              <p className="mt-0.5 truncate text-[9px] text-slate-400">{profile?.role || 'Super Admin'}</p>
            </div>
            <button
              aria-label="Sign out"
              className="rounded-md p-2 text-slate-400 hover:bg-slate-800 hover:text-white disabled:opacity-50"
              disabled={signOutPending}
              onClick={onSignOut}
              type="button"
            >
              <LogOut size={15} />
            </button>
          </div>
          </div> : <div className="flex flex-col items-center gap-2 border-t border-slate-800 pt-3">
            <span aria-label="All systems operational" className="h-1.5 w-1.5 rounded-full bg-emerald-400" title="All systems operational" />
            <span className="text-[8px] text-slate-500">Live</span>
            <span aria-label={profile?.full_name?.trim() || 'Alex Mercer'} className="relative grid h-8 w-8 place-items-center overflow-hidden rounded-lg bg-[#131c31] text-[9px] font-semibold text-slate-100" title={profile?.full_name?.trim() || 'Alex Mercer'}>
              {(profile?.full_name?.trim() || 'Alex Mercer').split(/\s+/).slice(0, 2).map((part) => part[0]).join('')}
              {profile?.avatar_url && <img alt="" className="absolute inset-0 h-full w-full object-cover" onError={(event) => { event.currentTarget.style.display = 'none' }} src={getProfileAvatarUrl(profile.avatar_url)} />}
            </span>
            <button aria-label="Sign out" className="rounded-md p-2 text-slate-400 hover:bg-slate-800 hover:text-white disabled:opacity-50" disabled={signOutPending} onClick={onSignOut} title="Sign out" type="button"><LogOut size={15} /></button>
          </div>}
        </div>
      </aside>
    </>
  )
}
