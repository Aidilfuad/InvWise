import { createContext, useContext } from 'react'

export const WORKSPACE_PERMISSION_KEYS = [
  'view_dashboard',
  'view_inventory',
  'create_inventory',
  'edit_inventory',
  'delete_inventory',
  'adjust_stock',
  'receive_stock',
  'issue_stock',
  'view_activity',
  'view_alerts',
  'view_reports',
  'export_reports',
  'view_telemetry',
  'manage_telemetry_thresholds',
  'manage_users',
  'manage_registration_requests',
  'manage_settings',
  'manage_departments',
  'manage_roles',
  'manage_categories',
  'manage_units',
  'manage_warehouses',
]

export const FALLBACK_PERMISSION_MAP = {
  'Super Admin': new Set(WORKSPACE_PERMISSION_KEYS),
  'Inventory Administrator': new Set([
    'view_dashboard', 'view_inventory', 'create_inventory', 'edit_inventory',
    'adjust_stock', 'receive_stock', 'issue_stock', 'view_activity',
    'view_alerts', 'view_reports', 'export_reports', 'view_telemetry',
    'manage_users', 'manage_registration_requests', 'manage_settings',
    'manage_categories', 'manage_units', 'manage_warehouses',
  ]),
  'Warehouse Supervisor': new Set([
    'view_dashboard', 'view_inventory', 'adjust_stock', 'receive_stock',
    'issue_stock', 'view_activity', 'view_alerts', 'view_reports',
    'export_reports', 'view_telemetry', 'manage_warehouses',
  ]),
  Storekeeper: new Set([
    'view_dashboard', 'view_inventory', 'adjust_stock', 'receive_stock',
    'issue_stock', 'view_alerts',
  ]),
}

export function isSuperAdminRole(role) {
  const normalized = String(role ?? '')
    .trim()
    .toLowerCase()
    .replace(/[_\-\s]+/g, '')
  return normalized === 'superadmin'
}

export const WorkspaceAccessContext = createContext({
  role: '',
  permissions: [],
  loaded: false,
  allows: () => false,
})

export function useWorkspaceAccess() {
  return useContext(WorkspaceAccessContext)
}
