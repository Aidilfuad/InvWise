import { useCallback, useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from '../../lib/supabase'
import { getSupabaseFunctionErrorMessage } from '../../lib/supabaseFunctionErrors'
import { sortWorkspaceRoles } from '../../lib/workspaceAccess'

function messageFrom(error, fallback) {
  const responseMessage = error?.context?.body?.error ?? error?.context?.body?.message
  if (typeof responseMessage === 'string' && responseMessage.trim()) return responseMessage
  if (typeof error?.message === 'string' && error.message.trim()) return error.message
  return error instanceof Error ? error.message : fallback
}

async function loadUsers() {
  const { data, error } = await supabase.functions.invoke('manage-users', { body: { action: 'list' } })
  if (error) {
    throw new Error(await getSupabaseFunctionErrorMessage(error, 'Unable to load the user directory.'))
  }
  if (data?.error) throw new Error(data.error)
  if (!Array.isArray(data?.users)) throw new Error('The user management service returned an invalid user list.')
  return data.users.map((user) => ({
    ...user,
    full_name: user.full_name ?? 'Unnamed user',
    email: user.email ?? '',
    employee_id: user.employee_id ?? '—',
    role: user.role ?? '',
    is_active: user.is_active === true,
    warehouse: null,
    accessScope: user.role === 'Super Admin' || user.role === 'Inventory Administrator'
      ? 'All warehouses'
      : 'Role-based access',
  }))
}

export default function useUserManagementData() {
  const [users, setUsers] = useState([])
  const [requests, setRequests] = useState([])
  const [provisioningFailures, setProvisioningFailures] = useState([])
  const [source, setSource] = useState('unavailable')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [rolesCatalog, setRolesCatalog] = useState([])
  const [departmentsCatalog, setDepartmentsCatalog] = useState([])

  const reload = useCallback(async () => {
    if (!supabase || !isSupabaseConfigured) {
      setUsers([])
      setRequests([])
      setProvisioningFailures([])
      setRolesCatalog([])
      setDepartmentsCatalog([])
      setSource('unavailable')
      setError('Connect to Supabase to load User Management data.')
      setLoading(false)
      return []
    }

    setLoading(true)
    const [usersResult, requestsResult, failuresResult, rolesResult, departmentsResult] = await Promise.allSettled([
      loadUsers(),
      supabase.from('registration_requests')
        .select('id,full_name,employee_id,email,department,requested_role,status,created_at,reason')
        .eq('status', 'pending')
        .order('created_at', { ascending: true }),
      supabase.from('registration_requests')
        .select('id,full_name,employee_id,email,department,requested_role,provisioning_status,provisioning_error,created_at')
        .eq('status', 'approved')
        .eq('provisioning_status', 'failed')
        .order('created_at', { ascending: false }),
      supabase.from('custom_roles').select('id,name,description,scope,is_active').eq('is_active', true).order('name'),
      supabase.from('departments').select('id,name,description,is_active').eq('is_active', true).order('name'),
    ])

    const issues = []
    let loadedUsers = []
    if (usersResult.status === 'fulfilled') {
      loadedUsers = usersResult.value
      setUsers(loadedUsers)
    } else {
      setUsers([])
      issues.push(`User directory: ${messageFrom(usersResult.reason, 'unavailable')}`)
    }

    if (requestsResult.status === 'fulfilled' && !requestsResult.value.error) {
      setRequests(requestsResult.value.data ?? [])
    } else {
      setRequests([])
      const requestError = requestsResult.status === 'rejected' ? requestsResult.reason : requestsResult.value.error
      issues.push(`Registration requests: ${messageFrom(requestError, 'unavailable')}`)
    }

    if (failuresResult.status === 'fulfilled' && !failuresResult.value.error) {
      setProvisioningFailures(failuresResult.value.data ?? [])
    } else {
      setProvisioningFailures([])
      const failureError = failuresResult.status === 'rejected' ? failuresResult.reason : failuresResult.value.error
      issues.push(`Failed provisioning requests: ${messageFrom(failureError, 'unavailable')}`)
    }

    if (rolesResult.status === 'fulfilled' && !rolesResult.value.error) {
      setRolesCatalog(sortWorkspaceRoles((rolesResult.value.data ?? []).map((role) => role.name)))
    } else {
      setRolesCatalog([])
      const roleError = rolesResult.status === 'rejected' ? rolesResult.reason : rolesResult.value.error
      issues.push(`Workspace roles: ${messageFrom(roleError, 'unavailable')}`)
    }

    if (departmentsResult.status === 'fulfilled' && !departmentsResult.value.error) {
      setDepartmentsCatalog((departmentsResult.value.data ?? []).map((department) => department.name))
    } else {
      setDepartmentsCatalog([])
      const departmentError = departmentsResult.status === 'rejected' ? departmentsResult.reason : departmentsResult.value.error
      issues.push(`Departments: ${messageFrom(departmentError, 'unavailable')}`)
    }

    const usersLive = usersResult.status === 'fulfilled'
    const requestsLive = requestsResult.status === 'fulfilled' && !requestsResult.value.error
    const failuresLive = failuresResult.status === 'fulfilled' && !failuresResult.value.error
    setSource(usersLive && requestsLive && failuresLive ? 'live' : 'partial')
    setError(issues.length ? `Live User Management data is partially unavailable. ${issues.join(' ')}` : '')
    setLoading(false)
    return loadedUsers
  }, [])

  useEffect(() => {
    let active = true
    void Promise.resolve().then(() => active ? reload() : undefined).catch((loadError) => {
      if (!active) return
      setUsers([])
      setRequests([])
      setProvisioningFailures([])
      setRolesCatalog([])
      setDepartmentsCatalog([])
      setSource('unavailable')
      setError(`Unable to load User Management data. ${messageFrom(loadError, 'Please try again.')}`)
      setLoading(false)
    })
    return () => { active = false }
  }, [reload])

  const invokeUserAction = useCallback(async (body) => {
    if (!supabase || !isSupabaseConfigured) {
      throw new Error('User management requires a configured Supabase connection.')
    }
    const { data, error: invokeError } = await supabase.functions.invoke('manage-users', { body })
    if (invokeError) {
      throw new Error(await getSupabaseFunctionErrorMessage(invokeError, 'User management request failed.'))
    }
    if (data?.error) throw new Error(data.error)
    return data
  }, [])

  return {
    users,
    requests,
    provisioningFailures,
    rolesCatalog,
    departmentsCatalog,
    source,
    loading,
    error,
    reload,
    invokeUserAction,
  }
}
