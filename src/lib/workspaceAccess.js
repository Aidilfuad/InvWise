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

export const MANDATORY_WORKSPACE_PERMISSION_KEYS = [
  'view_inventory',
  'view_activity',
  'view_alerts',
  'view_reports',
  'view_telemetry',
  'manage_settings',
]

export const WORKSPACE_ROLE_ORDER = [
  'Super Admin',
  'Director',
  'Factory 1 Manager',
  'Factory 2 Manager',
  'Warehouse Manager',
  'Manager',
  'Supervisor',
  'Production Supervisor',
  'Quality Assurance / QC Supervisor',
  'Maintenance & Automation Lead',
  'Inventory Controller',
  'Warehouse Supervisor',
  'Storekeeper',
  'Viewer',
]

export function canReviewProfileChangeRequests(role) {
  const normalized = String(role ?? '').trim().toLowerCase().replace(/[_-]+/g, ' ')
  return [
    'manager',
    'factory 1 manager',
    'factory 2 manager',
    'warehouse manager',
    'director',
    'super admin',
  ].includes(normalized.replace(/\s+/g, ' '))
}

export function sortWorkspaceRoles(roles) {
  const rank = new Map(WORKSPACE_ROLE_ORDER.map((role, index) => [role, index]))
  const roleName = (role) => typeof role === 'string' ? role : role?.name ?? ''
  return [...roles].sort((left, right) => {
    const leftName = roleName(left)
    const rightName = roleName(right)
    const leftRank = rank.get(leftName) ?? WORKSPACE_ROLE_ORDER.length
    const rightRank = rank.get(rightName) ?? WORKSPACE_ROLE_ORDER.length
    return leftRank - rightRank || leftName.localeCompare(rightName)
  })
}

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
    'export_reports', 'view_telemetry', 'manage_settings', 'manage_warehouses',
  ]),
  Storekeeper: new Set([
    'view_dashboard', 'view_inventory', 'view_activity', 'view_alerts',
    'view_reports', 'view_telemetry', 'manage_settings', 'adjust_stock',
    'receive_stock', 'issue_stock',
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
