import { useOutletContext } from 'react-router-dom'
import { ArrowRight } from 'lucide-react'

const descriptions = {
  '/inventory': 'Search items, review stock levels, and manage inventory details across your locations.',
  '/stock-adjustment': 'Track receipts, issues, and approved stock adjustments in one place.',
  '/activity-logs': 'Review recent stock movements and operational activity from your workspace.',
  '/telemetry': 'View your connected sensors, current readings, and historical telemetry.',
  '/alerts': 'Monitor low-stock warnings and hardware alerts that may need attention.',
  '/reports': 'Build and export inventory health and operations reports.',
  '/users': 'Manage InvWise workspace users, roles, and account status.',
  '/settings': 'Manage workspace preferences, currency, and system settings.',
}

export default function DashboardPlaceholder({ route }) {
  const { navigate, searchTerm } = useOutletContext()
  const detail = descriptions[route] ?? 'This workspace section will be available soon.'

  return (
    <main className="min-h-[calc(100vh-82px)] px-4 py-5 sm:px-7">
      <section className="rounded-lg border border-slate-200 bg-white p-6 shadow-[0_1px_2px_rgba(15,23,42,0.02)] sm:p-8">
        <p className="text-[9px] font-semibold uppercase tracking-[0.12em] text-teal-700">Enterprise workspace</p>
        <h2 className="mt-2 text-lg font-bold text-slate-900">{route === '/users' ? 'User Management' : route.replace('/', '').replaceAll('-', ' ').replace(/\b\w/g, (letter) => letter.toUpperCase())}</h2>
        <p className="mt-2 max-w-xl text-xs leading-5 text-slate-500">{detail}</p>
        {searchTerm && <p className="mt-3 text-[10px] text-slate-500">Search filter: <span className="font-semibold text-slate-700">{searchTerm}</span></p>}
        <button className="mt-6 inline-flex items-center gap-1.5 rounded-md bg-teal-600 px-3 py-2 text-[10px] font-semibold text-white hover:bg-teal-700" onClick={() => navigate('/dashboard')} type="button">
          Back to dashboard <ArrowRight size={12} />
        </button>
      </section>
    </main>
  )
}
