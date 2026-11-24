import { useEffect, useMemo, useState } from 'react'
import {
  Bell,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  Clock3,
  Edit3,
  Eye,
  EyeOff,
  Menu,
  Search,
  ShieldCheck,
  UserPlus,
  UsersRound,
  UserRoundCheck,
  UserRoundX,
} from 'lucide-react'
import { useOutletContext } from 'react-router-dom'
import EditUserModal from '../components/users/EditUserModal'
import InviteUserModal from '../components/users/InviteUserModal'
import RolePermissionsModal from '../components/users/RolePermissionsModal'
import useUserManagementData from '../components/users/useUserManagementData'
import { isSupabaseConfigured, supabase } from '../lib/supabase'
import { isSuperAdminRole } from '../lib/workspaceAccess'
import { getSupabaseFunctionErrorMessage } from '../lib/supabaseFunctionErrors'

const pageSize = 6

function roleClass(role) {
  if (role === 'Super Admin') return 'bg-violet-50 text-violet-700'
  if (role === 'Inventory Administrator') return 'bg-blue-50 text-blue-700'
  if (role === 'Warehouse Supervisor') return 'bg-teal-50 text-teal-700'
  return 'bg-slate-100 text-slate-600'
}

function displayDate(value) {
  if (!value) return 'No sign-in recorded'
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'No sign-in recorded' : date.toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })
}

function getErrorMessage(error, fallback) {
  const nested = error?.context?.body?.error ?? error?.context?.body?.message
  if (typeof nested === 'string' && nested.trim()) return nested
  return error instanceof Error ? error.message : fallback
}

function emailRateLimitPasswordGuidance() {
  return ' After the email limit clears, have them use Forgot password on the sign-in page, or send a password-reset link from Supabase Auth > Users.'
}

function provisioningNotice(response, name, successMessage) {
  return response?.email_rate_limited
    ? `${name} is provisioned in the User directory, but invitation email delivery was rate-limited.${emailRateLimitPasswordGuidance()}`
    : successMessage
}

function Toggle({ checked, label, onChange, disabled = false }) {
  return (
    <button
      aria-checked={checked}
      aria-label={label}
      className={`relative inline-flex h-[18px] w-9 items-center rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 ${checked ? 'bg-teal-600' : 'bg-slate-300'}`}
      disabled={disabled}
      onClick={onChange}
      role="switch"
      type="button"
    >
      <span className={`h-3.5 w-3.5 rounded-full bg-white shadow transition-transform ${checked ? 'translate-x-[18px]' : 'translate-x-[2px]'}`} />
    </button>
  )
}

export default function UserManagementPage() {
  const context = useOutletContext() ?? {}
  const data = useUserManagementData()
  const warehouses = context.source === 'live' ? context.data?.warehouses ?? [] : []
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [warehouseFilter, setWarehouseFilter] = useState('all')
  const [page, setPage] = useState(1)
  const [modal, setModal] = useState(null)
  const [busyId, setBusyId] = useState('')
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const userRoles = data.rolesCatalog
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deletePassword, setDeletePassword] = useState('')
  const [deletePasswordVisible, setDeletePasswordVisible] = useState(false)
  const [deleteError, setDeleteError] = useState('')
  const isCurrentSuperAdmin = isSuperAdminRole(context.data?.profile?.role)
  const [selectedRequestIds, setSelectedRequestIds] = useState(new Set())
  const [bulkBusy, setBulkBusy] = useState(false)
  const [bulkDeleteConfirm, setBulkDeleteConfirm] = useState(false)

  const directoryRows = useMemo(() => [
    ...data.users.map((user) => ({ ...user, key: `user-${user.id}`, pending: false })),
    ...data.requests.map((request) => ({
      ...request,
      key: `request-${request.id}`,
      employee_id: request.employee_id,
      full_name: request.full_name,
      role: request.requested_role,
      email: request.email,
      pending: true,
      is_active: false,
      warehouse: null,
      accessScope: request.department || 'Pending assignment',
    })),
  ], [data.requests, data.users])

  const filteredRows = directoryRows.filter((user) => {
    const query = search.trim().toLowerCase()
    const matchesText = !query || `${user.full_name} ${user.employee_id} ${user.email} ${user.role}`.toLowerCase().includes(query)
    const matchesRole = roleFilter === 'all' || user.role === roleFilter
    const matchesStatus = statusFilter === 'all' || (statusFilter === 'pending' ? user.pending : !user.pending && (statusFilter === 'active' ? user.is_active : !user.is_active))
    const matchesWarehouse = warehouseFilter === 'all' ||
      (warehouseFilter.startsWith('warehouse:') && user.warehouse === warehouseFilter.slice('warehouse:'.length)) ||
      (warehouseFilter.startsWith('scope:') && user.accessScope === warehouseFilter.slice('scope:'.length))
    return matchesText && matchesRole && matchesStatus && matchesWarehouse
  })

  const pageCount = Math.max(1, Math.ceil(filteredRows.length / pageSize))
  const pageRows = filteredRows.slice((page - 1) * pageSize, page * pageSize)
  const pendingCount = data.requests.length
  const activeCount = data.users.filter((user) => user.is_active).length
  const adminCount = data.users.filter((user) => user.is_active && ['Super Admin', 'Inventory Administrator'].includes(user.role)).length
  const totalCount = data.users.length + pendingCount
  const locationOptions = [...new Set([
    ...warehouses.map((warehouse) => warehouse.name),
    ...data.users.map((user) => user.warehouse).filter(Boolean),
  ])].sort((left, right) => left.localeCompare(right))
  const accessScopes = [...new Set(data.users.map((user) => user.accessScope).filter(Boolean))]
    .filter((scope) => scope !== 'All warehouses' && !locationOptions.includes(scope))
    .sort((left, right) => left.localeCompare(right))

  useEffect(() => {
    if (!notice) return undefined
    const duration = notice.includes('invitation email delivery was rate-limited') ? 10000 : 3500
    const timer = window.setTimeout(() => setNotice(''), duration)
    return () => window.clearTimeout(timer)
  }, [notice])

  async function currentProfileId() {
    const currentProfileIdValue = context.data?.profile?.id
    if (currentProfileIdValue) return currentProfileIdValue
    if (!supabase || !context.session?.user?.id) throw new Error('Your workspace profile could not be verified.')
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('id')
      .eq('auth_user_id', context.session.user.id)
      .maybeSingle()
    if (profileError) throw profileError
    if (!profile?.id) throw new Error('Your workspace profile could not be verified.')
    return profile.id
  }

  async function provisionRequest(requestId) {
    const { data: response, error: invokeError } = await supabase.functions.invoke('provision-approved-registration', { body: { request_id: requestId } })
    if (invokeError) {
      throw new Error(await getSupabaseFunctionErrorMessage(invokeError, 'The invitation could not be sent.'))
    }
    if (response?.error) {
      throw new Error(await getSupabaseFunctionErrorMessage({ context: { body: response } }, 'The invitation could not be sent.'))
    }
    if (!response?.profile_id || !response?.auth_user_id || !['invited', 'completed'].includes(response?.status)) {
      throw new Error('verify-provisioned-profile: The provisioning service did not confirm both the Auth account and workspace profile.')
    }
    return response
  }

  async function submitInvitation(values) {
    if (!supabase || !isSupabaseConfigured) throw new Error('Connect Supabase before inviting users.')
    let provisioningSucceeded = false
    const requestEmail = values.email.trim().toLowerCase()
    const insertResult = await supabase.from('registration_requests').insert({
      full_name: values.fullName.trim(),
      employee_id: values.employeeId.trim(),
      email: values.email.trim(),
      department: values.department.trim(),
      requested_role: values.role,
      reason: values.reason.trim() || null,
      status: 'pending',
    }).select('id').single()
    if (insertResult.error) throw new Error(insertResult.error.message)

    try {
      const approverId = await currentProfileId()
      const updateResult = await supabase.from('registration_requests').update({
        status: 'approved',
        approved_at: new Date().toISOString(),
        approved_by: approverId,
      }).eq('id', insertResult.data.id).eq('status', 'pending').select('id').maybeSingle()
      if (updateResult.error) throw new Error(updateResult.error.message)
      if (!updateResult.data) throw new Error('The invitation request was created but could not be approved. Review it in Pending registration requests.')
      const provisionResult = await provisionRequest(insertResult.data.id)
      provisioningSucceeded = true
      const invitationMessage = provisionResult.email_invitation_sent
        ? `Invitation email sent to ${values.email.trim()}.`
        : `The account for ${requestEmail} is provisioned, but no invitation email was sent.`
      setNotice(provisioningNotice(provisionResult, requestEmail, invitationMessage))
    } catch (inviteError) {
      setError(`Invitation setup failed: ${getErrorMessage(inviteError, 'Provisioning failed.')}`)
      setNotice('Invitation provisioning needs attention. Review the error details.')
    } finally {
      const refreshedUsers = await data.reload()
      if (provisioningSucceeded && !refreshedUsers.some((user) => user.email.toLowerCase() === requestEmail)) {
        setError(`Provisioning completed, but ${requestEmail} was not returned in the refreshed User directory.`)
      }
    }
  }

  async function updateRequest(request, status) {
    if (!supabase || !isSupabaseConfigured) {
      setError('Registration approvals require a configured Supabase connection.')
      return
    }
    setBusyId(request.id)
    setError('')
    let provisioningSucceeded = false
    try {
      const approverId = await currentProfileId()
      const { data: updated, error: updateError } = await supabase.from('registration_requests').update({
        status,
        approved_at: new Date().toISOString(),
        approved_by: approverId,
      }).eq('id', request.id).eq('status', 'pending').select('id').maybeSingle()
      if (updateError) throw updateError
      if (!updated) throw new Error('This request is no longer pending. Refresh the list and try again.')
      if (status === 'approved') {
        try {
          const provisionResult = await provisionRequest(request.id)
          provisioningSucceeded = true
          const approvalMessage = provisionResult.account_activated_without_email
            ? `Approved and activated ${request.full_name}. They can sign in using the password from their access request.`
            : provisionResult.email_invitation_sent
              ? `Approved and invited ${request.full_name}.`
              : `Approved and provisioned ${request.full_name}.`
          setNotice(provisioningNotice(provisionResult, request.full_name, approvalMessage))
        } catch (provisionError) {
          setError(`Request approved, but user provisioning failed: ${getErrorMessage(provisionError, 'Provisioning failed.')}`)
          setNotice('The request is approved, but account setup needs attention. See the error details.')
        }
      } else {
        setNotice(`Rejected the request from ${request.full_name}.`)
      }
      const refreshedUsers = await data.reload()
      if (status === 'approved' && provisioningSucceeded && !refreshedUsers.some((user) => user.email.toLowerCase() === request.email.toLowerCase())) {
        setError(`Provisioning completed, but ${request.email} was not returned in the refreshed User directory. Refresh the directory or retry provisioning from the failed requests list.`)
      }
    } catch (actionError) {
      setError(getErrorMessage(actionError, 'Unable to update the registration request.'))
    } finally {
      setBusyId('')
    }
  }

  async function updateUser(user, patch) {
    setBusyId(user.id)
    setError('')
    try {
      await data.invokeUserAction({ ...patch, user_id: user.id })
      await data.reload()
      setNotice(patch.action === 'change_role' ? `Role updated for ${user.full_name}.` : `${user.full_name} ${patch.is_active ? 'activated' : 'deactivated'}.`)
      return true
    } catch (actionError) {
      const message = getErrorMessage(actionError, 'Unable to update this user.')
      setError(message)
      throw new Error(message)
    } finally {
      setBusyId('')
    }
  }

  async function permanentlyDeleteUser(user) {
    setBusyId(user.id)
    setDeleteError('')
    try {
      const currentUserEmail = context.session?.user?.email
      if (!supabase || !currentUserEmail) {
        throw new Error('A signed-in account email is required to verify your password.')
      }

      const { error: verificationError } = await supabase.auth.signInWithPassword({
        email: currentUserEmail,
        password: deletePassword,
      })
      if (verificationError) {
        setDeleteError('Incorrect password. Please enter your own account password.')
        return false
      }

      await data.invokeUserAction({ action: 'permanent_delete', user_id: user.id })
      await data.reload()
      setNotice(`${user.full_name} was permanently deleted.`)
      setDeleteTarget(null)
      setDeletePassword('')
      setDeletePasswordVisible(false)
      return true
    } catch (actionError) {
      setDeleteError(getErrorMessage(actionError, 'Unable to permanently delete this user.'))
      return false
    } finally {
      setBusyId('')
    }
  }

  function toggleSelectedRequest(requestId) {
    setSelectedRequestIds((current) => {
      const next = new Set(current)
      if (next.has(requestId)) next.delete(requestId)
      else next.add(requestId)
      return next
    })
  }

  async function retryProvisioning(request) {
    if (!supabase || !isSupabaseConfigured || busyId) return
    setBusyId(request.id)
    setError('')
    try {
      const provisionResult = await provisionRequest(request.id)
      const refreshedUsers = await data.reload()
      if (!refreshedUsers.some((user) => user.email.toLowerCase() === request.email.toLowerCase())) {
        throw new Error(`verify-provisioned-profile: ${request.email} is still missing from the refreshed User directory.`)
      }
      const retryMessage = provisionResult.account_activated_without_email
        ? `${request.full_name} is activated and can sign in using the password from their access request.`
        : `Provisioning completed and ${request.full_name} is now in the User directory.`
      setNotice(provisioningNotice(
        provisionResult,
        request.full_name,
        retryMessage,
      ))
    } catch (provisionError) {
      setError(`Provisioning retry failed: ${getErrorMessage(provisionError, 'Provisioning failed.')}`)
      await data.reload()
    } finally {
      setBusyId('')
    }
  }

  async function acceptSelectedRequests() {
    if (!isCurrentSuperAdmin || bulkBusy || selectedRequestIds.size === 0) return
    setBulkBusy(true)
    setError('')
    let approvedCount = 0
    let provisionedCount = 0
    let activatedCount = 0
    let invitationSentCount = 0
    const failures = []
    const provisionedEmails = []
    const emailRateLimitedEmails = []
    try {
      const approverId = await currentProfileId()
      for (const requestId of selectedRequestIds) {
        const request = data.requests.find((item) => item.id === requestId)
        if (!request) continue
        try {
          const { data: updated, error: updateError } = await supabase
            .from('registration_requests')
            .update({
              status: 'approved',
              approved_at: new Date().toISOString(),
              approved_by: approverId,
            })
            .eq('id', requestId)
            .eq('status', 'pending')
            .select('id')
            .maybeSingle()
          if (updateError) throw updateError
          if (!updated) throw new Error('The request is no longer pending.')
          approvedCount += 1
          const provisionResult = await provisionRequest(requestId)
          provisionedCount += 1
          if (provisionResult.account_activated_without_email) activatedCount += 1
          if (provisionResult.email_invitation_sent) invitationSentCount += 1
          provisionedEmails.push(request.email.toLowerCase())
          if (provisionResult.email_rate_limited) emailRateLimitedEmails.push(request.email)
        } catch (requestError) {
          failures.push(`${request.full_name}: ${getErrorMessage(requestError, 'Unable to approve or provision.')}`)
        }
      }
      const refreshedUsers = await data.reload()
      const missingUsers = provisionedEmails.filter((email) => !refreshedUsers.some((user) => user.email.toLowerCase() === email))
      if (missingUsers.length) failures.push(`Provisioning reported success, but these users are missing from the refreshed directory: ${missingUsers.join(', ')}.`)
      setSelectedRequestIds(new Set())
      if (failures.length) setError(failures.join(' '))
      const rateLimitNotice = emailRateLimitedEmails.length
        ? ` Users are provisioned in the User directory, but invitation email delivery was rate-limited for: ${emailRateLimitedEmails.join(', ')}.${emailRateLimitPasswordGuidance()}`
        : ''
      const activationNote = activatedCount > 0
        ? ` ${activatedCount} requester${activatedCount === 1 ? '' : 's'} can sign in using their access-request passwords.`
        : ''
      const invitationNote = invitationSentCount > 0
        ? ` Invitation emails were sent to ${invitationSentCount}.`
        : ''
      const provisionedSummary = activatedCount === provisionedCount && activatedCount > 0
        ? `Accepted and activated ${activatedCount} registration request${activatedCount === 1 ? '' : 's'}. They can sign in using the passwords supplied with their access requests.`
        : `Accepted and provisioned ${provisionedCount} registration request${provisionedCount === 1 ? '' : 's'}.${activationNote}${invitationNote}`
      setNotice(
        failures.length
          ? `Accepted ${approvedCount}; provisioned ${provisionedCount}. ${failures.join(' ')}${rateLimitNotice}`
          : emailRateLimitedEmails.length
            ? `Accepted and provisioned ${provisionedCount} registration request${provisionedCount === 1 ? '' : 's'}.${rateLimitNotice}`
            : provisionedSummary,
      )
    } catch (actionError) {
      setError(getErrorMessage(actionError, 'Unable to accept selected requests.'))
    } finally {
      setBulkBusy(false)
    }
  }

  async function deleteSelectedRequests() {
    if (!isCurrentSuperAdmin || bulkBusy || selectedRequestIds.size === 0) return
    setBulkBusy(true)
    setError('')
    try {
      const { data: result, error: rpcError } = await supabase.rpc(
        'delete_pending_registration_requests',
        { p_request_ids: [...selectedRequestIds] },
      )
      if (rpcError) throw rpcError
      const deletedCount = result?.deleted_count
      await data.reload()
      setSelectedRequestIds(new Set())
      setBulkDeleteConfirm(false)
      setNotice(`Deleted ${deletedCount ?? 0} pending registration request(s).`)
    } catch (actionError) {
      setError(getErrorMessage(actionError, 'Unable to delete selected requests.'))
    } finally {
      setBulkBusy(false)
    }
  }

  function runUserUpdate(user, patch) {
    void updateUser(user, patch).catch(() => {})
  }

  function setFilters(field, value) {
    setPage(1)
    if (field === 'search') setSearch(value)
    if (field === 'role') setRoleFilter(value)
    if (field === 'status') setStatusFilter(value)
    if (field === 'warehouse') setWarehouseFilter(value)
  }

  const from = filteredRows.length ? (page - 1) * pageSize + 1 : 0
  const to = Math.min(page * pageSize, filteredRows.length)

  return (
    <main className="min-h-screen bg-[#f8fafc] px-4 pb-8 pt-5 sm:px-6 lg:px-7">
      <div className="mx-auto max-w-[1500px]">
        <header className="mb-5">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="flex items-start gap-2.5">
              <button aria-label="Open navigation menu" className="mt-1 grid h-8 w-8 shrink-0 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 lg:hidden" onClick={context.openMobileSidebar} type="button"><Menu size={15} /></button>
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <h1 className="text-xl font-bold tracking-tight text-slate-900 sm:text-2xl">User Management</h1>
                  <span className={`rounded-full px-2 py-1 text-[8px] font-semibold ${data.source === 'live' ? 'bg-teal-50 text-teal-700' : data.source === 'partial' ? 'bg-amber-50 text-amber-700' : 'bg-slate-100 text-slate-500'}`}>{data.source === 'live' ? 'LIVE DIRECTORY' : data.source === 'partial' ? 'PARTIAL DATA' : 'UNAVAILABLE'}</span>
                </div>
                <p className="mt-1 text-[10px] text-slate-500 sm:text-xs">Manage your people, permissions, and warehouse access.</p>
              </div>
            </div>

            <div className="flex w-full flex-wrap items-center justify-between gap-2 sm:w-auto sm:justify-end">
              <label className="relative min-w-[185px] flex-1 sm:w-[220px] sm:flex-none">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={13} />
                <input aria-label="Search people and roles" className="h-8 w-full rounded-md border border-slate-200 bg-white pl-8 pr-3 text-[9px] outline-none placeholder:text-slate-400 focus:border-teal-500" onChange={(event) => setFilters('search', event.target.value)} placeholder="Search people, roles..." value={search} />
              </label>
              <div className="relative">
                <button aria-expanded={notificationsOpen} aria-label={`Notifications, ${pendingCount} pending approvals`} className="relative grid h-8 w-8 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 hover:bg-slate-50" onClick={() => setNotificationsOpen((open) => !open)} type="button">
                  <Bell size={14} />
                  {pendingCount > 0 && <span className="absolute -right-1 -top-1 grid h-3.5 min-w-3.5 place-items-center rounded-full bg-amber-500 px-0.5 text-[7px] font-bold text-white">{pendingCount}</span>}
                </button>
                {notificationsOpen && <div className="absolute right-0 top-10 z-30 w-64 rounded-lg border border-slate-200 bg-white p-3 shadow-xl">
                  <p className="text-[10px] font-bold text-slate-800">User notifications</p>
                  <p className="mt-1 text-[9px] leading-4 text-slate-500">{pendingCount ? `${pendingCount} registration request${pendingCount === 1 ? '' : 's'} awaiting review.` : 'No pending registration approvals.'}</p>
                  <button className="mt-2 text-[9px] font-semibold text-teal-700" onClick={() => { setNotificationsOpen(false); document.getElementById('pending-requests')?.scrollIntoView({ behavior: 'smooth' }) }} type="button">Review requests</button>
                </div>}
              </div>
              <button className="inline-flex h-8 items-center gap-1.5 rounded-md bg-teal-600 px-3 text-[9px] font-semibold text-white hover:bg-teal-700" onClick={() => setModal({ type: 'invite' })} type="button"><UserPlus size={12} /> Invite User</button>
            </div>
          </div>
        </header>

        {(error || data.error) && <div className="mb-4 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-[9px] leading-4 text-amber-800" role="status">{error || data.error}</div>}

        <section aria-label="User summary" className="mb-4 grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <SummaryCard icon={UsersRound} label="Total users" value={totalCount.toLocaleString()} detail={`${warehouses.length} warehouses`} tone="teal" />
          <SummaryCard icon={CheckCircle2} label="Active accounts" value={activeCount.toLocaleString()} detail={`${totalCount ? ((activeCount / totalCount) * 100).toFixed(1) : '0.0'}% of all accounts`} tone="teal" />
          <SummaryCard icon={Clock3} label="Pending approvals" value={pendingCount.toLocaleString()} detail={pendingCount ? 'Awaiting your review' : 'All requests reviewed'} tone="amber" />
          <SummaryCard icon={ShieldCheck} label="Roles & admins" value={`${userRoles.length} roles`} detail={`${adminCount} administrators`} tone="teal" />
        </section>

        <section aria-label="User directory" className="mb-4 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
          <header className="flex flex-wrap items-start justify-between gap-3 px-4 pb-3 pt-4 sm:px-5">
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-bold text-slate-900">User directory</h2>
                <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[9px] font-semibold text-slate-600">{totalCount.toLocaleString()} users</span>
              </div>
              <p className="mt-1 text-[9px] text-slate-500">{activeCount} active · {data.users.length - activeCount} inactive · {pendingCount} pending</p>
            </div>
            <div className="flex flex-wrap gap-2">
              <button className="inline-flex h-8 items-center gap-1 rounded-md border border-slate-200 px-2.5 text-[9px] font-semibold text-slate-700 hover:bg-slate-50" onClick={() => setModal({ type: 'permissions', initialTab: 'departments' })} type="button">+ New Department</button>
              <button className="inline-flex h-8 items-center gap-1 rounded-md border border-slate-200 px-2.5 text-[9px] font-semibold text-slate-700 hover:bg-slate-50" onClick={() => setModal({ type: 'permissions', initialTab: 'roles' })} type="button">+ New Role</button>
              <button className="inline-flex h-8 items-center gap-1 rounded-md bg-teal-50 px-2.5 text-[9px] font-semibold text-teal-700 hover:bg-teal-100" onClick={() => setModal({ type: 'permissions', initialTab: 'permissions' })} type="button">Manage role permissions <ChevronRight size={12} /></button>
            </div>
          </header>

          <div className="flex flex-wrap items-center gap-2 border-b border-slate-100 px-4 pb-3 sm:px-5">
            <label className="relative min-w-[200px] flex-1 sm:max-w-[330px]">
              <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={12} />
              <input aria-label="Search user directory by name, employee ID, or email" className="h-8 w-full rounded-md border border-slate-200 pl-8 pr-3 text-[9px] outline-none placeholder:text-slate-400 focus:border-teal-500" onChange={(event) => setFilters('search', event.target.value)} placeholder="Search name, employee ID, or email" value={search} />
            </label>
            <FilterSelect ariaLabel="Filter users by role" value={roleFilter} onChange={(value) => setFilters('role', value)}>
              <option value="all">All roles</option>
              {userRoles.map((role) => <option key={role} value={role}>{role}</option>)}
            </FilterSelect>
            <FilterSelect ariaLabel="Filter users by status" value={statusFilter} onChange={(value) => setFilters('status', value)}>
              <option value="all">All statuses</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="pending">Pending</option>
            </FilterSelect>
            <FilterSelect ariaLabel="Filter users by warehouse or access scope" value={warehouseFilter} onChange={(value) => setFilters('warehouse', value)}>
              <option value="all">All warehouses</option>
              {locationOptions.map((location) => <option key={`warehouse-${location}`} value={`warehouse:${location}`}>{location}</option>)}
              {accessScopes.map((scope) => <option key={`scope-${scope}`} value={`scope:${scope}`}>{scope}</option>)}
            </FilterSelect>
            <span className="ml-auto text-[8px] text-slate-400">{filteredRows.length} results</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full min-w-[900px] border-collapse text-left">
              <thead>
                <tr className="bg-slate-50 text-[8px] font-medium text-slate-500">
                  <th className="px-4 py-2 font-medium">Name</th>
                  <th className="px-3 py-2 font-medium">Employee ID &amp; email</th>
                  <th className="px-3 py-2 font-medium">Role</th>
                  <th className="px-3 py-2 font-medium">Warehouse / Access scope</th>
                  <th className="px-3 py-2 font-medium">Status</th>
                  <th className="px-3 py-2 font-medium">Actions</th>
                </tr>
              </thead>
              <tbody>
                {pageRows.length === 0 ? <tr><td className="px-4 py-10 text-center text-[10px] text-slate-400" colSpan={6}>No users match the selected filters.</td></tr> : pageRows.map((user) => (
                  <tr className={`border-t border-slate-100 text-[9px] ${user.pending ? 'bg-amber-50/35' : ''}`} key={user.key}>
                    <td className="px-4 py-2">
                      <span className="block font-semibold text-slate-800">{user.full_name}</span>
                      {user.pending && <span className="mt-0.5 block text-[8px] text-slate-400">Registration request</span>}
                    </td>
                    <td className="px-3 py-2">
                      <span className="block font-medium text-slate-700">{user.employee_id || '—'}</span>
                      <span className="mt-0.5 block text-[8px] text-slate-400">{user.email || 'Email unavailable'}</span>
                    </td>
                    <td className="px-3 py-2"><span className={`inline-flex rounded px-1.5 py-1 text-[8px] font-semibold ${roleClass(user.role)}`}>{user.role}</span></td>
                    <td className="px-3 py-2">
                      <span className="block font-medium text-slate-700">{user.warehouse || user.accessScope || 'Role-based access'}</span>
                      <span className="mt-0.5 block text-[8px] text-slate-400">{user.pending ? user.department || 'Pending assignment' : user.warehouse ? (user.role === 'Storekeeper' ? 'Read-only access' : 'Manage warehouse') : user.role === 'Super Admin' ? 'Full access' : 'Access follows role policy'}</span>
                    </td>
                    <td className="px-3 py-2">
                      {user.pending ? (
                        <span className="inline-flex rounded bg-amber-50 px-1.5 py-1 text-[8px] font-semibold text-amber-700">Pending</span>
                      ) : (
                        <span className="inline-flex items-center gap-1.5">
                          <Toggle checked={user.is_active} disabled={busyId === user.id || (user.is_self && user.is_active)} label={`${user.is_active ? 'Deactivate' : 'Activate'} ${user.full_name}`} onChange={() => runUserUpdate(user, { action: 'set_active', is_active: !user.is_active })} />
                          <span className={user.is_active ? 'text-slate-500' : 'text-slate-400'}>{user.is_active ? 'Active' : 'Inactive'}</span>
                        </span>
                      )}
                    </td>
                    <td className="px-3 py-2">
                      {user.pending ? (
                        <div className="flex items-center gap-2">
                          <button className="font-semibold text-teal-700 hover:text-teal-800 disabled:opacity-50" disabled={busyId === user.id} onClick={() => updateRequest(user, 'approved')} type="button">Approve</button>
                          <button className="text-slate-500 hover:text-rose-700 disabled:opacity-50" disabled={busyId === user.id} onClick={() => updateRequest(user, 'rejected')} type="button">Reject</button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-2">
                          <button aria-label={`Edit ${user.full_name}`} className="inline-flex items-center gap-1 text-slate-500 hover:text-teal-700 disabled:opacity-50" disabled={busyId === user.id || user.is_deletion_pending} onClick={() => setModal({ type: 'edit', user })} type="button"><Edit3 size={11} /> Edit</button>
                          <button className={`font-medium hover:underline disabled:opacity-50 ${user.is_active ? 'text-rose-600' : 'text-teal-700'}`} disabled={busyId === user.id || user.is_deletion_pending || (user.is_self && user.is_active)} onClick={() => runUserUpdate(user, { action: 'set_active', is_active: !user.is_active })} type="button">{user.is_active ? 'Deactivate' : 'Activate'}</button>
                          {isCurrentSuperAdmin && !user.is_active && !user.is_self && !user.is_deletion_pending && (
                            <button className="font-semibold text-rose-600 hover:text-rose-800 disabled:opacity-50" disabled={busyId === user.id} onClick={() => {
                              setDeletePassword('')
                              setDeletePasswordVisible(false)
                              setDeleteError('')
                              setDeleteTarget(user)
                            }} type="button">Delete permanently</button>
                          )}
                        </div>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <footer className="flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 px-4 py-2.5 text-[8px] text-slate-500 sm:px-5">
            <span>Showing {from}–{to} of {filteredRows.length} users</span>
            <div className="flex items-center gap-2">
              <button aria-label="Previous user page" className="rounded p-1 hover:bg-slate-100 disabled:opacity-30" disabled={page <= 1} onClick={() => setPage((value) => Math.max(1, value - 1))} type="button"><ChevronLeft size={13} /></button>
              {Array.from({ length: pageCount }, (_, index) => index + 1).slice(Math.max(0, page - 2), Math.min(pageCount, page + 1)).map((pageNumber) => (
                <button aria-current={pageNumber === page ? 'page' : undefined} className={`rounded px-2 py-1 ${pageNumber === page ? 'bg-teal-50 font-semibold text-teal-700' : 'hover:bg-slate-100'}`} key={pageNumber} onClick={() => setPage(pageNumber)} type="button">{pageNumber}</button>
              ))}
              <button aria-label="Next user page" className="rounded p-1 hover:bg-slate-100 disabled:opacity-30" disabled={page >= pageCount} onClick={() => setPage((value) => Math.min(pageCount, value + 1))} type="button"><ChevronRight size={13} /></button>
            </div>
          </footer>
        </section>

        {data.provisioningFailures.length > 0 && (
          <section aria-label="Registration requests with provisioning failures" className="mb-4 overflow-hidden rounded-xl border border-rose-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5">
            <header className="mb-3">
              <h2 className="text-sm font-bold text-rose-800">Account provisioning needs attention</h2>
              <p className="mt-1 text-[9px] text-slate-500">These requests were approved, but account setup did not finish. Retry verifies or creates the Auth user and profile row.</p>
            </header>
            <div className="space-y-2">
              {data.provisioningFailures.map((request) => (
                <article className="flex flex-wrap items-start justify-between gap-3 rounded-lg border border-rose-100 bg-rose-50/60 p-3" key={request.id}>
                  <div className="min-w-0 flex-1">
                    <p className="text-[10px] font-semibold text-slate-800">{request.full_name} · {request.email}</p>
                    <p className="mt-1 break-words text-[9px] leading-4 text-rose-800">{request.provisioning_error || 'The provisioning function did not return an error detail.'}</p>
                  </div>
                  {isCurrentSuperAdmin && (
                    <button className="h-8 shrink-0 rounded-md bg-rose-700 px-3 text-[9px] font-semibold text-white hover:bg-rose-800 disabled:opacity-50" disabled={Boolean(busyId)} onClick={() => void retryProvisioning(request)} type="button">
                      {busyId === request.id ? 'Retrying…' : 'Retry provisioning'}
                    </button>
                  )}
                </article>
              ))}
            </div>
          </section>
        )}

        <section aria-label="Pending registration requests" className="overflow-hidden rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5" id="pending-requests">
          <header className="flex flex-wrap items-start justify-between gap-2">
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-sm font-bold text-slate-900">Pending registration requests</h2>
                {pendingCount > 0 && <span className="rounded bg-amber-50 px-1.5 py-0.5 text-[8px] font-semibold text-amber-700">{pendingCount} pending</span>}
              </div>
              <p className="mt-1 text-[9px] text-slate-500">Review access before new team members join your workspace.</p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {isCurrentSuperAdmin && data.requests.length > 0 && (
                <label className="inline-flex items-center gap-1.5 text-[9px] font-semibold text-slate-600">
                  <input
                    checked={selectedRequestIds.size === data.requests.length}
                    onChange={(event) => setSelectedRequestIds(event.target.checked
                      ? new Set(data.requests.map((request) => request.id))
                      : new Set())}
                    type="checkbox"
                  />
                  Select all
                </label>
              )}
              {selectedRequestIds.size > 0 && (
                <>
                  <button className="h-7 rounded-md bg-teal-600 px-3 text-[9px] font-semibold text-white disabled:opacity-50" disabled={bulkBusy} onClick={() => void acceptSelectedRequests()} type="button">{bulkBusy ? 'Working…' : 'Accept Selected'}</button>
                  {isCurrentSuperAdmin && <button className="h-7 rounded-md border border-rose-200 px-3 text-[9px] font-semibold text-rose-700 disabled:opacity-50" disabled={bulkBusy} onClick={() => setBulkDeleteConfirm(true)} type="button">Delete Selected</button>}
                </>
              )}
              <button className="text-[9px] font-semibold text-teal-700 hover:text-teal-800" onClick={() => data.reload()} type="button">{data.loading ? 'Refreshing…' : 'Refresh requests'}</button>
            </div>
          </header>

          {data.requests.length ? <div className="mt-3 grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
            {data.requests.map((request) => (
              <article className="rounded-lg border border-slate-200 p-3" key={request.id}>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex min-w-0 items-start gap-2">
                    {isCurrentSuperAdmin && (
                      <input
                        aria-label={`Select ${request.full_name}`}
                        checked={selectedRequestIds.has(request.id)}
                        onChange={() => toggleSelectedRequest(request.id)}
                        type="checkbox"
                      />
                    )}
                    <div className="min-w-0">
                      <h3 className="truncate text-[10px] font-semibold text-slate-800">{request.full_name}</h3>
                      <p className="mt-1 truncate text-[9px] text-slate-500">{request.email}</p>
                    </div>
                  </div>
                  <span className="shrink-0 text-[8px] text-slate-400">{displayDate(request.created_at)}</span>
                </div>
                <p className="mt-2 text-[9px] text-slate-600">{request.requested_role} · {request.department || 'Department not specified'}</p>
                {request.reason && <p className="mt-1 line-clamp-2 text-[8px] leading-4 text-slate-400">{request.reason}</p>}
                <div className="mt-3 flex gap-2">
                  <button className="inline-flex h-7 items-center gap-1 rounded bg-teal-600 px-3 text-[9px] font-semibold text-white hover:bg-teal-700 disabled:opacity-50" disabled={busyId === request.id} onClick={() => updateRequest(request, 'approved')} type="button"><Check size={11} /> Approve</button>
                  <button className="h-7 rounded border border-slate-200 px-3 text-[9px] font-medium text-slate-600 hover:bg-slate-50 disabled:opacity-50" disabled={busyId === request.id} onClick={() => updateRequest(request, 'rejected')} type="button">Reject</button>
                </div>
              </article>
            ))}
          </div> : <p className="mt-4 rounded-lg border border-dashed border-slate-200 py-7 text-center text-[10px] text-slate-400">There are no pending registration requests.</p>}
        </section>

        <footer className="mt-4 flex flex-wrap items-center justify-between gap-2 text-[8px] text-slate-400">
          <span className="inline-flex items-center gap-1.5"><UserRoundCheck size={11} /> Changes are audited through the secure user-management service</span>
          <span className="inline-flex items-center gap-1.5"><UserRoundX size={11} /> Self-deactivation is disabled</span>
        </footer>
      </div>

      {modal?.type === 'invite' && <InviteUserModal departments={data.departmentsCatalog} onClose={() => setModal(null)} onInvite={submitInvitation} roles={userRoles.filter((role) => !isSuperAdminRole(role))} />}
      {modal?.type === 'edit' && <EditUserModal onClose={() => setModal(null)} onSave={(role) => (
        updateUser(modal.user, { action: 'change_role', role })
      )} roles={userRoles} user={modal.user} />}
      {modal?.type === 'permissions' && <RolePermissionsModal initialTab={modal.initialTab || 'permissions'} onClose={() => setModal(null)} />}
      {deleteTarget && (
        <div className="fixed inset-0 z-[120] grid place-items-center bg-slate-950/45 p-4">
          <section aria-modal="true" aria-labelledby="permanent-delete-title" className="w-full max-w-md rounded-xl border border-rose-200 bg-white p-5 shadow-2xl" role="dialog">
            <h2 className="text-sm font-bold text-slate-900" id="permanent-delete-title">Permanently delete {deleteTarget.full_name}?</h2>
            <p className="mt-2 text-[10px] leading-5 text-slate-600">
              This permanently removes the workspace profile and linked Supabase Auth account. This cannot be undone.
              The account must remain deactivated.
            </p>
            <label className="mt-4 block text-[10px] font-semibold text-slate-700">
              Enter your account password to confirm
              <span className="relative mt-1.5 block">
                <input
                  autoComplete="current-password"
                  className="modal-input pr-10"
                  onChange={(event) => {
                    setDeletePassword(event.target.value)
                    setDeleteError('')
                  }}
                  placeholder="Enter your password"
                  type={deletePasswordVisible ? 'text' : 'password'}
                  value={deletePassword}
                />
                <button
                  aria-label={deletePasswordVisible ? 'Hide password' : 'Show password'}
                  className="absolute right-2 top-1/2 -translate-y-1/2 rounded p-1 text-slate-400 hover:text-slate-700"
                  onClick={() => setDeletePasswordVisible((visible) => !visible)}
                  type="button"
                >
                  {deletePasswordVisible ? <EyeOff size={14} /> : <Eye size={14} />}
                </button>
              </span>
            </label>
            {deleteError && <p className="mt-3 rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{deleteError}</p>}
            <div className="mt-5 flex justify-end gap-2">
              <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600" disabled={busyId === deleteTarget.id} onClick={() => {
                setDeleteTarget(null)
                setDeletePassword('')
                setDeletePasswordVisible(false)
                setDeleteError('')
              }} type="button">Cancel</button>
              <button className="h-9 rounded-md bg-rose-600 px-4 text-[10px] font-semibold text-white disabled:opacity-50" disabled={busyId === deleteTarget.id || !deletePassword.trim()} onClick={() => void permanentlyDeleteUser(deleteTarget)} type="button">
                {busyId === deleteTarget.id ? 'Deleting…' : 'Permanently Delete'}
              </button>
            </div>
          </section>
        </div>
      )}
      {bulkDeleteConfirm && (
        <div className="fixed inset-0 z-[120] grid place-items-center bg-slate-950/45 p-4">
          <section aria-modal="true" aria-labelledby="bulk-delete-title" className="w-full max-w-md rounded-xl border border-rose-200 bg-white p-5 shadow-2xl" role="dialog">
            <h2 className="text-sm font-bold text-slate-900" id="bulk-delete-title">Delete {selectedRequestIds.size} selected registration request(s)?</h2>
            <p className="mt-2 text-[10px] leading-5 text-slate-600">This permanently removes the selected pending requests. It cannot be undone.</p>
            <div className="mt-5 flex justify-end gap-2">
              <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600" disabled={bulkBusy} onClick={() => setBulkDeleteConfirm(false)} type="button">Cancel</button>
              <button className="h-9 rounded-md bg-rose-600 px-4 text-[10px] font-semibold text-white disabled:opacity-50" disabled={bulkBusy} onClick={() => void deleteSelectedRequests()} type="button">{bulkBusy ? 'Deleting…' : 'Delete Selected'}</button>
            </div>
          </section>
        </div>
      )}
      {notice && <div className="fixed bottom-5 right-5 z-[100] max-w-[min(420px,calc(100vw-2rem))] rounded-lg bg-slate-900 px-4 py-3 text-[10px] leading-4 text-white shadow-xl" role="status">{notice}</div>}
    </main>
  )
}

function SummaryCard({ detail, icon: Icon, label, tone, value }) {
  return (
    <article className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
      <div className="flex items-start justify-between gap-2">
        <div><p className="text-[9px] font-semibold text-slate-500">{label}</p><p className="mt-2 text-[22px] font-bold leading-none text-slate-900">{value}</p></div>
        <span className={`grid h-8 w-8 place-items-center rounded-md ${tone === 'amber' ? 'bg-amber-50 text-amber-700' : 'bg-teal-50 text-teal-700'}`}><Icon size={15} /></span>
      </div>
      <p className={`mt-3 text-[8px] ${tone === 'amber' && label === 'Pending approvals' ? 'text-amber-700' : 'text-slate-500'}`}>{detail}</p>
    </article>
  )
}

function FilterSelect({ ariaLabel, children, onChange, value }) {
  return (
    <label className="relative">
      <select aria-label={ariaLabel} className="h-8 min-w-[105px] appearance-none rounded-md border border-slate-200 bg-white pl-2.5 pr-7 text-[9px] text-slate-700 outline-none focus:border-teal-500" onChange={(event) => onChange(event.target.value)} value={value}>
        {children}
      </select>
      <ChevronDown className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" size={12} />
    </label>
  )
}
