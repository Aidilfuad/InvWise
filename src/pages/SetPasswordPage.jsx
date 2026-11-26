import { useState } from 'react'
import { Eye, EyeOff, Package } from 'lucide-react'
import { getSupabaseFunctionErrorMessage } from '../lib/supabaseFunctionErrors'
import { supabase } from '../lib/supabase'

export default function SetPasswordPage({ session, type, onComplete }) {
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [visible, setVisible] = useState(false)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const user = session?.user

  async function submit(event) {
    event.preventDefault()
    setError('')
    if (password.length < 8 || !/[A-Za-z]/.test(password) || !/\d/.test(password)) {
      setError('Use at least 8 characters, including a letter and a number.')
      return
    }
    if (password !== confirmation) {
      setError('The passwords do not match.')
      return
    }
    if (!supabase || !user) {
      setError('This password link is no longer active. Request a new link and try again.')
      return
    }

    setPending(true)
    try {
      const { error: updateError } = await supabase.auth.updateUser({ password })
      if (updateError) throw updateError

      const requestId = user.user_metadata?.registration_request_id
      if (typeof requestId === 'string' && requestId) {
        const email = user.email
        if (!email) throw new Error('The invitation does not contain an account email.')
        const { data: signInData, error: signInError } = await supabase.auth.signInWithPassword({
          email,
          password,
        })
        if (signInError) throw signInError
        if (signInData.user?.id !== user.id) {
          throw new Error('Unable to verify the invited account after setting its password.')
        }

        const { data, error: completionError } = await supabase.functions.invoke(
          'complete-registration-setup',
          { body: { request_id: requestId } },
        )
        if (completionError) {
          throw new Error(await getSupabaseFunctionErrorMessage(
            completionError,
            'Unable to complete invitation setup.',
          ))
        }
        if (data?.status !== 'completed') {
          throw new Error(data?.error ?? 'The account setup was not confirmed.')
        }
      }

      await onComplete()
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : 'Unable to set your password.')
      setPending(false)
    }
  }

  return (
    <main className="grid min-h-screen place-items-center bg-slate-50 p-4">
      <section aria-labelledby="set-password-title" className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-xl sm:p-8">
        <div className="flex items-center gap-3">
          <span className="grid h-10 w-10 place-items-center rounded-xl bg-teal-50 text-teal-700"><Package size={19} /></span>
          <div>
            <p className="text-[10px] font-semibold uppercase tracking-[0.16em] text-teal-700">InvWise account</p>
            <h1 className="mt-1 text-xl font-bold text-slate-900" id="set-password-title">
              {type === 'recovery' ? 'Reset your password' : 'Set your password'}
            </h1>
          </div>
        </div>
        <p className="mt-4 text-sm leading-6 text-slate-600">
          {type === 'invite'
            ? 'Your initial password is your Employee ID. Set a new password here before entering your workspace.'
            : 'Choose a new password for your InvWise account.'}
          {user?.email && <> Account: <strong>{user.email}</strong>.</>}
        </p>
        <form className="mt-5 space-y-4" onSubmit={submit}>
          <label className="block text-xs font-semibold text-slate-700">
            New password
            <span className="relative mt-1.5 block">
              <input autoComplete="new-password" className="modal-input pr-10" disabled={pending} minLength={8} onChange={(event) => setPassword(event.target.value)} required type={visible ? 'text' : 'password'} value={password} />
              <button aria-label={visible ? 'Hide password' : 'Show password'} className="absolute right-2 top-1/2 -translate-y-1/2 rounded p-1 text-slate-400" onClick={() => setVisible((current) => !current)} type="button">{visible ? <EyeOff size={15} /> : <Eye size={15} />}</button>
            </span>
          </label>
          <label className="block text-xs font-semibold text-slate-700">
            Confirm password
            <input autoComplete="new-password" className="modal-input mt-1.5" disabled={pending} onChange={(event) => setConfirmation(event.target.value)} required type={visible ? 'text' : 'password'} value={confirmation} />
          </label>
          {error && <p className="rounded-lg border border-rose-200 bg-rose-50 px-3 py-2.5 text-xs leading-5 text-rose-700" role="alert">{error}</p>}
          <button className="w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={pending} type="submit">
            {pending ? 'Saving password…' : 'Save password and continue'}
          </button>
        </form>
      </section>
    </main>
  )
}
