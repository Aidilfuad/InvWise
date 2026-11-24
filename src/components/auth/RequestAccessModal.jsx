import { useEffect, useState } from 'react'
import { CheckCircle2, Eye, EyeOff, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'

const fallbackRoles = ['Warehouse Supervisor', 'Storekeeper']
const fallbackDepartments = [
  'Warehouse Operations',
  'Inventory Control',
  'Telemetry & Maintenance',
  'Logistics & Distribution',
  'Quality & Compliance',
  'Administration',
]

function passwordStrength(password) {
  if (!password) return 0
  return [
    password.length >= 8,
    /[A-Za-z]/.test(password) && /\d/.test(password),
    /[a-z]/.test(password) && /[A-Z]/.test(password),
    /[^A-Za-z0-9]/.test(password),
  ].filter(Boolean).length
}

export default function RequestAccessModal({ onClose }) {
  const [form, setForm] = useState({
    full_name: '',
    work_email: '',
    employee_id: '',
    department: '',
    requested_role: fallbackRoles[0],
    reason: '',
    password: '',
    confirm_password: '',
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [submitted, setSubmitted] = useState(false)
  const [passwordVisible, setPasswordVisible] = useState(false)
  const [confirmPasswordVisible, setConfirmPasswordVisible] = useState(false)
  const [departments, setDepartments] = useState(fallbackDepartments)
  const [roles, setRoles] = useState(fallbackRoles)
  const strength = passwordStrength(form.password)
  const strengthLabels = ['Weak', 'Fair', 'Good', 'Strong']
  const passwordsMatch = form.confirm_password && form.password === form.confirm_password

  useEffect(() => {
    if (!supabase) return
    Promise.all([
      supabase.from('departments').select('name').eq('is_active', true).order('name'),
      supabase.from('custom_roles').select('name').eq('is_active', true).neq('name', 'Super Admin').order('name'),
    ]).then(([departmentResult, roleResult]) => {
      if (!departmentResult.error && departmentResult.data?.length) {
        setDepartments(departmentResult.data.map((item) => item.name))
      }
      if (!roleResult.error && roleResult.data?.length) {
        setRoles(roleResult.data.map((item) => item.name))
        setForm((current) => ({ ...current, requested_role: current.requested_role || roleResult.data[0].name }))
      }
    })
  }, [])

  function updateField(event) {
    setForm((current) => ({ ...current, [event.target.name]: event.target.value }))
  }

  async function submitRequest(event) {
    event.preventDefault()
    setError('')

    if (form.password.length < 8 || !/[A-Za-z]/.test(form.password) || !/\d/.test(form.password)) {
      setError('Use at least 8 characters, including a letter and a number.')
      return
    }
    if (form.password !== form.confirm_password) {
      setError('Passwords do not match.')
      return
    }

    if (!supabase) {
      setError('Account requests are unavailable until Supabase is configured.')
      return
    }

    setLoading(true)
    try {
      const { error: requestError } = await supabase.from('registration_requests').insert({
        full_name: form.full_name.trim(),
        email: form.work_email.trim(),
        employee_id: form.employee_id.trim(),
        department: form.department.trim(),
        requested_role: form.requested_role,
        reason: form.reason.trim(),
        status: 'pending',
      })

      if (requestError) {
        setError('We could not submit your request. Please try again or contact your workspace administrator.')
        return
      }

      setForm((current) => ({ ...current, password: '', confirm_password: '' }))
      setSubmitted(true)
    } catch {
      setError('We could not submit your request. Please try again or contact your workspace administrator.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/55 p-4" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !loading) onClose()
    }}>
      <section
        aria-labelledby="request-access-title"
        aria-modal="true"
        className="max-h-[min(90vh,760px)] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl sm:p-8"
        role="dialog"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-teal-700">InvWise access</p>
            <h2 className="mt-2 text-xl font-bold text-slate-900" id="request-access-title">
              {submitted ? 'Request received' : 'Request account access'}
            </h2>
          </div>
          <button aria-label="Close dialog" className="rounded-lg p-2 text-slate-400 hover:bg-slate-100 hover:text-slate-700" onClick={onClose} type="button">
            <X size={18} />
          </button>
        </div>

        {submitted ? (
          <div className="py-8 text-center">
            <CheckCircle2 className="mx-auto text-teal-600" size={40} />
            <p className="mt-4 text-sm leading-6 text-slate-600">
              Your request has been sent to the InvWise workspace administrators. If approved, you will receive an invitation email to securely set your account password.
            </p>
            <button className="mt-6 w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700" onClick={onClose} type="button">
              Done
            </button>
          </div>
        ) : (
          <form className="mt-6 space-y-4" onSubmit={submitRequest}>
            <div className="grid gap-4 sm:grid-cols-2">
              <label className="block text-sm font-medium text-slate-700">
                Full name
                <input autoComplete="name" className="modal-input mt-1.5" name="full_name" onChange={updateField} required value={form.full_name} />
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Work email
                <input autoComplete="email" className="modal-input mt-1.5" name="work_email" onChange={updateField} required type="email" value={form.work_email} />
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Employee ID
                <input className="modal-input mt-1.5" name="employee_id" onChange={updateField} required value={form.employee_id} />
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Department
                <select className="modal-input mt-1.5" name="department" onChange={updateField} required value={form.department}>
                  <option disabled value="">Select a department</option>
                  {departments.map((department) => <option key={department} value={department}>{department}</option>)}
                </select>
              </label>
              <label className="block text-sm font-medium text-slate-700 sm:col-span-2">
                Requested role
                <select className="modal-input mt-1.5" name="requested_role" onChange={updateField} value={form.requested_role}>
                  {roles.map((role) => <option key={role} value={role}>{role}</option>)}
                </select>
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Password
                <span className="relative mt-1.5 block">
                  <input
                    autoComplete="new-password"
                    className="modal-input pr-11"
                    minLength={8}
                    name="password"
                    onChange={updateField}
                    required
                    type={passwordVisible ? 'text' : 'password'}
                    value={form.password}
                  />
                  <button
                    aria-label={passwordVisible ? 'Hide password' : 'Show password'}
                    className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1.5 text-slate-400 hover:text-slate-700"
                    onClick={() => setPasswordVisible((visible) => !visible)}
                    type="button"
                  >
                    {passwordVisible ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </span>
                <span className="mt-1 block text-xs font-normal text-slate-500">At least 8 characters, including a letter and a number.</span>
                {form.password && (
                  <span className="mt-2 flex items-center gap-2" aria-live="polite">
                    <span className="flex flex-1 gap-1">
                      {strengthLabels.map((label, index) => (
                        <span className={`h-1 flex-1 rounded-full ${index < strength ? (strength < 2 ? 'bg-rose-400' : strength < 3 ? 'bg-amber-400' : 'bg-teal-500') : 'bg-slate-200'}`} key={label} />
                      ))}
                    </span>
                    <span className="text-xs font-medium text-slate-500">{strengthLabels[Math.max(0, strength - 1)]}</span>
                  </span>
                )}
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Confirm password
                <span className="relative mt-1.5 block">
                  <input
                    autoComplete="new-password"
                    className="modal-input pr-11"
                    name="confirm_password"
                    onChange={updateField}
                    required
                    type={confirmPasswordVisible ? 'text' : 'password'}
                    value={form.confirm_password}
                  />
                  <button
                    aria-label={confirmPasswordVisible ? 'Hide confirm password' : 'Show confirm password'}
                    className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1.5 text-slate-400 hover:text-slate-700"
                    onClick={() => setConfirmPasswordVisible((visible) => !visible)}
                    type="button"
                  >
                    {confirmPasswordVisible ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </span>
                {form.confirm_password && <span className={`mt-1 block text-xs font-normal ${passwordsMatch ? 'text-teal-700' : 'text-rose-600'}`} aria-live="polite">{passwordsMatch ? 'Passwords match.' : 'Passwords do not match.'}</span>}
              </label>
              <p className="text-xs leading-5 text-slate-500 sm:col-span-2">
                For your security, this password is checked only in this form and is never saved with your access request. You will set your account password from the invitation email after approval.
              </p>
              <label className="block text-sm font-medium text-slate-700 sm:col-span-2">
                Reason for access
                <textarea className="modal-input mt-1.5 min-h-24 resize-y" name="reason" onChange={updateField} required value={form.reason} />
              </label>
            </div>
            {error && <p className="rounded-lg border border-red-100 bg-red-50 px-3 py-2.5 text-sm text-red-700" role="alert">{error}</p>}
            <button className="w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={loading} type="submit">
              {loading ? 'Submitting request...' : 'Submit access request'}
            </button>
          </form>
        )}
      </section>
    </div>
  )
}
