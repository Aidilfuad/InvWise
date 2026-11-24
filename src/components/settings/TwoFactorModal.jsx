import { useEffect, useRef, useState } from 'react'
import { LoaderCircle, ShieldCheck, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'

export default function TwoFactorModal({ factorId, mode, onClose, onUpdated }) {
  const [factor, setFactor] = useState(null)
  const [code, setCode] = useState('')
  const [pending, setPending] = useState(mode === 'enable')
  const [error, setError] = useState('')
  const enrollmentPromise = useRef(null)

  useEffect(() => {
    if (mode !== 'enable') return undefined
    let active = true
    async function enroll() {
      if (!supabase) {
        setError('Two-factor authentication requires a configured Supabase connection.')
        setPending(false)
        return
      }
      try {
        if (!enrollmentPromise.current) {
          enrollmentPromise.current = supabase.auth.mfa.enroll({
            factorType: 'totp',
            friendlyName: 'InvWise web',
          }).then(({ data, error: enrollError }) => {
            if (enrollError) throw enrollError
            return data
          })
        }
        const data = await enrollmentPromise.current
        if (active) setFactor(data)
      } catch (enrollError) {
        if (active) setError(enrollError instanceof Error ? enrollError.message : 'Unable to start two-factor setup.')
      } finally {
        if (active) setPending(false)
      }
    }
    void enroll()
    return () => { active = false }
  }, [mode])

  async function enable() {
    if (!supabase || !factor?.id) return
    if (!/^\d{6}$/.test(code.trim())) {
      setError('Enter the 6-digit code from your authenticator app.')
      return
    }
    setPending(true)
    setError('')
    try {
      const { data: challenge, error: challengeError } = await supabase.auth.mfa.challenge({ factorId: factor.id })
      if (challengeError) throw challengeError
      const { error: verifyError } = await supabase.auth.mfa.verify({
        factorId: factor.id,
        challengeId: challenge.id,
        code: code.trim(),
      })
      if (verifyError) throw verifyError
      onUpdated(factor.id)
    } catch (verifyError) {
      setError(verifyError instanceof Error ? verifyError.message : 'Unable to verify the authenticator code.')
    } finally {
      setPending(false)
    }
  }

  async function disable() {
    if (!supabase || !factorId) return
    setPending(true)
    setError('')
    try {
      const { error: unenrollError } = await supabase.auth.mfa.unenroll({ factorId })
      if (unenrollError) throw unenrollError
      onUpdated(null)
    } catch (unenrollError) {
      setError(unenrollError instanceof Error ? unenrollError.message : 'Unable to disable two-factor authentication.')
    } finally {
      setPending(false)
    }
  }

  async function cancelEnrollment() {
    if (mode === 'enable' && factor?.id && supabase) {
      setPending(true)
      try {
        const { error: cleanupError } = await supabase.auth.mfa.unenroll({ factorId: factor.id })
        if (cleanupError) throw cleanupError
      } catch (cleanupError) {
        setError(cleanupError instanceof Error ? cleanupError.message : 'Unable to cancel two-factor setup.')
        setPending(false)
        return
      }
      setPending(false)
    }
    onClose()
  }

  return (
    <div className="fixed inset-0 z-[90] grid place-items-center overflow-y-auto bg-slate-950/45 p-4">
      <section aria-labelledby="two-factor-title" aria-modal="true" className="my-auto w-full max-w-[460px] rounded-xl border border-slate-200 bg-white shadow-2xl" role="dialog">
        <header className="flex items-start justify-between border-b border-slate-100 px-5 py-4">
          <div className="flex items-center gap-3">
            <span className="grid h-9 w-9 place-items-center rounded-lg bg-teal-50 text-teal-700"><ShieldCheck size={16} /></span>
            <div>
              <h2 className="text-sm font-bold text-slate-900" id="two-factor-title">{mode === 'enable' ? 'Set up two-factor authentication' : 'Disable two-factor authentication'}</h2>
              <p className="mt-1 text-[10px] text-slate-500">{mode === 'enable' ? 'Protect your account with an authenticator app.' : 'Your account will no longer require a second factor.'}</p>
            </div>
          </div>
          {mode === 'disable' && <button aria-label="Close two-factor settings" className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100" disabled={pending} onClick={onClose} type="button"><X size={15} /></button>}
        </header>

        {mode === 'enable' ? (
          <div className="space-y-4 p-5">
            {pending && <div className="flex items-center gap-2 py-6 text-[10px] text-slate-500"><LoaderCircle className="animate-spin" size={14} /> Preparing authenticator setup…</div>}
            {!pending && factor?.totp && (
              <>
                <p className="text-[10px] leading-4 text-slate-600">Scan this QR code with your authenticator app, then enter the 6-digit code to confirm setup.</p>
                <div className="flex justify-center rounded-lg border border-slate-100 bg-slate-50 p-4">
                  <img alt="Authenticator setup QR code" className="h-40 w-40" src={factor.totp.qr_code} />
                </div>
                <p className="text-[9px] text-slate-500">Can&apos;t scan it? Enter this setup key manually:</p>
                <code className="block break-all rounded bg-slate-50 px-3 py-2 text-[10px] text-slate-700">{factor.totp.secret}</code>
                <label className="block text-[10px] font-semibold text-slate-700">Authenticator code
                  <input autoComplete="one-time-code" className="modal-input mt-1.5" inputMode="numeric" maxLength={6} onChange={(event) => setCode(event.target.value.replace(/\D/g, ''))} placeholder="000000" value={code} />
                </label>
              </>
            )}
            {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
            <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
              <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50 disabled:opacity-50" disabled={pending} onClick={cancelEnrollment} type="button">Cancel</button>
              <button className="h-9 rounded-md bg-teal-600 px-4 text-[10px] font-semibold text-white hover:bg-teal-700 disabled:opacity-50" disabled={pending || !factor?.id} onClick={enable} type="button">{pending ? 'Verifying…' : 'Verify and enable'}</button>
            </div>
          </div>
        ) : (
          <div className="space-y-4 p-5">
            <div className="rounded-lg border border-amber-100 bg-amber-50 p-3 text-[10px] leading-4 text-amber-800">You will be asked for your password only when signing in after you disable this factor.</div>
            {error && <p className="rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[10px] text-rose-700" role="alert">{error}</p>}
            <div className="flex justify-end gap-2 border-t border-slate-100 pt-4">
              <button className="h-9 rounded-md border border-slate-200 px-3 text-[10px] font-semibold text-slate-600 hover:bg-slate-50" disabled={pending} onClick={onClose} type="button">Keep enabled</button>
              <button className="inline-flex h-9 items-center gap-1.5 rounded-md bg-rose-600 px-4 text-[10px] font-semibold text-white hover:bg-rose-700 disabled:opacity-50" disabled={pending} onClick={disable} type="button">{pending ? 'Updating…' : 'Disable 2FA'}</button>
            </div>
          </div>
        )}
      </section>
    </div>
  )
}
