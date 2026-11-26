import { useState } from 'react'
import { UserPlus, X } from 'lucide-react'
import SearchableSelect from '../common/SearchableSelect'

export default function InviteUserModal({ departments = [], onClose, onInvite, roles = [] }) {
  const [values, setValues] = useState({
    fullName: '',
    employeeId: '',
    email: '',
    department: '',
    role: '',
    reason: '',
  })
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const selectedRole = values.role || (roles.includes('Viewer') ? 'Viewer' : roles[0] || '')
  function update(event) {
    setValues((current) => ({ ...current, [event.target.name]: event.target.value }))
  }

  async function submit(event) {
    event.preventDefault()
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(values.email.trim())) {
      setError('Enter a valid work email address.')
      return
    }
    const role = selectedRole
    if (!values.fullName.trim() || !values.employeeId.trim() || !values.department.trim() || !role) {
      setError('Complete the required fields and ensure an active department and role are available.')
      return
    }

    setPending(true)
    setError('')
    try {
      await onInvite({ ...values, role })
      onClose()
    } catch (inviteError) {
      setError(inviteError instanceof Error ? inviteError.message : 'Unable to send this invitation.')
    } finally {
      setPending(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[80] grid place-items-center overflow-y-auto bg-slate-950/45 p-4" onMouseDown={(event) => { if (event.target === event.currentTarget && !pending) onClose() }}>
      <section aria-labelledby="invite-user-title" aria-modal="true" className="my-auto w-full max-w-[520px] rounded-xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-50 text-teal-700"><UserPlus size={16} /></span>
            <div>
              <h2 className="text-sm font-bold text-slate-900" id="invite-user-title">Invite a workspace user</h2>
              <p className="mt-1 text-[10px] text-slate-500">Create the approved request and send a secure account invitation.</p>
            </div>
          </div>
          <button aria-label="Close invite user form" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100" disabled={pending} onClick={onClose} type="button"><X size={15} /></button>
        </header>

        <form className="space-y-3.5 p-5" onSubmit={submit}>
          <div className="grid gap-3.5 sm:grid-cols-2">
            <label className="block text-[10px] font-semibold text-slate-700 sm:col-span-2">
              Full name
              <input autoFocus className="modal-input mt-1.5" maxLength={160} name="fullName" onChange={update} placeholder="Full name" required value={values.fullName} />
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Employee ID
              <input className="modal-input mt-1.5" maxLength={64} name="employeeId" onChange={update} placeholder="Employee ID" required value={values.employeeId} />
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Work email
              <input className="modal-input mt-1.5" maxLength={254} name="email" onChange={update} placeholder="name@company.com" required type="email" value={values.email} />
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Department
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Department"
                  className="modal-input"
                  onChange={(department) => setValues((current) => ({ ...current, department }))}
                  options={departments.map((department) => ({ value: department, label: department }))}
                  placeholder="Select a department"
                  value={values.department}
                />
              </span>
              {departments.length === 0 && <span className="mt-1 block text-[8px] font-normal text-amber-700">No active departments are available. Add one before inviting a user.</span>}
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Requested role
              <span className="mt-1.5 block">
                <SearchableSelect
                  aria-label="Requested role"
                  className="modal-input"
                  onChange={(role) => setValues((current) => ({ ...current, role }))}
                  options={roles.map((role) => ({ value: role, label: role }))}
                  placeholder="Select a role"
                  value={selectedRole}
                />
              </span>
              {roles.length === 0 && <span className="mt-1 block text-[8px] font-normal text-amber-700">No active roles are available. Add one before inviting a user.</span>}
            </label>
            <label className="block text-[10px] font-semibold text-slate-700 sm:col-span-2">
              Invitation note <span className="font-normal text-slate-400">(optional)</span>
              <textarea className="modal-input mt-1.5 min-h-16 resize-y" maxLength={1000} name="reason" onChange={update} placeholder="Add a short note about the account request..." value={values.reason} />
            </label>
          </div>

          <p className="text-[9px] leading-4 text-slate-500">
            The initial password is the user’s Employee ID as entered, with
            surrounding spaces removed. Ask them to change it after signing in
            under Settings → Change password; the invitation link also lets
            them choose a new password before their first sign-in.
          </p>
          {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
            <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" disabled={pending} onClick={onClose} type="button">Cancel</button>
            <button className="inline-flex h-9 items-center gap-1.5 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={pending || !departments.length || !roles.length} type="submit">{pending ? 'Sending…' : 'Send invitation'}</button>
          </div>
        </form>
      </section>
    </div>
  )
}
