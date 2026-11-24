import { useState } from 'react'
import { CheckCircle2, X } from 'lucide-react'
import { supabase } from '../../lib/supabase'

const emptyForm = { name: '', email: '', subject: '', message: '' }

export default function ContactAdminModal({ onClose }) {
  const [form, setForm] = useState(emptyForm)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [submitted, setSubmitted] = useState(false)

  function updateField(event) {
    setForm((current) => ({ ...current, [event.target.name]: event.target.value }))
  }

  async function submitRequest(event) {
    event.preventDefault()
    setLoading(true)
    setError('')

    if (!supabase) {
      setError('Support requests are unavailable until Supabase is configured.')
      setLoading(false)
      return
    }

    try {
      const user = supabase.auth.currentUser
      let profileId = null

      if (user) {
        const { data: profile, error: profileError } = await supabase
          .from('profiles')
          .select('id, is_active')
          .eq('auth_user_id', user.id)
          .maybeSingle()
        if (profileError || !profile || profile.is_active !== true) {
          setError('We could not verify your active workspace profile. Please sign in again.')
          return
        }
        profileId = profile.id
      }

      const { error: requestError } = await supabase.from('support_requests').insert({
        profile_id: profileId,
        name: form.name.trim(),
        email: form.email.trim(),
        subject: form.subject.trim(),
        message: form.message.trim(),
        status: 'open',
      })

      if (requestError) {
        setError('We could not send your support request. Please try again or contact your workspace administrator directly.')
        return
      }

      setSubmitted(true)
    } catch {
      setError('We could not send your support request. Please try again or contact your workspace administrator directly.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/55 p-4" onMouseDown={(event) => {
      if (event.target === event.currentTarget && !loading) onClose()
    }}>
      <section
        aria-labelledby="contact-admin-title"
        aria-modal="true"
        className="max-h-[min(90vh,720px)] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl sm:p-8"
        role="dialog"
      >
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.16em] text-teal-700">Workspace support</p>
            <h2 className="mt-2 text-xl font-bold text-slate-900" id="contact-admin-title">
              {submitted ? 'Support request sent' : 'Contact your administrator'}
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
              Your message has been recorded for the workspace IT team. They can follow up using the email you provided.
            </p>
            <button className="mt-6 w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700" onClick={onClose} type="button">
              Done
            </button>
          </div>
        ) : (
          <>
            <p className="mt-3 text-sm leading-6 text-slate-500">
              Send an issue to your workspace IT team. Your workspace administrator manages the organization-specific support address.
            </p>
            <div className="mt-4 rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
              <p className="text-xs font-semibold text-slate-700">IT support contact</p>
              <p className="mt-1 text-xs leading-5 text-slate-500">
                Workspace administrator · follow-up to the email address you provide
              </p>
            </div>
            <form className="mt-5 space-y-4" onSubmit={submitRequest}>
              <div className="grid gap-4 sm:grid-cols-2">
                <label className="block text-sm font-medium text-slate-700">
                  Name
                  <input autoComplete="name" className="modal-input mt-1.5" name="name" onChange={updateField} required value={form.name} />
                </label>
                <label className="block text-sm font-medium text-slate-700">
                  Email
                  <input autoComplete="email" className="modal-input mt-1.5" name="email" onChange={updateField} required type="email" value={form.email} />
                </label>
              </div>
              <label className="block text-sm font-medium text-slate-700">
                Subject
                <input className="modal-input mt-1.5" maxLength={160} name="subject" onChange={updateField} required value={form.subject} />
              </label>
              <label className="block text-sm font-medium text-slate-700">
                Message
                <textarea className="modal-input mt-1.5 min-h-32 resize-y" maxLength={5000} name="message" onChange={updateField} required value={form.message} />
              </label>
              {error && <p className="rounded-lg border border-red-100 bg-red-50 px-3 py-2.5 text-sm text-red-700" role="alert">{error}</p>}
              <button className="w-full rounded-lg bg-teal-600 px-4 py-3 text-sm font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={loading} type="submit">
                {loading ? 'Sending request...' : 'Send support request'}
              </button>
            </form>
          </>
        )}
      </section>
    </div>
  )
}
