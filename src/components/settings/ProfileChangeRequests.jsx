import { useCallback, useEffect, useState } from 'react'
import { Check, Clock3, X } from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'
import { supabase } from '../../lib/supabase'
import { canReviewProfileChangeRequests } from '../../lib/workspaceAccess'

function formatDate(value) {
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? 'Unknown date' : date.toLocaleString()
}

export default function ProfileChangeRequests({ profile, role }) {
  const [roles, setRoles] = useState([])
  const [departments, setDepartments] = useState([])
  const [requests, setRequests] = useState([])
  const [requestedRole, setRequestedRole] = useState('')
  const [requestedDepartment, setRequestedDepartment] = useState('')
  const [reason, setReason] = useState('')
  const [reviewNote, setReviewNote] = useState('')
  const [loading, setLoading] = useState(Boolean(supabase))
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState(supabase ? '' : 'Role and department requests require a configured Supabase connection.')
  const [message, setMessage] = useState('')
  const canReview = canReviewProfileChangeRequests(role)

  const reload = useCallback(async () => {
    if (!supabase) return
    const [requestResult, roleResult, departmentResult] = await Promise.all([
      supabase.from('profile_change_requests')
        .select('id,profile_id,profile_name,previous_role,requested_role,current_department,requested_department,reason,status,created_at,review_note')
        .order('created_at', { ascending: false })
        .limit(100),
      supabase.from('custom_roles').select('name').eq('is_active', true),
      supabase.from('departments').select('name').eq('is_active', true),
    ])
    const issue = requestResult.error || roleResult.error || departmentResult.error
    if (issue) {
      setError(issue.message)
      setLoading(false)
      return
    }
    setRequests(requestResult.data ?? [])
    setRoles((roleResult.data ?? []).map((item) => item.name))
    setDepartments((departmentResult.data ?? []).map((item) => item.name))
    setError('')
    setLoading(false)
  }, [])

  useEffect(() => {
    void reload()
  }, [reload])

  async function submit(event) {
    event.preventDefault()
    setError('')
    setMessage('')
    setBusy(true)
    try {
      const { error: submitError } = await supabase.rpc('submit_profile_change_request', {
        p_requested_role: requestedRole || null,
        p_requested_department: requestedDepartment || null,
        p_reason: reason.trim(),
      })
      if (submitError) throw submitError
      setRequestedRole('')
      setRequestedDepartment('')
      setReason('')
      setMessage('Your role and department change request was submitted.')
      await reload()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to submit your profile change request.')
    } finally {
      setBusy(false)
    }
  }

  async function review(requestId, decision) {
    setError('')
    setMessage('')
    setBusy(true)
    try {
      const { error: reviewError } = await supabase.rpc('review_profile_change_request', {
        p_request_id: requestId,
        p_decision: decision,
        p_review_note: reviewNote.trim() || null,
      })
      if (reviewError) throw reviewError
      setReviewNote('')
      setMessage(`The request was ${decision}.`)
      await reload()
    } catch (reviewError) {
      setError(reviewError instanceof Error ? reviewError.message : 'Unable to review this request.')
    } finally {
      setBusy(false)
    }
  }

  const ownRequests = requests.filter((request) => request.profile_id === profile?.id)
  const pendingRequests = canReview
    ? requests.filter((request) => request.status === 'pending')
    : []
  const roleOptions = [...new Set([profile?.role, ...roles].filter(Boolean))]

  return (
    <section className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5">
      <div>
        <h2 className="text-sm font-bold text-slate-900">Role &amp; Department Change Requests</h2>
        <p className="mt-1 text-[9px] leading-4 text-slate-500">Request a profile change and track its approval status. Manager and above approval is required.</p>
      </div>

      <form className="mt-4 grid gap-3 sm:grid-cols-2" onSubmit={submit}>
        <label className="block text-[9px] font-semibold text-slate-700">
          Requested role
          <span className="mt-1.5 block">
            <SearchableSelect
              aria-label="Requested role"
              className="h-9 w-full text-[10px] text-slate-700"
              onChange={setRequestedRole}
              options={[
                { value: '', label: 'No role change' },
                ...roleOptions.filter((option) => option !== 'Super Admin').map((option) => ({ value: option, label: option })),
              ]}
              value={requestedRole}
            />
          </span>
        </label>
        <label className="block text-[9px] font-semibold text-slate-700">
          Requested department
          <span className="mt-1.5 block">
            <SearchableSelect
              aria-label="Requested department"
              className="h-9 w-full text-[10px] text-slate-700"
              onChange={setRequestedDepartment}
              options={[
                { value: '', label: 'No department change' },
                ...departments.map((option) => ({ value: option, label: option })),
              ]}
              value={requestedDepartment}
            />
          </span>
        </label>
        <label className="block text-[9px] font-semibold text-slate-700 sm:col-span-2">
          Reason / notes
          <textarea className="modal-input mt-1.5 min-h-16 resize-y text-[10px]" maxLength={1000} onChange={(event) => setReason(event.target.value)} required value={reason} />
        </label>
        {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[9px] text-rose-700 sm:col-span-2" role="alert">{error}</p>}
        {message && <p className="rounded-md border border-teal-200 bg-teal-50 px-3 py-2 text-[9px] text-teal-700 sm:col-span-2" role="status">{message}</p>}
        <div className="flex items-center justify-between gap-3 sm:col-span-2">
          <p className="text-[8px] text-slate-400">Current role: {profile?.role || 'Unknown'} · Department: {profile?.department || 'Not set'}</p>
          <button className="h-8 shrink-0 rounded-md bg-teal-600 px-3 text-[9px] font-semibold text-white disabled:opacity-60" disabled={busy || loading || (!requestedRole && !requestedDepartment)} type="submit">
            {busy ? 'Submitting…' : 'Submit request'}
          </button>
        </div>
      </form>

      <div className="mt-5 border-t border-slate-100 pt-4">
        <h3 className="text-[10px] font-bold text-slate-800">Your requests</h3>
        {loading ? <p className="mt-2 text-[9px] text-slate-400">Loading requests…</p> : ownRequests.length ? (
          <div className="mt-2 space-y-2">
            {ownRequests.map((request) => (
              <article className="rounded-md border border-slate-100 bg-slate-50 p-3" key={request.id}>
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <p className="text-[9px] font-semibold text-slate-700">{request.previous_role} → {request.requested_role}{request.current_department !== request.requested_department ? ` · ${request.current_department || 'No department'} → ${request.requested_department || 'No department'}` : ''}</p>
                  <span className="inline-flex items-center gap-1 text-[8px] capitalize text-slate-500"><Clock3 size={11} /> {request.status}</span>
                </div>
                <p className="mt-1 text-[8px] text-slate-500">{request.reason} · {formatDate(request.created_at)}</p>
                {request.review_note && <p className="mt-1 text-[8px] text-slate-500">Review note: {request.review_note}</p>}
              </article>
            ))}
          </div>
        ) : <p className="mt-2 text-[9px] text-slate-400">No role or department requests submitted.</p>}
      </div>

      {canReview && (
        <div className="mt-5 border-t border-slate-100 pt-4">
          <h3 className="text-[10px] font-bold text-slate-800">Pending approval</h3>
          {loading ? <p className="mt-2 text-[9px] text-slate-400">Loading requests…</p> : pendingRequests.length ? (
            <div className="mt-2 space-y-2">
              <label className="block text-[8px] font-medium text-slate-500">
                Review note (optional)
                <input className="modal-input mt-1 h-8 text-[9px]" maxLength={1000} onChange={(event) => setReviewNote(event.target.value)} value={reviewNote} />
              </label>
              {pendingRequests.map((request) => (
                <article className="rounded-md border border-slate-200 p-3" key={request.id}>
                  <div className="flex flex-wrap items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-[9px] font-semibold text-slate-800">{request.profile_name} · {request.previous_role} → {request.requested_role}</p>
                      <p className="mt-1 text-[8px] text-slate-500">{request.current_department || 'No department'} → {request.requested_department || 'No department'} · {formatDate(request.created_at)}</p>
                      <p className="mt-2 text-[9px] leading-4 text-slate-600">{request.reason}</p>
                    </div>
                    <div className="flex shrink-0 gap-2">
                      <button aria-label={`Approve request from ${request.profile_name}`} className="inline-flex h-7 items-center gap-1 rounded-md bg-teal-600 px-2 text-[8px] font-semibold text-white disabled:opacity-50" disabled={busy || request.profile_id === profile?.id} onClick={() => void review(request.id, 'approved')} type="button"><Check size={11} /> Approve</button>
                      <button aria-label={`Reject request from ${request.profile_name}`} className="inline-flex h-7 items-center gap-1 rounded-md border border-rose-200 px-2 text-[8px] font-semibold text-rose-700 disabled:opacity-50" disabled={busy || request.profile_id === profile?.id} onClick={() => void review(request.id, 'rejected')} type="button"><X size={11} /> Reject</button>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          ) : <p className="mt-2 text-[9px] text-slate-400">No pending profile-change requests.</p>}
        </div>
      )}
    </section>
  )
}
