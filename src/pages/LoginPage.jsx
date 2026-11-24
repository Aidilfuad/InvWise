import { useState } from 'react'
import {
  ArrowRight,
  Eye,
  EyeOff,
  IdCard,
  LockKeyhole,
  Mail,
  Package,
  ShieldCheck,
  Thermometer,
  Warehouse,
  X,
} from 'lucide-react'
import ContactAdminModal from '../components/auth/ContactAdminModal'
import RequestAccessModal from '../components/auth/RequestAccessModal'
import { supabase } from '../lib/supabase'

const rememberedIdentifierKey = 'invwise.login.identifier'
const rememberLoginKey = 'invwise.login.remember'

function ResetPasswordModal({ onClose, initialEmail }) {
  const [email, setEmail] = useState(initialEmail)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [sent, setSent] = useState(false)

  async function sendResetLink(event) {
    event.preventDefault()
    setLoading(true)
    setError('')
    if (!supabase) {
      setError('Password recovery is unavailable until Supabase is configured.')
      setLoading(false)
      return
    }

    try {
      const { error: resetError } = await supabase.auth.resetPasswordForEmail(email.trim())
      if (resetError) {
        setError(resetError.message)
        return
      }
      setSent(true)
    } catch {
      setError('Unable to send a password reset email. Check your connection and try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/55 p-4" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !loading) onClose()
    }}>
      <section aria-labelledby="reset-password-title" aria-modal="true" className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl sm:p-8" role="dialog">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-teal-700">Account recovery</p>
            <h2 className="mt-2 text-xl font-bold text-slate-900" id="reset-password-title">Reset password</h2>
          </div>
          <button aria-label="Close dialog" className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700" onClick={onClose} type="button">
            <X size={18} />
          </button>
        </div>
        {sent ? (
          <div className="mt-5">
            <p className="text-sm leading-6 text-slate-600">If an account exists for that email, a password reset link has been sent.</p>
            <button className="mt-6 w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700" onClick={onClose} type="button">Done</button>
          </div>
        ) : (
          <form className="mt-5" onSubmit={sendResetLink}>
            <p className="mb-4 text-sm leading-6 text-slate-500">Enter your account email and we’ll send you a secure password reset link.</p>
            <label className="block text-sm font-medium text-slate-700" htmlFor="reset-email">Work email</label>
            <input autoComplete="email" autoFocus className="modal-input mt-1.5" id="reset-email" onChange={(event) => setEmail(event.target.value)} required type="email" value={email} />
            {error && <p className="mt-3 rounded-lg border border-red-100 bg-red-50 px-3 py-2.5 text-sm text-red-700" role="alert">{error}</p>}
            <button className="mt-5 w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={loading} type="submit">
              {loading ? 'Sending...' : 'Send reset link'}
            </button>
          </form>
        )}
      </section>
    </div>
  )
}

export default function LoginPage({ routeError }) {
  const [loginType, setLoginType] = useState('email')
  const [identifier, setIdentifier] = useState(() => (
    localStorage.getItem(rememberLoginKey) === 'true'
      ? localStorage.getItem(rememberedIdentifierKey) || ''
      : ''
  ))
  const [rememberMe, setRememberMe] = useState(() => localStorage.getItem(rememberLoginKey) === 'true')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(routeError || '')
  const [storageWarning, setStorageWarning] = useState('')
  const [modal, setModal] = useState('')

  async function signIn(event) {
    event.preventDefault()
    if (loading) return
    setError('')
    setStorageWarning('')

    const cleanIdentifier = identifier.trim()
    if (!cleanIdentifier || !password) {
      setError('Enter your email or employee ID and password.')
      return
    }
    if (!supabase) {
      setError('Authentication is unavailable until Supabase is configured.')
      return
    }

    setLoading(true)
    try {
      let email = cleanIdentifier

      if (loginType === 'employee') {
        const { data: resolvedEmail, error: resolveError } = await supabase.rpc(
          'resolve_login_email_by_employee_id',
          { p_employee_id: cleanIdentifier },
        )
        if (resolveError) throw resolveError
        if (typeof resolvedEmail !== 'string' || !resolvedEmail) {
          throw new Error('Invalid Employee ID or password.')
        }
        email = resolvedEmail
      }

      const { error: signInError } = await supabase.auth.signInWithPassword({
        email,
        password,
      })
      if (signInError) {
        const message = signInError.message.toLowerCase().includes('invalid login credentials')
          ? 'Invalid email or password.'
          : signInError.message
        throw new Error(message)
      }

      try {
        if (rememberMe) {
          localStorage.setItem(rememberedIdentifierKey, cleanIdentifier)
          localStorage.setItem(rememberLoginKey, 'true')
        } else {
          localStorage.removeItem(rememberedIdentifierKey)
          localStorage.removeItem(rememberLoginKey)
        }
      } catch {
        setStorageWarning('You are signed in, but this browser could not save your Remember me preference.')
      }
    } catch (signInError) {
      setError(signInError instanceof Error ? signInError.message : 'Unable to sign in. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  function updateRememberMe(checked) {
    setRememberMe(checked)
    try {
      localStorage.setItem(rememberLoginKey, String(checked))
      if (!checked) localStorage.removeItem(rememberedIdentifierKey)
    } catch {
      setStorageWarning('This browser could not save your Remember me preference.')
    }
  }

  const isEmailLogin = loginType === 'email'

  return (
    <main className="min-h-screen bg-slate-50 lg:grid lg:grid-cols-[45.2%_54.8%]">
      <section className="relative flex min-h-[720px] flex-col overflow-hidden bg-[#0b1220] px-7 py-8 text-white sm:px-10 lg:min-h-screen lg:pt-10 lg:pb-5 lg:pl-12 lg:pr-10">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute inset-0 opacity-30"
          style={{
            backgroundImage: 'linear-gradient(rgba(148, 163, 184, 0.075) 1px, transparent 1px), linear-gradient(90deg, rgba(148, 163, 184, 0.075) 1px, transparent 1px)',
            backgroundSize: '46px 46px',
          }}
        />
        <div aria-hidden="true" className="pointer-events-none absolute inset-0 bg-gradient-to-br from-transparent via-transparent to-slate-700/30" />

        <header className="relative z-10 flex items-center gap-3">
          <span className="grid h-9 w-9 translate-y-[5px] place-items-center rounded-xl bg-teal-600 text-white shadow-lg shadow-teal-950/30">
            <Package size={18} strokeWidth={2} />
          </span>
          <span>
            <span className="block text-[22px] font-bold leading-6 tracking-[-0.03em]">InvWise</span>
            <span className="mt-0.5 block text-[10px] font-medium tracking-wide text-slate-400">Enterprise Inventory &amp; Telemetry</span>
          </span>
        </header>

        <div className="relative z-10 flex flex-1 flex-col justify-center py-16 lg:translate-y-9 lg:py-12">
          <div className="max-w-[470px]">
            <p className="text-[10px] font-bold uppercase tracking-[0.19em] text-teal-300">
              Clarity across every warehouse
            </p>
            <h1 className="mt-4 max-w-[410px] text-[32px] font-bold leading-[1.27] tracking-[-0.035em] text-white sm:text-[35px]">
              Enterprise Inventory<br className="hidden lg:block" />
              &amp; Real-Time Warehouse<br className="hidden lg:block" />
              Telemetry
            </h1>
            <p className="mt-5 max-w-[440px] text-[13px] leading-[1.75] text-slate-300">
              Take control of your stock, monitor live sensor data,
              <br className="hidden lg:block" /> and keep every team in sync — from one secure workspace.
            </p>
            <div className="mt-7">
              <span className="block h-[3px] w-10 rounded-full bg-teal-500" />
              <p className="mt-4 text-[11px] text-slate-400">One platform. Every location. Always in view.</p>
            </div>
          </div>
        </div>

        <div className="relative z-10 rounded-2xl border border-slate-700/70 bg-slate-800/60 p-4 shadow-xl shadow-slate-950/10 sm:p-[18px]">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-[12px] font-semibold text-slate-100">Warehouse network</h2>
            <span className="flex items-center gap-2 text-[9px] font-bold tracking-[0.12em] text-emerald-300">
              <span className="h-[5px] w-[5px] rounded-full bg-emerald-400" />
              LIVE
            </span>
          </div>
          <div className="space-y-2">
            <div className="flex items-center gap-3 rounded-lg bg-slate-950/35 px-3 py-[9px] text-[11px] text-slate-200">
              <Warehouse className="text-teal-400" size={14} strokeWidth={2.2} />
              <span>4 Active Warehouses</span>
            </div>
            <div className="flex items-center gap-3 rounded-lg bg-slate-950/35 px-3 py-[9px] text-[11px] text-slate-200">
              <Thermometer className="text-teal-400" size={14} strokeWidth={2.2} />
              <span>Cold Storage: 4.2°C Optimal</span>
            </div>
            <div className="flex items-center gap-3 rounded-lg bg-slate-950/35 px-3 py-[9px] text-[11px] text-slate-200">
              <ShieldCheck className="text-teal-400" size={14} strokeWidth={2.2} />
              <span>99.4% Stock Accuracy</span>
            </div>
          </div>
        </div>

        <footer className="relative z-10 mt-6 text-[9px] text-slate-500">
          © 2026 InvWise. All rights reserved.
        </footer>
      </section>

      <section className="flex min-h-[720px] flex-col items-center justify-center bg-[#f8fafc] px-5 py-12 sm:px-8 lg:min-h-screen lg:px-10 lg:pt-[58px] lg:pb-[22px]">
        <div className="mb-6 flex items-center gap-2 text-[9px] font-bold uppercase tracking-[0.18em] text-slate-500">
          <LockKeyhole size={12} strokeWidth={2.4} />
          Secure workspace access
        </div>

        <div className="w-full max-w-[372px] rounded-2xl border border-slate-200/90 bg-white px-6 py-6 shadow-[0_8px_24px_rgba(15,23,42,0.07)] sm:px-[26px] sm:py-[25px] sm:pb-[45px]">
          <h2 className="text-[23px] font-bold leading-8 tracking-[-0.035em] text-slate-900">Sign in to InvWise</h2>
          <p className="mt-1.5 text-[11px] text-slate-500">Enter your credentials to access your workspace</p>

          <div aria-label="Sign-in method" className="mt-6 grid grid-cols-2 rounded-lg bg-slate-100 p-[4px]" role="tablist">
            <button
              aria-selected={isEmailLogin}
              className={`rounded-md py-[9px] text-[10px] transition ${isEmailLogin ? 'bg-white font-bold text-teal-700 shadow-sm' : 'font-medium text-slate-500 hover:text-slate-700'}`}
              onClick={() => { setLoginType('email'); setError('') }}
              role="tab"
              type="button"
            >
              Email Address
            </button>
            <button
              aria-selected={!isEmailLogin}
              className={`rounded-md py-[9px] text-[10px] transition ${!isEmailLogin ? 'bg-white font-bold text-teal-700 shadow-sm' : 'font-medium text-slate-500 hover:text-slate-700'}`}
              onClick={() => { setLoginType('employee'); setError('') }}
              role="tab"
              type="button"
            >
              Employee ID
            </button>
          </div>

          <form className="mt-5" onSubmit={signIn}>
            <label className="block text-[10px] font-semibold text-slate-700" htmlFor="login-identifier">
              {isEmailLogin ? 'Work Email' : 'Employee ID'}
            </label>
            <div className="relative mt-1.5">
              {isEmailLogin
                ? <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
                : <IdCard className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={15} />}
              <input
                autoComplete={isEmailLogin ? 'username' : 'off'}
                className="h-[41px] w-full rounded-lg border border-slate-300 px-9 text-[11px] text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/15"
                id="login-identifier"
                onChange={(event) => setIdentifier(event.target.value)}
                placeholder={isEmailLogin ? 'name@company.com' : 'EMP-1024'}
                required
                type={isEmailLogin ? 'email' : 'text'}
                value={identifier}
              />
            </div>

            <label className="mt-[18px] block text-[10px] font-semibold text-slate-700" htmlFor="login-password">Password</label>
            <div className="relative mt-1.5">
              <LockKeyhole className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={15} />
              <input
                autoComplete="current-password"
                className="h-[41px] w-full rounded-lg border border-slate-300 px-9 pr-10 text-[11px] text-slate-800 outline-none transition placeholder:text-slate-400 focus:border-teal-500 focus:ring-2 focus:ring-teal-500/15"
                id="login-password"
                onChange={(event) => setPassword(event.target.value)}
                placeholder="Enter your password"
                required
                type={showPassword ? 'text' : 'password'}
                value={password}
              />
              <button
                aria-label={showPassword ? 'Hide password' : 'Show password'}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 rounded p-1 text-slate-400 hover:text-slate-600"
                onClick={() => setShowPassword((current) => !current)}
                type="button"
              >
                {showPassword ? <EyeOff size={15} /> : <Eye size={15} />}
              </button>
            </div>

            <div className="mt-4 flex items-center justify-between gap-2">
              <label className="flex cursor-pointer items-center gap-2 text-[10px] text-slate-600">
                <input
                  checked={rememberMe}
                  className="h-[14px] w-[14px] rounded border-slate-300 text-teal-600 focus:ring-teal-500"
                  onChange={(event) => updateRememberMe(event.target.checked)}
                  type="checkbox"
                />
                Remember me
              </label>
              <button className="text-[10px] font-semibold text-teal-600 hover:text-teal-700" onClick={() => setModal('reset')} type="button">
                Forgot password?
              </button>
            </div>

            {error && <p className="mt-4 rounded-lg border border-red-100 bg-red-50 px-3 py-2.5 text-[11px] leading-5 text-red-700" role="alert">{error}</p>}
            {storageWarning && <p className="mt-3 text-[10px] leading-4 text-amber-700" role="status">{storageWarning}</p>}

            <button
              className="relative mt-5 flex h-[41px] w-full items-center justify-center gap-2 rounded-lg bg-teal-600 text-[11px] font-bold text-white transition hover:bg-teal-700 disabled:opacity-70"
              disabled={loading}
              type="submit"
            >
              {loading ? <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" /> : <>Sign In <ArrowRight className="absolute right-4" size={15} /></>}
            </button>
          </form>

          <div className="my-5 flex items-center gap-3">
            <span className="h-px flex-1 bg-slate-200" />
            <span className="text-[9px] text-slate-400">New to InvWise?</span>
            <span className="h-px flex-1 bg-slate-200" />
          </div>

          <button
            className="h-[41px] w-full rounded-lg border border-slate-300 bg-white text-[11px] font-semibold text-slate-700 transition hover:bg-slate-50"
            onClick={() => setModal('request')}
            type="button"
          >
            Request Account Access
          </button>
        </div>

        <div className="mt-8 text-center">
          <p className="text-[10px] text-slate-500">Having trouble signing in?</p>
          <button className="mt-1.5 text-[10px] font-semibold text-teal-600 hover:text-teal-700" onClick={() => setModal('contact')} type="button">
            Contact your workspace administrator
          </button>
        </div>
      </section>

      {modal === 'reset' && <ResetPasswordModal initialEmail={loginType === 'email' ? identifier : ''} onClose={() => setModal('')} />}
      {modal === 'request' && <RequestAccessModal onClose={() => setModal('')} />}
      {modal === 'contact' && <ContactAdminModal onClose={() => setModal('')} />}
    </main>
  )
}
