import { useEffect, useState } from 'react'
import { UserPlus, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'

export default function InviteUserModal({ onClose, onInvite }) {
  const [values, setValues] = useState({
    fullName: '',
    employeeId: '',
    email: '',
    department: '',
    role: 'Storekeeper',
    reason: '',
  })
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [departments, setDepartments] = useState([
    'Warehouse Operations',
    'Inventory Control',
    'Telemetry & Maintenance',
    'Logistics & Distribution',
    'Quality & Compliance',
    'Administration',
  ])
  const [roles, setRoles] = useState(['Storekeeper', 'Warehouse Supervisor'])

  useEffect(() => {
    if (!supabase) return
    Promise.all([
      supabase.from('departments').select('name').eq('is_active', true).order('name'),
      supabase.from('custom_roles').select('name').eq('is_active', true).neq('name', 'Super Admin').order('name'),
    ]).then(([departmentResult, roleResult]) => {
      if (!departmentResult.error && departmentResult.data?.length) setDepartments(departmentResult.data.map((item) => item.name))
      if (!roleResult.error && roleResult.data?.length) {
        setRoles(roleResult.data.map((item) => item.name))
        setValues((current) => ({ ...current, role: current.role === 'Storekeeper' && roleResult.data.some((item) => item.name === 'Storekeeper') ? 'Storekeeper' : roleResult.data[0].name }))
      }
    })
  }, [])

  function update(event) {
    setValues((current) => ({ ...current, [event.target.name]: event.target.value }))
  }

  async function submit(event) {
    event.preventDefault()
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(values.email.trim())) {
      setError('Enter a valid work email address.')
      return
    }
    if (!values.fullName.trim() || !values.employeeId.trim() || !values.department.trim()) {
      setError('Complete the name, employee ID, and department fields.')
      return
    }

    setPending(true)
    setError('')
    try {
      await onInvite(values)
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
              <input autoFocus className="modal-input mt-1.5" maxLength={160} name="fullName" onChange={update} placeholder="e.g. Farah Nabila" required value={values.fullName} />
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Employee ID
              <input className="modal-input mt-1.5" maxLength={64} name="employeeId" onChange={update} placeholder="EMP-048" required value={values.employeeId} />
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Work email
              <input className="modal-input mt-1.5" maxLength={254} name="email" onChange={update} placeholder="name@company.com" required type="email" value={values.email} />
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Department
              <select className="modal-input mt-1.5" name="department" onChange={update} required value={values.department}>
                <option disabled value="">Select a department</option>
                {departments.map((department) => <option key={department} value={department}>{department}</option>)}
              </select>
            </label>
            <label className="block text-[10px] font-semibold text-slate-700">
              Requested role
              <select className="modal-input mt-1.5" name="role" onChange={update} value={values.role}>
                {roles.map((role) => <option key={role} value={role}>{role}</option>)}
              </select>
            </label>
            <label className="block text-[10px] font-semibold text-slate-700 sm:col-span-2">
              Invitation note <span className="font-normal text-slate-400">(optional)</span>
              <textarea className="modal-input mt-1.5 min-h-16 resize-y" maxLength={1000} name="reason" onChange={update} placeholder="Add a short note about the account request..." value={values.reason} />
            </label>
          </div>

          <p className="text-[9px] leading-4 text-slate-500">The database supports Warehouse Supervisor and Storekeeper registration requests. New accounts are provisioned through the secured Supabase invitation function.</p>
          {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
            <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" disabled={pending} onClick={onClose} type="button">Cancel</button>
            <button className="inline-flex h-9 items-center gap-1.5 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={pending} type="submit">{pending ? 'Sending…' : 'Send invitation'}</button>
          </div>
        </form>
      </section>
    </div>
  )
}
