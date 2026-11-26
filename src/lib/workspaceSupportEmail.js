import { useCallback, useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from './supabase'

export const DEFAULT_WORKSPACE_SUPPORT_EMAIL = 'aidrusaidil@gmail.com'
const SETTINGS_ID = 'exchange_rate_usd_myr'
const STORAGE_KEY = 'invwise.workspaceSupportEmail'
const CHANGE_EVENT = 'invwise:workspace-support-email-changed'
let nextSubscriptionId = 0

function getCachedEmail() {
  try {
    return localStorage.getItem(STORAGE_KEY) || DEFAULT_WORKSPACE_SUPPORT_EMAIL
  } catch {
    return DEFAULT_WORKSPACE_SUPPORT_EMAIL
  }
}

function cacheEmail(email) {
  try {
    localStorage.setItem(STORAGE_KEY, email)
  } catch {
    // The in-memory update and event still reach the current tab.
  }
  window.dispatchEvent(new CustomEvent(CHANGE_EVENT, { detail: email }))
}

export function useWorkspaceSupportEmail() {
  const [email, setEmail] = useState(getCachedEmail)
  const [syncError, setSyncError] = useState('')

  useEffect(() => {
    if (!supabase || !isSupabaseConfigured) return undefined
    let active = true
    const applyEmail = (value) => {
      if (typeof value !== 'string' || !value.trim()) return
      cacheEmail(value.trim())
    }
    const loadEmail = async () => {
      const { data, error } = await supabase
        .from('app_settings')
        .select('support_email')
        .eq('id', SETTINGS_ID)
        .maybeSingle()
      if (!active) return
      if (error) {
        setSyncError(`The workspace support email could not be refreshed. ${error.message}`)
      } else if (data?.support_email) {
        setSyncError('')
        applyEmail(data.support_email)
      }
    }
    const handleChange = (event) => setEmail(event.detail)
    const handleStorage = (event) => {
      if (event.key === STORAGE_KEY) setEmail(event.newValue || DEFAULT_WORKSPACE_SUPPORT_EMAIL)
    }

    window.addEventListener(CHANGE_EVENT, handleChange)
    window.addEventListener('storage', handleStorage)
    void loadEmail()
    const channel = supabase
      .channel(`workspace-support-email-${++nextSubscriptionId}`)
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'app_settings',
        filter: `id=eq.${SETTINGS_ID}`,
      }, (payload) => {
        applyEmail(payload.new?.support_email)
        setSyncError('')
      })
      .subscribe((status) => {
        if (status === 'SUBSCRIBED') void loadEmail()
        if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
          setSyncError('Live workspace support email updates are unavailable.')
        }
      })

    return () => {
      active = false
      window.removeEventListener(CHANGE_EVENT, handleChange)
      window.removeEventListener('storage', handleStorage)
      void supabase.removeChannel(channel)
    }
  }, [])

  const saveEmail = useCallback(async (value) => {
    const normalizedEmail = String(value ?? '').trim().toLowerCase()
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(normalizedEmail) || normalizedEmail.length > 254) {
      throw new Error('Enter a valid workspace support email address.')
    }
    if (!supabase || !isSupabaseConfigured) {
      throw new Error('Connect to Supabase before saving the workspace support email.')
    }
    const { data, error } = await supabase
      .from('app_settings')
      .update({ support_email: normalizedEmail, updated_at: new Date().toISOString() })
      .eq('id', SETTINGS_ID)
      .select('support_email')
      .maybeSingle()
    if (error) throw error
    if (!data?.support_email) {
      throw new Error('The support email was not updated. Confirm that you are an active Super Admin.')
    }
    cacheEmail(data.support_email)
    setSyncError('')
    return data.support_email
  }, [])

  return [email, saveEmail, syncError]
}
