import { useEffect, useState } from 'react'
import {
  Bell,
  Check,
  ChevronDown,
  Globe2,
  Menu,
  Save,
  Search,
  ShieldCheck,
  SlidersHorizontal,
} from 'lucide-react'
import { useOutletContext } from 'react-router-dom'
import ChangePasswordModal from '../components/settings/ChangePasswordModal'
import TwoFactorModal from '../components/settings/TwoFactorModal'
import RolePermissionsModal from '../components/users/RolePermissionsModal'
import { isSupabaseConfigured, supabase } from '../lib/supabase'
import { isSuperAdminRole, useWorkspaceAccess } from '../lib/workspaceAccess'

const initialPreferences = {
  workspaceName: 'Acme Operations',
  currencyCode: 'MYR',
  timezone: 'Asia/Kuala_Lumpur',
  dateFormat: 'DD/MM/YYYY',
  language: 'en',
  appearance: 'light',
  temperatureMin: '18',
  temperatureMax: '26',
  humidityMin: '40',
  humidityMax: '60',
  powerWarning: '60',
  offlineTimeout: '5',
  voltageWarningThreshold: '250',
  currentWarningThreshold: '10',
  realtimeEnabled: true,
  emailAlerts: true,
  inAppNotifications: true,
  weeklyDigest: false,
  sessionTimeout: '30',
}

const supportedTimezones = [
  ['Asia/Kuala_Lumpur', '(UTC+08:00) Kuala Lumpur'],
  ['Asia/Singapore', '(UTC+08:00) Singapore'],
  ['Asia/Jakarta', '(UTC+07:00) Jakarta'],
  ['Asia/Tokyo', '(UTC+09:00) Tokyo'],
  ['UTC', '(UTC+00:00) Coordinated Universal Time'],
]

function localStorageKey(profileId) {
  return `invwise.settings.${profileId || 'current'}`
}

function safeLocalPreferences(profileId) {
  try {
    const raw = localStorage.getItem(localStorageKey(profileId))
    if (!raw) return {}
    const parsed = JSON.parse(raw)
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return {}
    return parsed
  } catch {
    return {}
  }
}

function validNumber(value) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function showTime(value) {
  return value ? new Date(value).toLocaleString([], { hour: '2-digit', minute: '2-digit' }) : 'just now'
}

function applyWebAppearance(mode) {
  const dark = mode === 'dark' ||
    (mode === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches)
  document.documentElement.dataset.theme = dark ? 'dark' : 'light'
  document.documentElement.style.colorScheme = dark ? 'dark' : 'light'
}

function Toggle({ checked, label, onChange, disabled = false }) {
  return (
    <button
      aria-checked={checked}
      aria-label={label}
      className={`relative inline-flex h-[18px] w-9 items-center rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-teal-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 ${checked ? 'bg-teal-600' : 'bg-slate-300'}`}
      disabled={disabled}
      onClick={onChange}
      role="switch"
      type="button"
    >
      <span className={`h-3.5 w-3.5 rounded-full bg-white shadow transition-transform ${checked ? 'translate-x-[18px]' : 'translate-x-[2px]'}`} />
    </button>
  )
}

export default function SettingsPage() {
  const context = useOutletContext() ?? {}
  const access = useWorkspaceAccess()
  const session = context.session
  const [preferences, setPreferences] = useState(initialPreferences)
  const [profile, setProfile] = useState({
    id: context.data?.profile?.id ?? '',
    fullName: context.data?.profile?.full_name ?? '',
    email: session?.user?.email ?? '',
    employeeId: '',
    role: context.data?.profile?.role ?? 'Staff',
  })
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [dirty, setDirty] = useState(false)
  const [loadError, setLoadError] = useState('')
  const [saveMessage, setSaveMessage] = useState('Loading your preferences…')
  const [savedAt, setSavedAt] = useState('')
  const [notice, setNotice] = useState('')
  const [notificationsOpen, setNotificationsOpen] = useState(false)
  const [modal, setModal] = useState(null)
  const [mfaFactorId, setMfaFactorId] = useState('')
  const [mfaError, setMfaError] = useState('')

  const alertCount = context.data?.activeAlertCount ?? 0
  const globalProfile = context.data?.profile

  useEffect(() => {
    document.title = 'Settings | InvWise'
  }, [])

  useEffect(() => {
    applyWebAppearance(preferences.appearance)
  }, [preferences.appearance])

  useEffect(() => {
    let active = true
    async function load() {
      const currentProfileId = globalProfile?.id ?? ''
      let nextProfile = {
        id: currentProfileId,
        fullName: globalProfile?.full_name ?? '',
        email: session?.user?.email ?? '',
        employeeId: '',
        role: globalProfile?.role ?? 'Staff',
      }
      let nextPreferences = { ...initialPreferences, ...safeLocalPreferences(currentProfileId) }
      const issues = []

      if (supabase && isSupabaseConfigured && session?.user?.id) {
        const [profileResult, userSettingsResult, telemetryResult] = await Promise.allSettled([
          supabase.from('profiles')
            .select('id,full_name,email,employee_id,role,is_active')
            .eq('auth_user_id', session.user.id)
            .maybeSingle(),
          currentProfileId
            ? supabase.from('user_settings').select('currency_code,theme_mode,language_code').eq('profile_id', currentProfileId).maybeSingle()
            : Promise.resolve({ data: null, error: null }),
          supabase.from('telemetry_settings')
            .select('voltage_warning_threshold,current_warning_threshold,offline_timeout_minutes,realtime_enabled')
            .eq('id', 'default')
            .maybeSingle(),
        ])

        if (profileResult.status === 'fulfilled' && !profileResult.value.error && profileResult.value.data) {
          const row = profileResult.value.data
          nextProfile = {
            id: row.id,
            fullName: row.full_name ?? nextProfile.fullName,
            email: row.email ?? session.user.email ?? '',
            employeeId: row.employee_id ?? '',
            role: row.role ?? nextProfile.role,
          }
          nextPreferences = { ...nextPreferences, ...safeLocalPreferences(row.id) }
        } else {
          const profileError = profileResult.status === 'rejected' ? profileResult.reason : profileResult.value.error
          if (profileError) issues.push(`Profile: ${profileError.message ?? 'unavailable'}`)
        }

        if (userSettingsResult.status === 'fulfilled' && !userSettingsResult.value.error) {
          const row = userSettingsResult.value.data
          if (row) {
            nextPreferences.currencyCode = row.currency_code ?? nextPreferences.currencyCode
            nextPreferences.appearance = row.theme_mode ?? nextPreferences.appearance
            nextPreferences.language = row.language_code ?? nextPreferences.language
          }
        } else {
          const settingsError = userSettingsResult.status === 'rejected' ? userSettingsResult.reason : userSettingsResult.value.error
          issues.push(`User preferences: ${settingsError?.message ?? 'unavailable'}`)
        }

        if (telemetryResult.status === 'fulfilled' && !telemetryResult.value.error) {
          const row = telemetryResult.value.data
          if (row) {
            nextPreferences.currentWarningThreshold = String(row.current_warning_threshold ?? nextPreferences.currentWarningThreshold)
            nextPreferences.voltageWarningThreshold = String(row.voltage_warning_threshold ?? nextPreferences.voltageWarningThreshold)
            nextPreferences.offlineTimeout = String(row.offline_timeout_minutes ?? nextPreferences.offlineTimeout)
            nextPreferences.realtimeEnabled = row.realtime_enabled ?? nextPreferences.realtimeEnabled
          }
        } else {
          const telemetryError = telemetryResult.status === 'rejected' ? telemetryResult.reason : telemetryResult.value.error
          issues.push(`Telemetry defaults: ${telemetryError?.message ?? 'unavailable'}`)
        }

        try {
          const { data: factors, error: mfaListError } = await supabase.auth.mfa.listFactors()
          if (mfaListError) throw mfaListError
          const verifiedFactor = (factors?.totp ?? []).find((factor) => factor.status === 'verified')
          if (active) setMfaFactorId(verifiedFactor?.id ?? '')
        } catch (mfaLoadError) {
          if (active) setMfaError(mfaLoadError instanceof Error ? mfaLoadError.message : 'Two-factor status is unavailable.')
        }
      } else {
        issues.push('Supabase is not configured. Changes will be saved on this device only.')
      }

      if (!active) return
      setProfile(nextProfile)
      setPreferences(nextPreferences)
      setLoadError(issues.length ? issues.join(' ') : '')
      setSaveMessage(issues.length ? 'Showing locally saved preferences; verify remote access.' : 'All changes saved.')
      setLoading(false)
    }

    void load().catch((loadIssue) => {
      if (!active) return
      setLoadError(loadIssue instanceof Error ? loadIssue.message : 'Unable to load settings.')
      setSaveMessage('Some settings could not be loaded.')
      setLoading(false)
    })
    return () => { active = false }
  }, [globalProfile?.id, globalProfile?.full_name, globalProfile?.role, session?.user?.email, session?.user?.id])

  useEffect(() => {
    if (!notice) return undefined
    const timer = window.setTimeout(() => setNotice(''), 3500)
    return () => window.clearTimeout(timer)
  }, [notice])

  const query = search.trim().toLowerCase()
  const showWorkspace = !query || ['workspace', 'display', 'currency', 'timezone', 'date format', 'language', 'appearance'].some((term) => term.includes(query) || query.includes(term))
  const showTelemetry = !query || ['telemetry', 'alert', 'temperature', 'humidity', 'power', 'offline', 'email', 'notification', 'digest'].some((term) => term.includes(query) || query.includes(term))
  const showAccount = !query || ['account', 'security', 'name', 'email', 'employee', 'role', 'two-factor', 'password', 'session'].some((term) => term.includes(query) || query.includes(term))

  const updatePreference = (key, value) => {
    setPreferences((current) => ({ ...current, [key]: value }))
    if (key === 'appearance') applyWebAppearance(value)
    setDirty(true)
    setSaveMessage('Unsaved changes')
  }

  async function saveChanges() {
    if (!profile.fullName.trim()) {
      setLoadError('Enter your full name before saving.')
      return
    }
    const temperatureMin = validNumber(preferences.temperatureMin)
    const temperatureMax = validNumber(preferences.temperatureMax)
    const humidityMin = validNumber(preferences.humidityMin)
    const humidityMax = validNumber(preferences.humidityMax)
    const powerWarning = validNumber(preferences.powerWarning)
    const offlineTimeout = validNumber(preferences.offlineTimeout)
    if (temperatureMin == null || temperatureMax == null || temperatureMin >= temperatureMax) {
      setLoadError('Temperature minimum must be lower than its maximum.')
      return
    }
    if (humidityMin == null || humidityMax == null || humidityMin >= humidityMax || humidityMin < 0 || humidityMax > 100) {
      setLoadError('Humidity values must be between 0 and 100, with the minimum below the maximum.')
      return
    }
    if (powerWarning == null || powerWarning <= 0) {
      setLoadError('Power warning must be greater than zero.')
      return
    }
    if (offlineTimeout == null || !Number.isInteger(offlineTimeout) || offlineTimeout < 2 || offlineTimeout > 60) {
      setLoadError('Sensor offline timeout must be between 2 and 60 minutes.')
      return
    }

    setSaving(true)
    setLoadError('')
    setSaveMessage('Saving changes…')
    const localPreferences = { ...preferences }
    const issues = []
    try {
      localStorage.setItem(localStorageKey(profile.id), JSON.stringify(localPreferences))
    } catch (storageError) {
      issues.push(`Local preference storage: ${storageError instanceof Error ? storageError.message : 'unavailable'}`)
    }

    if (supabase && isSupabaseConfigured && profile.id && session?.user?.id) {
      const [userSettingsResult, telemetryResult, profileResult] = await Promise.allSettled([
        supabase.from('user_settings').upsert({
          profile_id: profile.id,
          currency_code: preferences.currencyCode,
          theme_mode: preferences.appearance,
          language_code: preferences.language,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'profile_id' }),
        supabase.from('telemetry_settings')
          .update({ offline_timeout_minutes: offlineTimeout })
          .eq('id', 'default')
          .select('id')
          .maybeSingle(),
        supabase.from('profiles')
          .update({ full_name: profile.fullName.trim() })
          .eq('id', profile.id)
          .eq('auth_user_id', session.user.id)
          .select('id')
          .maybeSingle(),
      ])
      if (userSettingsResult.status === 'rejected' || userSettingsResult.value.error) {
        const issue = userSettingsResult.status === 'rejected' ? userSettingsResult.reason : userSettingsResult.value.error
        issues.push(`Currency, language, or appearance could not be synced: ${issue?.message ?? 'permission denied'}`)
      }
      if (telemetryResult.status === 'rejected' || telemetryResult.value.error || !telemetryResult.value.data) {
        const issue = telemetryResult.status === 'rejected' ? telemetryResult.reason : telemetryResult.value.error
        issues.push(`Offline timeout could not be synced to telemetry settings: ${issue?.message ?? 'the default settings row is unavailable'}`)
      }
      if (profileResult.status === 'rejected' || profileResult.value.error || !profileResult.value.data) {
        const issue = profileResult.status === 'rejected' ? profileResult.reason : profileResult.value.error
        issues.push(`Profile name could not be synced: ${issue?.message ?? 'profile not updated'}`)
      }
    } else {
      issues.push('Supabase is unavailable; these changes are stored on this device only.')
    }

    const now = new Date().toISOString()
    setSavedAt(now)
    setDirty(false)
    if (issues.length) {
      setLoadError(issues.join(' '))
      setSaveMessage('Saved locally with remote sync warnings.')
    } else {
      setSaveMessage(`All changes saved · Last updated at ${showTime(now)} MYT`)
    }
    try {
      if (typeof context.refresh === 'function') await context.refresh()
    } catch (refreshError) {
      setLoadError((current) => [current, `Workspace data refresh failed: ${refreshError instanceof Error ? refreshError.message : String(refreshError)}`].filter(Boolean).join(' '))
    }
    setSaving(false)
  }

  function updateProfileName(value) {
    setProfile((current) => ({ ...current, fullName: value }))
    setDirty(true)
    setSaveMessage('Unsaved changes')
  }

  function startMfaChange() {
    setMfaError('')
    if (!supabase || !isSupabaseConfigured) {
      setMfaError('Two-factor authentication requires a configured Supabase connection.')
      return
    }
    setModal(mfaFactorId ? { type: 'mfa-disable' } : { type: 'mfa-enable' })
  }

  function mfaUpdated(factorId) {
    const enabling = modal?.type === 'mfa-enable'
    setMfaFactorId(enabling ? factorId : '')
    setModal(null)
    setMfaError('')
    setNotice(enabling ? 'Two-factor authentication is enabled.' : 'Two-factor authentication is disabled.')
  }

  const notifications = context.data?.alerts ?? []
  const visibleNotifications = notifications.slice(0, 4)

  return (
    <main className="min-h-screen bg-[#f8fafc] px-4 pb-8 pt-5 sm:px-6 lg:px-7">
      <div className="mx-auto max-w-[1500px]">
        <header className="mb-4">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="flex items-start gap-2.5">
              <button aria-label="Open navigation menu" className="mt-1 grid h-8 w-8 shrink-0 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 lg:hidden" onClick={context.openMobileSidebar} type="button"><Menu size={15} /></button>
              <div>
                <h1 className="text-xl font-bold tracking-tight text-slate-900 sm:text-2xl">Settings</h1>
                <p className="mt-1 text-[10px] text-slate-500 sm:text-xs">Make InvWise work the way your team does.</p>
              </div>
            </div>
            <div className="flex w-full flex-wrap items-center justify-between gap-2 sm:w-auto sm:justify-end">
              <label className="relative min-w-[190px] flex-1 sm:w-[220px] sm:flex-none">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" size={13} />
                <input aria-label="Search settings" className="h-8 w-full rounded-md border border-slate-200 bg-white pl-8 pr-3 text-[9px] outline-none placeholder:text-slate-400 focus:border-teal-500" onChange={(event) => setSearch(event.target.value)} placeholder="Search settings..." value={search} />
              </label>
              <div className="relative">
                <button aria-expanded={notificationsOpen} aria-label={`Notifications, ${alertCount} active`} className="relative grid h-8 w-8 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 hover:bg-slate-50" onClick={() => setNotificationsOpen((open) => !open)} type="button">
                  <Bell size={14} />
                  {alertCount > 0 && <span className="absolute -right-1 -top-1 h-2 w-2 rounded-full bg-amber-500" />}
                </button>
                {notificationsOpen && <div className="absolute right-0 top-10 z-30 w-64 rounded-lg border border-slate-200 bg-white p-3 shadow-xl">
                  <div className="flex items-center justify-between"><p className="text-[10px] font-bold text-slate-800">Notifications</p><span className="text-[8px] text-slate-400">{alertCount} active</span></div>
                  {visibleNotifications.length ? visibleNotifications.map((alert) => <p className="mt-2 border-t border-slate-100 pt-2 text-[9px] text-slate-600" key={alert.id}>{alert.title}</p>) : <p className="mt-2 text-[9px] text-slate-500">No recent notifications.</p>}
                </div>}
              </div>
              <span className={`hidden text-[8px] sm:inline ${dirty ? 'text-amber-700' : 'text-slate-400'}`}>{loading ? 'Loading…' : dirty ? 'Unsaved changes' : saveMessage}</span>
              <button className="inline-flex h-8 items-center gap-1.5 rounded-md bg-teal-600 px-3 text-[9px] font-semibold text-white hover:bg-teal-700 disabled:opacity-60" disabled={saving || loading} onClick={saveChanges} type="button">
                <Save size={12} /> {saving ? 'Saving…' : 'Save Changes'}
              </button>
            </div>
          </div>
          <div className="mt-4 flex flex-wrap items-center gap-2 border-b border-slate-200">
            <span className="inline-flex items-center gap-1.5 border-b-2 border-teal-600 px-1 pb-2 text-[9px] font-semibold text-teal-700"><SlidersHorizontal size={12} /> Settings</span>
            {isSuperAdminRole(access.role) && (
              <div className="mb-1.5 flex w-full flex-wrap gap-2 sm:ml-auto sm:w-auto">
                <button className="h-8 rounded-md border border-slate-200 bg-white px-3 text-[9px] font-semibold text-slate-700" onClick={() => setModal({ type: 'access', initialTab: 'permissions' })} type="button">Manage Role Permissions</button>
                <button className="h-8 rounded-md border border-slate-200 bg-white px-3 text-[9px] font-semibold text-slate-700" onClick={() => setModal({ type: 'access', initialTab: 'roles' })} type="button">+ New Role</button>
                <button className="h-8 rounded-md bg-teal-600 px-3 text-[9px] font-semibold text-white" onClick={() => setModal({ type: 'access', initialTab: 'departments' })} type="button">+ New Department</button>
              </div>
            )}
          </div>
        </header>

        {loadError && <p className="mb-3 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-[9px] leading-4 text-amber-800" role="status">{loadError}</p>}

        {showWorkspace && (
          <SettingsCard icon={Globe2} title="Workspace & Display" subtitle="Regional preferences used throughout your workspace.">
            <div className="grid gap-x-4 gap-y-3 sm:grid-cols-2 xl:grid-cols-3">
              <TextSetting label="Workspace name" onChange={(value) => updatePreference('workspaceName', value)} value={preferences.workspaceName} />
              <div className="block text-[9px] font-semibold text-slate-600">
                Default currency
                <div aria-label="Default currency" className="mt-1.5 grid h-8 grid-cols-2 rounded-md border border-slate-200 bg-slate-50 p-0.5" role="group">
                  {[['MYR', 'MYR (RM)'], ['USD', 'USD ($)']].map(([value, label]) => (
                    <button aria-pressed={preferences.currencyCode === value} className={`rounded text-[9px] transition ${preferences.currencyCode === value ? 'bg-white font-semibold text-teal-700 shadow-sm' : 'text-slate-500 hover:text-slate-800'}`} key={value} onClick={() => updatePreference('currencyCode', value)} type="button">{label}</button>
                  ))}
                </div>
              </div>
              <SelectSetting label="Timezone" onChange={(value) => updatePreference('timezone', value)} value={preferences.timezone}>
                {supportedTimezones.map(([value, label]) => <option key={value} value={value}>{label}</option>)}
              </SelectSetting>
              <SelectSetting label="Date format" onChange={(value) => updatePreference('dateFormat', value)} value={preferences.dateFormat}>
                <option value="DD/MM/YYYY">DD/MM/YYYY</option><option value="MM/DD/YYYY">MM/DD/YYYY</option><option value="YYYY-MM-DD">YYYY-MM-DD</option>
              </SelectSetting>
              <SelectSetting label="Language" onChange={(value) => updatePreference('language', value)} value={preferences.language}>
                <option value="en">English (UK)</option><option value="ms">Bahasa Melayu</option>
              </SelectSetting>
              <SelectSetting label="Appearance" onChange={(value) => updatePreference('appearance', value)} value={preferences.appearance}>
                <option value="light">Light</option><option value="dark">Dark</option><option value="system">System</option>
              </SelectSetting>
            </div>
            <p className="mt-3 text-[8px] text-slate-400">Currency, language, and appearance sync with your Supabase user settings. Workspace name, timezone, and date format are saved on this device because those fields are not in the current schema.</p>
          </SettingsCard>
        )}

        {showTelemetry && (
          <SettingsCard icon={Bell} title="Telemetry & Alert Defaults" subtitle="Starting thresholds for new sensors. Individual sensor settings take priority.">
            <div className="grid gap-4 xl:grid-cols-[1.25fr_0.95fr]">
              <div className="grid gap-3 sm:grid-cols-2">
                <RangeSetting label="Temperature range (°C)" minValue={preferences.temperatureMin} maxValue={preferences.temperatureMax} onMin={(value) => updatePreference('temperatureMin', value)} onMax={(value) => updatePreference('temperatureMax', value)} />
                <RangeSetting label="Humidity range (%)" minValue={preferences.humidityMin} maxValue={preferences.humidityMax} onMin={(value) => updatePreference('humidityMin', value)} onMax={(value) => updatePreference('humidityMax', value)} />
                <NumberSetting label="Power warning (kW)" min="0.1" onChange={(value) => updatePreference('powerWarning', value)} step="0.1" value={preferences.powerWarning} />
                <SelectSetting label="Offline after" onChange={(value) => updatePreference('offlineTimeout', value)} value={preferences.offlineTimeout}>
                  <option value="2">2 minutes</option><option value="5">5 minutes</option><option value="10">10 minutes</option><option value="15">15 minutes</option><option value="30">30 minutes</option><option value="60">60 minutes</option>
                </SelectSetting>
              </div>
              <div className="space-y-3 border-t border-slate-100 pt-3 xl:border-l xl:border-t-0 xl:pl-4 xl:pt-0">
                <ToggleSetting description="Send warnings and offline notifications." label="Email alerts" onChange={(value) => updatePreference('emailAlerts', value)} value={preferences.emailAlerts} />
                <ToggleSetting description="Keep alerts in your notification center." label="In-app notifications" onChange={(value) => updatePreference('inAppNotifications', value)} value={preferences.inAppNotifications} />
                <ToggleSetting description="A summary of your warehouse health." label="Weekly activity digest" onChange={(value) => updatePreference('weeklyDigest', value)} value={preferences.weeklyDigest} />
              </div>
            </div>
            <p className="mt-3 text-[8px] text-slate-400">Offline timeout syncs to telemetry_settings. Voltage/current thresholds map to the documented database fields; temperature, humidity, power, and notification delivery preferences are saved locally because the current schema has no matching columns.</p>
          </SettingsCard>
        )}

        {showAccount && (
          <SettingsCard icon={ShieldCheck} title="Account & Security" subtitle="Manage your profile and protect access to your account.">
            <div className="grid gap-4 xl:grid-cols-[1.25fr_0.95fr]">
              <div>
                <div className="grid gap-3 sm:grid-cols-2">
                  <TextSetting label="Full name" onChange={updateProfileName} value={profile.fullName} />
                  <TextSetting label="Email address" readOnly value={profile.email} />
                  <TextSetting label="Employee ID" readOnly value={profile.employeeId || '—'} muted />
                  <TextSetting label="Workspace role" readOnly value={profile.role} muted />
                </div>
                <p className="mt-3 text-[8px] text-slate-400">Contact a workspace administrator to update your role or employee ID.</p>
              </div>
              <div className="space-y-3 border-t border-slate-100 pt-3 xl:border-l xl:border-t-0 xl:pl-4 xl:pt-0">
                <div className="flex items-center justify-between gap-3">
                  <div><p className="text-[9px] font-semibold text-slate-700">Two-factor authentication</p><p className="mt-0.5 text-[8px] text-slate-400">{mfaFactorId ? 'An authenticator app is connected.' : 'An extra layer of protection for your account.'}</p></div>
                  <Toggle checked={Boolean(mfaFactorId)} label={`${mfaFactorId ? 'Disable' : 'Enable'} two-factor authentication`} onChange={startMfaChange} />
                </div>
                {mfaError && <p className="text-[8px] leading-4 text-rose-700" role="alert">{mfaError}</p>}
                <SelectSetting label="Session timeout" onChange={(value) => updatePreference('sessionTimeout', value)} value={preferences.sessionTimeout}>
                  <option value="15">15 minutes</option><option value="30">30 minutes</option><option value="60">60 minutes</option><option value="120">2 hours</option>
                </SelectSetting>
                <div className="flex items-center justify-between gap-3 border-t border-slate-100 pt-3">
                  <div><p className="text-[9px] font-semibold text-slate-700">Password</p><p className="mt-0.5 text-[8px] text-slate-400">Change your account password securely.</p></div>
                  <button className="h-8 rounded-md border border-slate-200 px-3 text-[9px] font-semibold text-slate-700 hover:bg-slate-50" onClick={() => setModal({ type: 'password' })} type="button">Change password</button>
                </div>
              </div>
            </div>
          </SettingsCard>
        )}

        {!showWorkspace && !showTelemetry && !showAccount && <div className="rounded-lg border border-dashed border-slate-200 bg-white py-12 text-center text-xs text-slate-500">No settings match “{search}”.</div>}

        <footer className="mt-4 flex flex-wrap items-center justify-between gap-2 text-[8px] text-slate-400">
          <span className="inline-flex items-center gap-1.5"><Check size={11} className={dirty ? 'text-amber-500' : 'text-teal-600'} /> {saveMessage}{savedAt ? ` · Last updated ${showTime(savedAt)} MYT` : ''}</span>
          <span>Changes apply to {preferences.workspaceName || 'your workspace'}</span>
        </footer>
      </div>

      {modal?.type === 'password' && <ChangePasswordModal email={profile.email} onClose={() => setModal(null)} onSuccess={() => { setModal(null); setNotice('Password updated successfully.') }} />}
      {(modal?.type === 'mfa-enable' || modal?.type === 'mfa-disable') && <TwoFactorModal factorId={mfaFactorId} mode={modal.type === 'mfa-enable' ? 'enable' : 'disable'} onClose={() => setModal(null)} onUpdated={mfaUpdated} />}
      {modal?.type === 'access' && <RolePermissionsModal initialTab={modal.initialTab || 'permissions'} onClose={() => setModal(null)} />}
      {notice && <div className="fixed bottom-5 right-5 z-[100] rounded-lg bg-slate-900 px-4 py-3 text-[10px] text-white shadow-xl" role="status">{notice}</div>}
    </main>
  )
}

function SettingsCard({ children, icon: Icon, subtitle, title }) {
  return (
    <section className="mb-4 rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)] sm:p-5">
      <header className="mb-4 flex items-start gap-2.5">
        <span className="grid h-7 w-7 shrink-0 place-items-center rounded-md bg-teal-50 text-teal-700"><Icon size={14} /></span>
        <div><h2 className="text-[11px] font-bold text-slate-900">{title}</h2><p className="mt-1 text-[8px] text-slate-500">{subtitle}</p></div>
      </header>
      {children}
    </section>
  )
}

function TextSetting({ label, muted = false, onChange, readOnly = false, value }) {
  return (
    <label className="block text-[8px] font-medium text-slate-500">
      {label}
      <input className={`mt-1.5 h-8 w-full rounded-md border px-2.5 text-[9px] outline-none focus:border-teal-500 ${muted ? 'border-slate-200 bg-slate-50 text-slate-400' : 'border-slate-200 bg-white text-slate-700'}`} onChange={(event) => onChange?.(event.target.value)} readOnly={readOnly} value={value} />
    </label>
  )
}

function NumberSetting({ label, min, onChange, step, value }) {
  return (
    <label className="block text-[8px] font-medium text-slate-500">
      {label}
      <input className="mt-1.5 h-8 w-full rounded-md border border-slate-200 px-2.5 text-[9px] text-slate-700 outline-none focus:border-teal-500" min={min} onChange={(event) => onChange(event.target.value)} step={step} type="number" value={value} />
    </label>
  )
}

function SelectSetting({ children, label, onChange, value }) {
  return (
    <label className="block text-[8px] font-medium text-slate-500">
      {label}
      <span className="relative mt-1.5 block">
        <select className="h-8 w-full appearance-none rounded-md border border-slate-200 bg-white pl-2.5 pr-7 text-[9px] text-slate-700 outline-none focus:border-teal-500" onChange={(event) => onChange(event.target.value)} value={value}>{children}</select>
        <ChevronDown className="pointer-events-none absolute right-2 top-1/2 -translate-y-1/2 text-slate-400" size={12} />
      </span>
    </label>
  )
}

function RangeSetting({ label, maxValue, minValue, onMax, onMin }) {
  return (
    <fieldset className="min-w-0">
      <legend className="text-[8px] font-medium text-slate-500">{label}</legend>
      <div className="mt-1.5 flex h-8 items-center rounded-md border border-slate-200 px-2">
        <input aria-label={`${label} minimum`} className="min-w-0 flex-1 bg-transparent text-[9px] text-slate-700 outline-none" onChange={(event) => onMin(event.target.value)} type="number" value={minValue} />
        <span className="px-1 text-[8px] text-slate-400">–</span>
        <input aria-label={`${label} maximum`} className="min-w-0 flex-1 bg-transparent text-[9px] text-slate-700 outline-none" onChange={(event) => onMax(event.target.value)} type="number" value={maxValue} />
      </div>
    </fieldset>
  )
}

function ToggleSetting({ description, label, onChange, value }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <div><p className="text-[9px] font-semibold text-slate-700">{label}</p><p className="mt-0.5 text-[8px] text-slate-400">{description}</p></div>
      <Toggle checked={value} label={label} onChange={() => onChange(!value)} />
    </div>
  )
}
