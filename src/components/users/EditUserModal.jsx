import { useState } from 'react'
import { UserRoundCog, X } from 'lucide-react'

export default function EditUserModal({ onClose, onSave, user, roles = ['Super Admin', 'Inventory Administrator', 'Warehouse Supervisor', 'Storekeeper'] }) {
  const [role, setRole] = useState(user.role)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')

  async function submit(event) {
    event.preventDefault()
    setPending(true)
    setError('')
    try {
      await onSave(role)
      onClose()
    } catch (saveError) {
      setError(saveError instanceof Error ? saveError.message : 'Unable to update this user.')
    } finally {
      setPending(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[80] grid place-items-center bg-slate-950/45 p-4" onMouseDown={(event) => { if (event.target === event.currentTarget && !pending) onClose() }}>
      <section aria-labelledby="edit-user-title" aria-modal="true" className="w-full max-w-[420px] rounded-xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-50 text-teal-700"><UserRoundCog size={16} /></span>
            <div>
              <h2 className="text-sm font-bold text-slate-900" id="edit-user-title">Edit user access</h2>
              <p className="mt-1 text-[10px] text-slate-500">{user.full_name} · {user.employee_id || 'No employee ID'}</p>
            </div>
          </div>
          <button aria-label="Close edit user form" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100" disabled={pending} onClick={onClose} type="button"><X size={15} /></button>
        </header>
        <form className="space-y-4 p-5" onSubmit={submit}>
          <label className="block text-[10px] font-semibold text-slate-700">
            Workspace role
            <select className="modal-input mt-1.5" onChange={(event) => setRole(event.target.value)} value={role}>
              {roles.map((value) => <option key={value} value={value}>{value}</option>)}
            </select>
          </label>
          <p className="text-[9px] leading-4 text-slate-500">Role changes are applied through the protected Supabase user-management function. Names, employee IDs, and email addresses are managed by the account provisioning flow.</p>
          {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
            <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" onClick={onClose} type="button">Cancel</button>
            <button className="h-9 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={pending || role === user.role} type="submit">{pending ? 'Saving…' : 'Save role'}</button>
          </div>
        </form>
      </section>
    </div>
  )
}
