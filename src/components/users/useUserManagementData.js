import { useCallback, useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from '../../lib/supabase'

const roles = ['Super Admin', 'Inventory Administrator', 'Warehouse Supervisor', 'Storekeeper']
const fallbackDepartments = [
  'Warehouse Operations',
  'Inventory Control',
  'Telemetry & Maintenance',
  'Logistics & Distribution',
  'Quality & Compliance',
  'Administration',
]
const sampleWarehouses = ['Shah Alam', 'Klang', 'Johor Bahru', 'Penang']
const samplePeople = [
  ['Aidil Fuad', 'EMP-001', 'aidil.fuad@acme.my', 'Super Admin'],
  ['Nur Aisyah', 'EMP-008', 'nur.aisyah@acme.my', 'Inventory Administrator'],
  ['Daniel Lee', 'EMP-012', 'daniel.lee@acme.my', 'Warehouse Supervisor'],
  ['Siti Aminah', 'EMP-019', 'siti.aminah@acme.my', 'Warehouse Supervisor'],
  ['Jason Tan', 'EMP-024', 'jason.tan@acme.my', 'Storekeeper'],
  ['Mei Ling', 'EMP-029', 'mei.ling@acme.my', 'Storekeeper'],
]

const sampleUsers = Array.from({ length: 45 }, (_, index) => {
  const person = samplePeople[index] ?? [
    `Workspace User ${String(index + 1).padStart(2, '0')}`,
    `EMP-${String(index + 30).padStart(3, '0')}`,
    `user${index + 1}@acme.my`,
    roles[index % roles.length],
  ]
  return {
    id: `sample-user-${index + 1}`,
    auth_user_id: `sample-auth-${index + 1}`,
    employee_id: person[1],
    full_name: person[0],
    email: person[2],
    role: person[3],
    is_active: index < 42,
    is_self: index === 0,
    last_login_at: null,
    is_deletion_pending: false,
    warehouse: sampleWarehouses[index % sampleWarehouses.length],
    accessScope: index === 0 || person[3] === 'Inventory Administrator' ? 'All warehouses' : sampleWarehouses[index % sampleWarehouses.length],
  }
})

const sampleRequests = [
  {
    id: 'sample-request-1',
    full_name: 'Farah Nabila',
    employee_id: 'EMP-048',
    email: 'farah.nabila@acme.my',
    department: 'Warehouse operations',
    requested_role: 'Warehouse Supervisor',
    status: 'pending',
    created_at: new Date(Date.now() - 12 * 60 * 1000).toISOString(),
    reason: 'Manage the Shah Alam warehouse team.',
  },
  {
    id: 'sample-request-2',
    full_name: 'Amir Hakim',
    employee_id: 'EMP-051',
    email: 'amir.hakim@acme.my',
    department: 'Inventory',
    requested_role: 'Storekeeper',
    status: 'pending',
    created_at: new Date(Date.now() - 38 * 60 * 1000).toISOString(),
    reason: 'Support daily stock operations.',
  },
  {
    id: 'sample-request-3',
    full_name: 'Mei Ling',
    employee_id: 'EMP-052',
    email: 'mei.ling2@acme.my',
    department: 'Distribution',
    requested_role: 'Storekeeper',
    status: 'pending',
    created_at: new Date(Date.now() - 60 * 60 * 1000).toISOString(),
    reason: 'Help maintain distribution stock.',
  },
]

function messageFrom(error, fallback) {
  const responseMessage = error?.context?.body?.error ?? error?.context?.body?.message
  if (typeof responseMessage === 'string' && responseMessage.trim()) return responseMessage
  if (typeof error?.message === 'string' && error.message.trim()) return error.message
  return error instanceof Error ? error.message : fallback
}

async function loadUsers() {
  const { data, error } = await supabase.functions.invoke('manage-users', { body: { action: 'list' } })
  if (error) throw new Error(messageFrom(error, 'Unable to load the user directory.'))
  if (data?.error) throw new Error(data.error)
  if (!Array.isArray(data?.users)) throw new Error('The user management service returned an invalid user list.')
  return data.users.map((user) => ({
    ...user,
    full_name: user.full_name ?? 'Unnamed user',
    email: user.email ?? '',
    employee_id: user.employee_id ?? '—',
    role: user.role ?? 'Storekeeper',
    is_active: user.is_active === true,
    warehouse: null,
    accessScope: user.role === 'Super Admin' || user.role === 'Inventory Administrator'
      ? 'All warehouses'
      : 'Role-based access',
  }))
}

export default function useUserManagementData() {
  const [users, setUsers] = useState(sampleUsers)
  const [requests, setRequests] = useState(sampleRequests)
  const [source, setSource] = useState('sample')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [rolesCatalog, setRolesCatalog] = useState(roles)
  const [departmentsCatalog, setDepartmentsCatalog] = useState(fallbackDepartments)

  const reload = useCallback(async () => {
    if (!supabase || !isSupabaseConfigured) {
      setUsers(sampleUsers)
      setRequests(sampleRequests)
      setRolesCatalog(roles)
      setDepartmentsCatalog(fallbackDepartments)
      setSource('sample')
      setError('')
      setLoading(false)
      return
    }

    setLoading(true)
    const [usersResult, requestsResult, rolesResult, departmentsResult] = await Promise.allSettled([
      loadUsers(),
      supabase.from('registration_requests')
        .select('id,full_name,employee_id,email,department,requested_role,status,created_at,reason')
        .eq('status', 'pending')
        .order('created_at', { ascending: true }),
      supabase.from('custom_roles').select('id,name,description,scope,is_active').eq('is_active', true).order('name'),
      supabase.from('departments').select('id,name,description,is_active').eq('is_active', true).order('name'),
    ])

    const issues = []
    if (usersResult.status === 'fulfilled') {
      setUsers(usersResult.value)
    } else {
      setUsers(sampleUsers)
      issues.push(`User directory: ${messageFrom(usersResult.reason, 'unavailable')}`)
    }

    if (requestsResult.status === 'fulfilled' && !requestsResult.value.error) {
      setRequests(requestsResult.value.data ?? [])
    } else {
      setRequests(sampleRequests)
      const requestError = requestsResult.status === 'rejected' ? requestsResult.reason : requestsResult.value.error
      issues.push(`Registration requests: ${messageFrom(requestError, 'unavailable')}`)
    }

    if (rolesResult.status === 'fulfilled' && !rolesResult.value.error && rolesResult.value.data?.length) {
      setRolesCatalog(rolesResult.value.data.map((role) => role.name))
    }
    if (departmentsResult.status === 'fulfilled' && !departmentsResult.value.error && departmentsResult.value.data?.length) {
      setDepartmentsCatalog(departmentsResult.value.data.map((department) => department.name))
    }

    const usersLive = usersResult.status === 'fulfilled'
    const requestsLive = requestsResult.status === 'fulfilled' && !requestsResult.value.error
    setSource(usersLive && requestsLive ? 'live' : usersLive || requestsLive ? 'partial' : 'sample')
    setError(issues.length ? `Live user data is partially unavailable. ${issues.join(' ')}` : '')
    setLoading(false)
  }, [])

  useEffect(() => {
    let active = true
    void Promise.resolve().then(() => active ? reload() : undefined).catch((loadError) => {
      if (!active) return
      setUsers(sampleUsers)
      setRequests(sampleRequests)
      setSource('sample')
      setError(`Unable to load user management data. ${messageFrom(loadError, 'Please try again.')}`)
      setLoading(false)
    })
    return () => { active = false }
  }, [reload])

  const invokeUserAction = useCallback(async (body) => {
    if (!supabase || !isSupabaseConfigured) {
      throw new Error('User management requires a configured Supabase connection.')
    }
    const { data, error: invokeError } = await supabase.functions.invoke('manage-users', { body })
    if (invokeError) throw new Error(messageFrom(invokeError, 'User management request failed.'))
    if (data?.error) throw new Error(data.error)
    return data
  }, [])

  return { users, requests, rolesCatalog, departmentsCatalog, source, loading, error, reload, invokeUserAction }
}
