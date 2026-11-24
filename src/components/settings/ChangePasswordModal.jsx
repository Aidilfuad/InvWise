import { useState } from 'react'
import { Eye, EyeOff, KeyRound, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'

export default function ChangePasswordModal({ email, onClose, onSuccess }) {
  const [values, setValues] = useState({ current: '', next: '', confirm: '' })
  const [visible, setVisible] = useState(false)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')

  async function submit(event) {
    event.preventDefault()
    if (values.next.length < 8) {
      setError('Use a new password with at least 8 characters.')
      return
    }
    if (values.next !== values.confirm) {
      setError('The new passwords do not match.')
      return
    }
    if (!supabase || !email) {
      setError('A signed-in Supabase account email is required to change your password.')
      return
    }

    setPending(true)
    setError('')
    try {
      const { error: verifyError } = await supabase.auth.signInWithPassword({ email, password: values.current })
      if (verifyError) throw new Error(verifyError.message.toLowerCase().includes('invalid login credentials') ? 'Current password is incorrect.' : verifyError.message)
      const { error: updateError } = await supabase.auth.updateUser({ password: values.next })
      if (updateError) throw updateError
      onSuccess()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to change your password.')
    } finally {
      setPending(false)
    }
  }

  function update(event) {
    setValues((current) => ({ ...current, [event.target.name]: event.target.value }))
  }

  return (
    <div className="fixed inset-0 z-[90] grid place-items-center overflow-y-auto bg-slate-950/45 p-4" onMouseDown={(event) => { if (event.target === event.currentTarget && !pending) onClose() }}>
      <section aria-labelledby="change-password-title" aria-modal="true" className="my-auto w-full max-w-[430px] rounded-xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-50 text-teal-700"><KeyRound size={15} /></span>
            <div>
              <h2 className="text-sm font-bold text-slate-900" id="change-password-title">Change password</h2>
              <p className="mt-1 text-[10px] text-slate-500">Verify your current password before saving a new one.</p>
            </div>
          </div>
          <button aria-label="Close change password" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100" disabled={pending} onClick={onClose} type="button"><X size={15} /></button>
        </header>
        <form className="space-y-3.5 p-5" onSubmit={submit}>
          <label className="block text-[10px] font-semibold text-slate-700">Current password
            <input autoComplete="current-password" className="modal-input mt-1.5" name="current" onChange={update} required type={visible ? 'text' : 'password'} value={values.current} />
          </label>
          <label className="block text-[10px] font-semibold text-slate-700">New password
            <div className="relative mt-1.5">
              <input autoComplete="new-password" className="modal-input pr-10" minLength={8} name="next" onChange={update} required type={visible ? 'text' : 'password'} value={values.next} />
              <button aria-label={visible ? 'Hide passwords' : 'Show passwords'} className="absolute right-2 top-1/2 -translate-y-1/2 rounded p-1 text-slate-400 hover:text-slate-700" onClick={() => setVisible((value) => !value)} type="button">{visible ? <EyeOff size={14} /> : <Eye size={14} />}</button>
            </div>
          </label>
          <label className="block text-[10px] font-semibold text-slate-700">Confirm new password
            <input autoComplete="new-password" className="modal-input mt-1.5" name="confirm" onChange={update} required type={visible ? 'text' : 'password'} value={values.confirm} />
          </label>
          {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
          <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
            <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" disabled={pending} onClick={onClose} type="button">Cancel</button>
            <button className="h-9 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={pending} type="submit">{pending ? 'Updating…' : 'Update password'}</button>
          </div>
        </form>
      </section>
    </div>
  )
}
