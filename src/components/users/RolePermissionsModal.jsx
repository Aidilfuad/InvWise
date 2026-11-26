import { useEffect, useState } from 'react'
import { LockKeyhole, Plus, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'
import { isSuperAdminRole, MANDATORY_WORKSPACE_PERMISSION_KEYS, sortWorkspaceRoles } from '../../lib/workspaceAccess'
import SearchableSelect from '../common/SearchableSelect'

const permissionGroups = [
  { title: 'Workspace', permissions: [
    ['view_dashboard', 'View dashboard'],
    ['view_inventory', 'View inventory'],
    ['view_activity', 'View activity'],
    ['view_alerts', 'View alerts'],
    ['view_reports', 'View reports'],
    ['view_telemetry', 'View telemetry'],
    ['manage_telemetry_thresholds', 'Manage telemetry thresholds'],
  ] },
  { title: 'Operations', permissions: [
    ['create_inventory', 'Create inventory'],
    ['edit_inventory', 'Edit inventory'],
    ['delete_inventory', 'Delete inventory'],
    ['adjust_stock', 'Adjust stock'],
    ['receive_stock', 'Receive stock'],
    ['issue_stock', 'Issue stock'],
    ['export_reports', 'Export reports'],
    ['manage_categories', 'Manage categories'],
    ['manage_units', 'Manage units'],
    ['manage_warehouses', 'Manage warehouses'],
  ] },
  { title: 'Administration', permissions: [
    ['manage_registration_requests', 'Manage registration requests'],
    ['manage_users', 'Manage users'],
    ['manage_roles', 'Manage roles'],
    ['manage_departments', 'Manage departments'],
    ['manage_settings', 'Manage settings'],
  ] },
]

export default function RolePermissionsModal({ onClose, initialTab = 'permissions' }) {
  const [roles, setRoles] = useState([])
  const [departments, setDepartments] = useState([])
  const [permissions, setPermissions] = useState([])
  const [draftPermissions, setDraftPermissions] = useState({})
  const [selectedRole, setSelectedRole] = useState('')
  const [tab, setTab] = useState(initialTab)
  const [roleName, setRoleName] = useState('')
  const [roleDescription, setRoleDescription] = useState('')
  const [roleScope, setRoleScope] = useState('')
  const [departmentName, setDepartmentName] = useState('')
  const [departmentDescription, setDepartmentDescription] = useState('')
  const [initialRolePermissions, setInitialRolePermissions] = useState(
    () => new Set(['view_dashboard', ...MANDATORY_WORKSPACE_PERMISSION_KEYS]),
  )
  const [error, setError] = useState('')
  const [pending, setPending] = useState(false)

  async function loadCatalog() {
    if (!supabase) return
    const [roleResult, departmentResult, permissionResult] = await Promise.all([
      supabase.from('custom_roles').select('id,name,description,scope,is_active').eq('is_active', true).order('name'),
      supabase.from('departments').select('id,name,description,is_active').eq('is_active', true).order('name'),
      supabase.from('role_permissions').select('role_name,permission_key,granted'),
    ])
    if (roleResult.error || departmentResult.error || permissionResult.error) {
      setError(roleResult.error?.message || departmentResult.error?.message || permissionResult.error?.message)
      return
    }
    setRoles(sortWorkspaceRoles(roleResult.data ?? []))
    setDepartments(departmentResult.data ?? [])
    setPermissions(permissionResult.data ?? [])
    const nextSelected = selectedRole || roleResult.data?.[0]?.name || ''
    setSelectedRole(nextSelected)
    if (nextSelected) {
      setDraftPermissions(Object.fromEntries(
        permissionGroups.flatMap((group) => group.permissions).map(([key]) => [
          key,
          isSuperAdminRole(nextSelected) ||
            MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(key) ||
            (permissionResult.data ?? []).some((item) =>
              item.role_name === nextSelected &&
              item.permission_key === key &&
              item.granted),
        ]),
      ))
    }
  }

  useEffect(() => {
    if (!supabase) return
    void Promise.all([
      supabase.from('custom_roles').select('id,name,description,scope,is_active').eq('is_active', true).order('name'),
      supabase.from('departments').select('id,name,description,is_active').eq('is_active', true).order('name'),
      supabase.from('role_permissions').select('role_name,permission_key,granted'),
    ]).then(([roleResult, departmentResult, permissionResult]) => {
      if (roleResult.error || departmentResult.error || permissionResult.error) {
        setError(roleResult.error?.message || departmentResult.error?.message || permissionResult.error?.message)
        return
      }
      setRoles(sortWorkspaceRoles(roleResult.data ?? []))
      setDepartments(departmentResult.data ?? [])
      setPermissions(permissionResult.data ?? [])
      setSelectedRole((current) => {
        const next = current || roleResult.data?.[0]?.name || ''
        setDraftPermissions(Object.fromEntries(
          permissionGroups.flatMap((group) => group.permissions).map(([key]) => [
            key,
            isSuperAdminRole(next) ||
              MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(key) ||
              (permissionResult.data ?? []).some((item) =>
                item.role_name === next &&
                item.permission_key === key &&
                item.granted),
          ]),
        ))
        return next
      })
    })
  }, [])

  function isGranted(permissionKey) {
    if (
      isSuperAdminRole(selectedRole) ||
      MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(permissionKey)
    ) return true
    if (Object.prototype.hasOwnProperty.call(draftPermissions, permissionKey)) {
      return draftPermissions[permissionKey]
    }
    return permissions.some((item) => item.role_name === selectedRole && item.permission_key === permissionKey && item.granted)
  }

  function togglePermission(permissionKey) {
    if (
      isSuperAdminRole(selectedRole) ||
      MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(permissionKey)
    ) return
    setDraftPermissions((current) => ({
      ...current,
      [permissionKey]: !isGranted(permissionKey),
    }))
  }

  async function applyPermissions() {
    if (!supabase || pending || !selectedRole || isSuperAdminRole(selectedRole)) return
    setPending(true)
    setError('')
    try {
      for (const [key, granted] of Object.entries(draftPermissions)) {
        const { error: rpcError } = await supabase.rpc('set_role_permission', {
          p_role_name: selectedRole,
          p_permission_key: key,
          p_granted: granted,
        })
        if (rpcError) throw rpcError
      }
      await loadCatalog()
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to apply permissions.')
    } finally {
      setPending(false)
    }
  }

  async function addRole(event) {
    event.preventDefault()
    setPending(true)
    setError('')
    try {
      const { error: rpcError } = await supabase.rpc('upsert_workspace_role', {
        p_name: roleName,
        p_description: roleDescription,
        p_scope: roleScope,
        p_is_active: true,
      })
      if (rpcError) throw rpcError
      for (const permissionKey of initialRolePermissions) {
        const { error: permissionError } = await supabase.rpc('set_role_permission', {
          p_role_name: roleName.trim(),
          p_permission_key: permissionKey,
          p_granted: true,
        })
        if (permissionError) throw permissionError
      }
      setRoleName('')
      setRoleDescription('')
      setRoleScope('')
      await loadCatalog()
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to add role.')
    } finally {
      setPending(false)
    }
  }

  async function addDepartment(event) {
    event.preventDefault()
    setPending(true)
    setError('')
    try {
      const { error: rpcError } = await supabase.rpc('upsert_workspace_department', {
        p_name: departmentName,
        p_description: departmentDescription,
        p_is_active: true,
      })
      if (rpcError) throw rpcError
      setDepartmentName('')
      setDepartmentDescription('')
      await loadCatalog()
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to add department.')
    } finally {
      setPending(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[80] grid place-items-center overflow-y-auto bg-slate-950/45 p-4" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose() }}>
      <section aria-modal="true" className="my-auto w-full max-w-[920px] overflow-hidden rounded-xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-50 text-teal-700"><LockKeyhole size={15} /></span>
            <div><h2 className="text-sm font-bold text-slate-900">Role & access management</h2><p className="mt-1 text-[10px] text-slate-500">Create departments and roles, then grant or revoke permissions.</p></div>
          </div>
          <button aria-label="Close access management" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100" onClick={onClose} type="button"><X size={15} /></button>
        </header>
        <div className="flex gap-2 border-b border-slate-100 px-5 py-3">
          {['permissions', 'roles', 'departments'].map((value) => (
            <button className={`rounded-md px-3 py-1.5 text-[10px] font-semibold ${tab === value ? 'bg-teal-600 text-white' : 'bg-slate-100 text-slate-600'}`} key={value} onClick={() => setTab(value)} type="button">{value[0].toUpperCase() + value.slice(1)}</button>
          ))}
        </div>
        <div className="max-h-[60vh] overflow-y-auto p-5">
          {tab === 'permissions' && (
            <div>
              <label className="block text-[10px] font-semibold text-slate-700">Role
                <span className="mt-1.5 block">
                  <SearchableSelect
                    aria-label="Role"
                    className="modal-input"
                    onChange={(next) => {
                  setSelectedRole(next)
                  setDraftPermissions(Object.fromEntries(
                    permissionGroups.flatMap((group) => group.permissions).map(([key]) => [
                      key,
                      isSuperAdminRole(next) ||
                        MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(key) ||
                        permissions.some((item) =>
                          item.role_name === next &&
                          item.permission_key === key &&
                          item.granted),
                    ]),
                  ))
                    }}
                    options={roles.map((role) => ({ value: role.name, label: role.name }))}
                    value={selectedRole}
                  />
                </span>
              </label>
              <div className="mt-4 space-y-4">
                {permissionGroups.map((group) => (
                  <div className="overflow-hidden rounded-lg border border-slate-200" key={group.title}>
                    <p className="bg-slate-50 px-3 py-2 text-[9px] font-bold text-slate-700">{group.title}</p>
                    {group.permissions.map(([key, label]) => (
                      <label className="flex items-center justify-between border-t border-slate-100 px-3 py-2.5 text-[10px] text-slate-700" key={key}>
                        {label}
                        <input checked={isGranted(key)} disabled={pending || !selectedRole || isSuperAdminRole(selectedRole)} onChange={() => togglePermission(key)} type="checkbox" />
                      </label>
                    ))}
                  </div>
                ))}
              </div>
            </div>
          )}
          {tab === 'roles' && (
            <div className="grid gap-5 sm:grid-cols-2">
              <form className="space-y-3" onSubmit={addRole}>
                <p className="text-[10px] font-bold text-slate-700">Add or update role</p>
                <input className="modal-input" maxLength={100} onChange={(event) => setRoleName(event.target.value)} placeholder="Role name" required value={roleName} />
                <input className="modal-input" maxLength={500} onChange={(event) => setRoleDescription(event.target.value)} placeholder="Description / scope" value={roleDescription} />
                <input className="modal-input" maxLength={100} onChange={(event) => setRoleScope(event.target.value)} placeholder="Warehouse scope" value={roleScope} />
                <fieldset className="rounded-lg border border-slate-200 p-3">
                  <legend className="px-1 text-[9px] font-bold text-slate-700">Initial permissions</legend>
                  {permissionGroups.flatMap((group) => group.permissions).map(([key, label]) => (
                    <label className="flex items-center justify-between border-t border-slate-100 py-1.5 text-[9px] text-slate-600" key={key}>
                      {label}
                      <input checked={MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(key) || initialRolePermissions.has(key)} disabled={MANDATORY_WORKSPACE_PERMISSION_KEYS.includes(key)} onChange={(event) => setInitialRolePermissions((current) => {
                        const next = new Set(current)
                        if (event.target.checked) next.add(key)
                        else next.delete(key)
                        return next
                      })} type="checkbox" />
                    </label>
                  ))}
                </fieldset>
                <button className="inline-flex h-9 items-center gap-1.5 rounded-md bg-teal-600 px-3 text-[10px] font-semibold text-white" disabled={pending} type="submit"><Plus size={12} /> Save role</button>
              </form>
              <div>{roles.map((role) => <article className="mb-2 rounded-lg border border-slate-200 p-3" key={role.id}><p className="text-[10px] font-bold text-slate-800">{role.name}</p><p className="mt-1 text-[9px] text-slate-500">{role.description || role.scope || 'No description'}</p></article>)}</div>
            </div>
          )}
          {tab === 'departments' && (
            <div className="grid gap-5 sm:grid-cols-2">
              <form className="space-y-3" onSubmit={addDepartment}>
                <p className="text-[10px] font-bold text-slate-700">Add or update department</p>
                <input className="modal-input" maxLength={100} onChange={(event) => setDepartmentName(event.target.value)} placeholder="Department name" required value={departmentName} />
                <input className="modal-input" maxLength={500} onChange={(event) => setDepartmentDescription(event.target.value)} placeholder="Description" value={departmentDescription} />
                <button className="inline-flex h-9 items-center gap-1.5 rounded-md bg-teal-600 px-3 text-[10px] font-semibold text-white" disabled={pending} type="submit"><Plus size={12} /> Save department</button>
              </form>
              <div>{departments.map((department) => <article className="mb-2 rounded-lg border border-slate-200 p-3" key={department.id}><p className="text-[10px] font-bold text-slate-800">{department.name}</p><p className="mt-1 text-[9px] text-slate-500">{department.description || 'No description'}</p></article>)}</div>
            </div>
          )}
          {error && <p className="mt-4 rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
        </div>
        <footer className="flex justify-end gap-2 border-t border-slate-100 px-5 py-3">
          {tab === 'permissions' && !isSuperAdminRole(selectedRole) && (
            <button className="h-8 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white disabled:opacity-60" disabled={pending || !selectedRole} onClick={applyPermissions} type="button">{pending ? 'Applying…' : 'Apply permission changes'}</button>
          )}
          <button className="h-8 rounded-md border border-slate-200 px-4 text-[10px] font-semibold text-slate-600" onClick={onClose} type="button">Done</button>
        </footer>
      </section>
    </div>
  )
}
