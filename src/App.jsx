import { Component, useEffect, useState } from 'react'
import { BrowserRouter, Navigate, Outlet, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import { isSupabaseConfigured, supabase } from './lib/supabase'
import LoginPage from './pages/LoginPage'
import DashboardPage from './pages/DashboardPage'
import InventoryPage from './pages/InventoryPage'
import ActivityReportsPage from './pages/ActivityReportsPage'
import TelemetryPage from './pages/TelemetryPage'
import UserManagementPage from './pages/UserManagementPage'
import SettingsPage from './pages/SettingsPage'
import DashboardLayout from './components/layout/DashboardLayout'
import { isSuperAdminRole, WORKSPACE_PERMISSION_KEYS, WorkspaceAccessContext, useWorkspaceAccess } from './lib/workspaceAccess'

class AppErrorBoundary extends Component {
  state = { hasError: false, error: null }

  static getDerivedStateFromError(error) {
    return { hasError: true, error }
  }

  componentDidCatch(error, info) {
    console.error('Application render error:', error, info.componentStack)
  }

  render() {
    if (this.state.hasError) {
      const errorMessage = this.state.error instanceof Error
        ? this.state.error.message
        : 'No additional error details are available.'
      return (
        <main className="grid min-h-screen place-items-center bg-slate-50 p-6">
          <section aria-labelledby="app-error-title" className="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm" role="alert">
            <h1 className="text-lg font-semibold text-slate-900" id="app-error-title">We couldn&apos;t load this page</h1>
            <p className="mt-2 text-sm text-slate-600">An unexpected display error occurred. You can try rendering the page again or return to sign in.</p>
            <p className="mt-3 break-words text-xs text-slate-500">{errorMessage}</p>
            <div className="mt-6 flex justify-center gap-5">
              <button className="text-sm font-semibold text-teal-700" onClick={() => this.setState({ hasError: false, error: null })} type="button">Try again</button>
              <a className="text-sm font-semibold text-slate-600" href="/login">Return to sign in</a>
            </div>
          </section>
        </main>
      )
    }

    return this.props.children
  }
}

function ProtectedDashboard({ session }) {
  const [status, setStatus] = useState('checking')
  const [error, setError] = useState('')
  const [access, setAccess] = useState({ role: '', permissions: [], loaded: false })
  const navigate = useNavigate()

  async function signOut() {
    try {
      const { error: signOutError } = await supabase.auth.signOut()
      if (signOutError) throw signOutError
    } catch {
      setError('Unable to sign out. Please try again.')
      setStatus('error')
    }
  }

  useEffect(() => {
    let active = true

    async function checkProfile() {
      if (!supabase || !session?.user) {
        navigate('/login', { replace: true })
        return
      }

      let profile
      let profileError
      try {
        const result = await supabase
          .from('profiles')
          .select('role, is_active')
          .eq('auth_user_id', session.user.id)
          .maybeSingle()
        profile = result.data
        profileError = result.error
      } catch {
        profileError = new Error('Profile lookup failed')
      }

      if (!active) return

      if (profileError) {
        setError('We could not verify your account status. Please try again.')
        setStatus('error')
        return
      }

      if (!profile || profile.is_active !== true || !profile.role) {
        let signOutError
        try {
          const result = await supabase.auth.signOut()
          signOutError = result.error
        } catch {
          signOutError = true
        }
        if (signOutError) {
          if (active) {
            setError(
              'This account is inactive or is not linked to a profile. Sign out and contact your administrator.',
            )
            setStatus('error')
          }
          return
        }
        if (active) {
          navigate('/login', {
            replace: true,
            state: { error: 'This account is inactive or is not linked to a profile.' },
          })
        }
        return
      }

      if (isSuperAdminRole(profile.role)) {
        setAccess({
          role: profile.role,
          permissions: [...WORKSPACE_PERMISSION_KEYS],
          loaded: true,
        })
        setStatus('ready')
        return
      }

      let permissions = []
      if (isSuperAdminRole(profile.role)) {
        permissions = [...WORKSPACE_PERMISSION_KEYS]
      } else if (supabase) {
        const permissionResult = await supabase
          .from('role_permissions')
          .select('permission_key,granted')
          .eq('role_name', profile.role)
          .eq('granted', true)
        if (!permissionResult.error) {
          permissions = (permissionResult.data ?? [])
            .map((item) => item.permission_key)
            .filter((key) => WORKSPACE_PERMISSION_KEYS.includes(key))
        }
      }
      setAccess({
        role: profile.role,
        permissions,
        loaded: true,
      })
      setStatus('ready')
    }

    checkProfile()
    return () => {
      active = false
    }
  }, [navigate, session])

  if (status === 'checking') {
    return <div className="grid min-h-screen place-items-center text-sm text-slate-500">Checking your workspace...</div>
  }

  if (status === 'error') {
    return (
      <main className="grid min-h-screen place-items-center bg-slate-50 p-6">
        <div className="max-w-md rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
          <p className="font-semibold text-slate-900">Unable to verify access</p>
          <p className="mt-2 text-sm text-slate-500">{error}</p>
          <div className="mt-5 flex justify-center gap-5">
            <button className="text-sm font-semibold text-teal-700" onClick={() => window.location.reload()}>Try again</button>
            <button className="text-sm font-semibold text-slate-600" onClick={signOut}>Sign out</button>
          </div>
        </div>
      </main>
    )
  }

  const accessValue = {
    role: access.role,
    permissions: access.permissions,
    loaded: access.loaded,
    allows: (permissionKey) =>
      isSuperAdminRole(access.role) || access.permissions.includes(permissionKey),
  }
  return (
    <WorkspaceAccessContext.Provider value={accessValue}>
      <Outlet />
    </WorkspaceAccessContext.Provider>
  )
}

function PermissionRoute({ permission, children }) {
  const access = useWorkspaceAccess()
  if (!access.loaded) {
    return <div className="grid min-h-[320px] place-items-center text-sm text-slate-500">Checking workspace permissions...</div>
  }
  if (!access.allows(permission)) {
    return (
      <main className="grid min-h-[320px] place-items-center p-6">
        <section className="max-w-md rounded-xl border border-slate-200 bg-white p-8 text-center shadow-sm">
          <h1 className="text-lg font-semibold text-slate-900">Access restricted</h1>
          <p className="mt-2 text-sm text-slate-500">Your role does not have permission to access this page.</p>
        </section>
      </main>
    )
  }
  return children
}

function AppRoutes({ session, loading }) {
  const location = useLocation()

  if (loading) {
    return <div className="grid min-h-screen place-items-center text-sm text-slate-500">Loading workspace...</div>
  }

  return (
    <Routes>
      <Route path="/" element={<Navigate to={session ? '/dashboard' : '/login'} replace />} />
      <Route
        path="/login"
        element={session ? <Navigate to="/dashboard" replace /> : <LoginPage routeError={location.state?.error} />}
      />
      <Route element={
        session
          ? <ProtectedDashboard session={session} />
          : isSupabaseConfigured
            ? <Navigate to="/login" replace />
            : <Outlet />
      }>
        <Route element={<DashboardLayout session={session} />}>
          <Route path="/dashboard" element={<PermissionRoute permission="view_dashboard"><DashboardPage /></PermissionRoute>} />
          <Route path="/inventory" element={<PermissionRoute permission="view_inventory"><InventoryPage mode="inventory" /></PermissionRoute>} />
          <Route path="/stock-adjustment" element={<PermissionRoute permission="adjust_stock"><InventoryPage mode="adjustment" /></PermissionRoute>} />
          <Route path="/activity-logs" element={<PermissionRoute permission="view_activity"><ActivityReportsPage /></PermissionRoute>} />
          <Route path="/telemetry" element={<PermissionRoute permission="view_telemetry"><TelemetryPage /></PermissionRoute>} />
          <Route path="/alerts" element={<PermissionRoute permission="view_alerts"><ActivityReportsPage /></PermissionRoute>} />
          <Route path="/reports" element={<PermissionRoute permission="view_reports"><ActivityReportsPage /></PermissionRoute>} />
          <Route path="/users" element={<PermissionRoute permission="manage_users"><UserManagementPage /></PermissionRoute>} />
          <Route path="/settings" element={<PermissionRoute permission="manage_settings"><SettingsPage /></PermissionRoute>} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default function App() {
  const [session, setSession] = useState(null)
  const [loading, setLoading] = useState(Boolean(supabase))

  useEffect(() => {
    if (!supabase) return undefined

    let active = true
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      if (active) setSession(nextSession)
    })

    supabase.auth.getSession().then(({ data, error }) => {
      if (!active) return
      if (error) console.error('Unable to restore the Supabase session:', error.message)
      setSession(data.session)
      setLoading(false)
    }).catch((error) => {
      if (!active) return
      console.error('Unable to restore the Supabase session:', error)
      setLoading(false)
    })

    return () => {
      active = false
      subscription.unsubscribe()
    }
  }, [])

  return (
    <AppErrorBoundary>
      <BrowserRouter>
        <AppRoutes session={session} loading={loading} />
      </BrowserRouter>
    </AppErrorBoundary>
  )
}
