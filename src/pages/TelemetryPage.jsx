import { useEffect, useState } from 'react'
import { useOutletContext } from 'react-router-dom'
import {
  Activity,
  Bell,
  Check,
  CircleHelp,
  Clock3,
  Menu,
  RefreshCw,
  Settings2,
  Thermometer,
  Wifi,
  Zap,
} from 'lucide-react'
import SensorDetailsDrawer from '../components/telemetry/SensorDetailsDrawer'
import TelemetrySensorTable from '../components/telemetry/TelemetrySensorTable'
import TelemetryTrendCard from '../components/telemetry/TelemetryTrendCard'
import ThresholdSettingsModal from '../components/telemetry/ThresholdSettingsModal'
import WarehouseHealthCard from '../components/telemetry/WarehouseHealthCard'
import useTelemetryData from '../components/telemetry/useTelemetryData'

const rangeOptions = [
  { value: '24h', label: 'Last 24h' },
  { value: '7d', label: '7d' },
  { value: '30d', label: '30d' },
]

function average(items) {
  const values = items.map((item) => Number(item.reading)).filter(Number.isFinite)
  return values.length ? values.reduce((total, value) => total + value, 0) / values.length : null
}

function formatNumber(value, digits = 1) {
  return value == null ? '—' : Number(value).toLocaleString(undefined, { minimumFractionDigits: digits, maximumFractionDigits: digits })
}

function buildEnergyStats(sensors, readings, source) {
  if (source !== 'live') return { power: 42.8, energy: 986 }
  const powerSensors = sensors.filter((sensor) => sensor.metric === 'power' && sensor.status !== 'offline' && sensor.reading != null)
  const power = powerSensors.length ? powerSensors.reduce((sum, sensor) => sum + sensor.reading, 0) : null
  const start = new Date()
  start.setHours(0, 0, 0, 0)
  const energyBySensor = new Map()
  readings.filter((reading) => new Date(reading.recorded_at) >= start && Number.isFinite(Number(reading.energy))).forEach((reading) => {
    const values = energyBySensor.get(reading.sensor_id) ?? []
    values.push({ at: new Date(reading.recorded_at), energy: Number(reading.energy) })
    energyBySensor.set(reading.sensor_id, values)
  })
  let energy = 0
  let hasEnergy = false
  energyBySensor.forEach((values) => {
    values.sort((left, right) => left.at - right.at)
    if (values.length > 1 && values[values.length - 1].energy >= values[0].energy) {
      energy += values[values.length - 1].energy - values[0].energy
      hasEnergy = true
    }
  })
  return { power, energy: hasEnergy ? energy : null }
}

function formatAlertTime(value) {
  if (!value) return 'Recently'
  const date = value instanceof Date ? value : new Date(value)
  if (Number.isNaN(date.getTime())) return 'Recently'
  const minutes = Math.max(0, Math.floor((Date.now() - date.getTime()) / 60000))
  return minutes < 1 ? 'Just now' : `${minutes}m ago`
}

export default function TelemetryPage() {
  const context = useOutletContext() ?? {}
  const warehousesFromWorkspace = context.data?.warehouses ?? []
  const [range, setRange] = useState('24h')
  const telemetry = useTelemetryData({ range, warehouses: warehousesFromWorkspace })
  const { sensors, alerts, energyRows, settings, source, loading, error, refresh, saveSettings, setMonitored } = telemetry

  const [metric, setMetric] = useState('temperature')
  const [trendWarehouse, setTrendWarehouse] = useState('all')
  const [tableWarehouse, setTableWarehouse] = useState('all')
  const [tableStatus, setTableStatus] = useState('all')
  const [sensorSearch, setSensorSearch] = useState('')
  const [page, setPage] = useState(1)
  const [showThresholds, setShowThresholds] = useState(false)
  const [selectedSensor, setSelectedSensor] = useState(null)
  const [notificationOpen, setNotificationOpen] = useState(false)
  const [toast, setToast] = useState('')
  const [monitorError, setMonitorError] = useState('')
  const [refreshing, setRefreshing] = useState(false)
  const pageSize = 8

  const warehouses = [...new Set([
    ...sensors.map((sensor) => sensor.warehouse),
    ...warehousesFromWorkspace.map((warehouse) => warehouse.name).filter(Boolean),
  ])].sort((left, right) => left.localeCompare(right))

  const activeSensors = sensors.filter((sensor) => sensor.monitored)
  const onlineSensors = sensors.filter((sensor) => sensor.status !== 'offline')
  const offlineCount = sensors.length - onlineSensors.length
  const warningCount = sensors.filter((sensor) => sensor.status === 'warning').length
  const statusCounts = {
    optimal: sensors.filter((sensor) => sensor.status === 'optimal').length,
    warning: warningCount,
    offline: offlineCount,
  }
  const temperature = average(sensors.filter((sensor) => sensor.metric === 'temperature' && sensor.status !== 'offline'))
  const humidity = average(sensors.filter((sensor) => sensor.metric === 'humidity' && sensor.status !== 'offline'))
  const energy = buildEnergyStats(sensors, energyRows, source)

  const filteredSensors = sensors.filter((sensor) => {
    const query = sensorSearch.trim().toLowerCase()
    const matchesSearch = !query || `${sensor.name} ${sensor.code} ${sensor.warehouse} ${sensor.zone}`.toLowerCase().includes(query)
    const matchesWarehouse = tableWarehouse === 'all' || sensor.warehouse === tableWarehouse
    const matchesStatus = tableStatus === 'all' || sensor.status === tableStatus
    return matchesSearch && matchesWarehouse && matchesStatus
  })
  const pageCount = Math.max(1, Math.ceil(filteredSensors.length / pageSize))
  const pageSensors = filteredSensors.slice((page - 1) * pageSize, page * pageSize)
  const activeAlerts = alerts.filter((alert) => alert.status === 'active' || alert.status === 'acknowledged')

  useEffect(() => {
    if (!toast) return undefined
    const timer = window.setTimeout(() => setToast(''), 3500)
    return () => window.clearTimeout(timer)
  }, [toast])

  async function handleRefresh() {
    setRefreshing(true)
    try {
      await refresh()
      setToast('Telemetry data refreshed.')
    } catch (refreshError) {
      setMonitorError(refreshError instanceof Error ? refreshError.message : 'Unable to refresh telemetry data.')
    } finally {
      setRefreshing(false)
    }
  }

  async function handleMonitorToggle(sensor) {
    setMonitorError('')
    try {
      const persisted = await setMonitored(sensor.id, !sensor.monitored)
      setToast(persisted ? 'Monitoring preference saved.' : 'Monitoring preference updated for this session.')
    } catch (toggleError) {
      setMonitorError(toggleError instanceof Error ? toggleError.message : 'Unable to update sensor monitoring.')
    }
  }

  async function handleSaveSettings(values) {
    await saveSettings(values)
    setToast('Telemetry thresholds saved.')
  }

  function handleSensorSearch(value) {
    setPage(1)
    setSensorSearch(value)
  }

  function handleWarehouseFilter(value) {
    setPage(1)
    setTableWarehouse(value)
  }

  function handleStatusFilter(value) {
    setPage(1)
    setTableStatus(value)
  }

  function showAttention() {
    setTableStatus('warning')
    setPage(1)
    document.getElementById('live-sensors')?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  }

  const monitoredPercent = sensors.length ? Math.round((activeSensors.length / sensors.length) * 100) : 0

  return (
    <main className="min-h-screen bg-[#f8fafc] px-4 pb-8 pt-5 sm:px-6 lg:px-7">
      <div className="mx-auto max-w-[1500px]">
        <header className="mb-5">
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="flex min-w-0 items-start gap-2.5">
              <button aria-label="Open navigation menu" className="mt-1 grid h-8 w-8 shrink-0 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 lg:hidden" onClick={context.openMobileSidebar} type="button"><Menu size={16} /></button>
              <div>
                <div className="flex flex-wrap items-center gap-2">
                  <h1 className="text-xl font-bold tracking-tight text-slate-900 sm:text-2xl">Telemetry &amp; Sensors</h1>
                  <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-[8px] font-semibold ${source === 'live' ? 'bg-teal-50 text-teal-700' : 'bg-slate-100 text-slate-600'}`}>
                    <span className={`h-1.5 w-1.5 rounded-full ${source === 'live' ? 'bg-teal-500' : 'bg-slate-400'}`} />
                    {source === 'live' ? 'LIVE MONITORING' : 'SAMPLE MONITORING'}
                  </span>
                </div>
                <p className="mt-1 max-w-[580px] text-[10px] leading-4 text-slate-500 sm:text-xs">Monitor real-time sensor readings, warehouse conditions, and energy consumption.</p>
              </div>
            </div>

            <div className="flex w-full flex-wrap items-center justify-between gap-2 sm:w-auto sm:justify-end">
              <div aria-label="Telemetry time range" className="flex rounded-md border border-slate-200 bg-white p-0.5" role="group">
                {rangeOptions.map((option) => (
                  <button aria-pressed={range === option.value} className={`rounded px-2.5 py-1.5 text-[9px] font-medium transition ${range === option.value ? 'bg-teal-50 text-teal-700' : 'text-slate-500 hover:text-slate-800'}`} key={option.value} onClick={() => setRange(option.value)} type="button">{option.label}</button>
                ))}
              </div>
              <div className="relative">
                <button aria-expanded={notificationOpen} aria-label={`Notifications, ${activeAlerts.length} active`} className="relative grid h-8 w-8 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 hover:bg-slate-50" onClick={() => setNotificationOpen((open) => !open)} type="button">
                  <Bell size={14} />
                  {activeAlerts.length > 0 && <span className="absolute -right-1 -top-1 grid h-3.5 min-w-3.5 place-items-center rounded-full bg-rose-500 px-0.5 text-[7px] font-bold text-white">{activeAlerts.length}</span>}
                </button>
                {notificationOpen && (
                  <div className="absolute right-0 top-10 z-30 w-[min(320px,calc(100vw-2rem))] overflow-hidden rounded-lg border border-slate-200 bg-white shadow-xl">
                    <div className="flex items-center justify-between border-b border-slate-100 px-3 py-2.5">
                      <p className="text-[10px] font-bold text-slate-800">Sensor notifications</p>
                      <button className="text-[9px] font-semibold text-teal-700" onClick={() => { setNotificationOpen(false); showAttention() }} type="button">View sensors</button>
                    </div>
                    <div className="max-h-64 overflow-auto">
                      {activeAlerts.length ? activeAlerts.slice(0, 5).map((alert) => (
                        <div className="border-b border-slate-50 px-3 py-2.5 last:border-0" key={alert.id}>
                          <div className="flex items-center justify-between gap-2">
                            <p className="truncate text-[9px] font-semibold text-slate-800">{alert.sensorName}</p>
                            <span className="shrink-0 text-[8px] text-slate-400">{formatAlertTime(alert.detectedAt)}</span>
                          </div>
                          <p className="mt-1 text-[9px] leading-4 text-slate-500">{alert.message}</p>
                        </div>
                      )) : <p className="px-3 py-5 text-center text-[9px] text-slate-400">No active sensor alerts.</p>}
                    </div>
                  </div>
                )}
              </div>
              <button className="inline-flex h-8 items-center gap-1.5 rounded-md border border-slate-200 bg-white px-2.5 text-[9px] font-semibold text-slate-700 transition hover:bg-slate-50" onClick={() => setShowThresholds(true)} type="button">
                <Settings2 size={12} /> Configure Thresholds
              </button>
              <button className="inline-flex h-8 items-center gap-1.5 rounded-md bg-teal-600 px-2.5 text-[9px] font-semibold text-white transition hover:bg-teal-700 disabled:opacity-60" disabled={refreshing || loading} onClick={handleRefresh} type="button">
                <RefreshCw className={refreshing || loading ? 'animate-spin' : ''} size={12} /> Refresh
              </button>
            </div>
          </div>
          {error && <p className="mt-3 rounded-md border border-amber-200 bg-amber-50 px-3 py-2 text-[9px] text-amber-800" role="status">{error}</p>}
        </header>

        <section aria-label="Telemetry summary" className="mb-4 grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <article className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
            <div className="flex items-start justify-between">
              <div><p className="text-[9px] font-semibold text-slate-500">Monitored sensors</p><p className="mt-2 text-[22px] font-bold leading-none text-slate-900">{activeSensors.length.toLocaleString()}</p></div>
              <span className="grid h-8 w-8 place-items-center rounded-md bg-teal-50 text-teal-700"><Activity size={15} /></span>
            </div>
            <div className="mt-3 flex items-center justify-between text-[8px] text-slate-500"><span>{sensors.length.toLocaleString()} registered</span><span>{monitoredPercent}% monitored</span></div>
            <div className="mt-1.5 h-1 overflow-hidden rounded-full bg-slate-100"><div className="h-full rounded-full bg-teal-500" style={{ width: `${monitoredPercent}%` }} /></div>
          </article>

          <article className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
            <div className="flex items-start justify-between">
              <div><p className="text-[9px] font-semibold text-slate-500">Sensor connectivity</p><p className="mt-2 text-[22px] font-bold leading-none text-slate-900">{sensors.length ? Math.round((onlineSensors.length / sensors.length) * 100) : 0}%</p></div>
              <span className="grid h-8 w-8 place-items-center rounded-md bg-blue-50 text-blue-700"><Wifi size={15} /></span>
            </div>
            <div className="mt-3 flex items-center justify-between text-[8px]"><span className="text-teal-700">{onlineSensors.length.toLocaleString()} online</span><span className="text-slate-500">{offlineCount} offline</span></div>
            <div className="mt-1.5 h-1 overflow-hidden rounded-full bg-slate-100"><div className="h-full rounded-full bg-blue-500" style={{ width: `${sensors.length ? (onlineSensors.length / sensors.length) * 100 : 0}%` }} /></div>
          </article>

          <article className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
            <div className="flex items-start justify-between">
              <div><p className="text-[9px] font-semibold text-slate-500">Avg. temperature</p><p className="mt-2 text-[22px] font-bold leading-none text-slate-900">{temperature == null ? '—' : `${formatNumber(temperature)}°C`}</p></div>
              <span className="grid h-8 w-8 place-items-center rounded-md bg-orange-50 text-orange-700"><Thermometer size={15} /></span>
            </div>
            <p className="mt-3 text-[8px] text-slate-500">Average humidity <span className="font-semibold text-slate-700">{humidity == null ? '—' : `${formatNumber(humidity)}%`}</span></p>
          </article>

          <article className="rounded-xl border border-slate-200 bg-white p-4 shadow-[0_1px_2px_rgba(15,23,42,0.03)]">
            <div className="flex items-start justify-between">
              <div><p className="text-[9px] font-semibold text-slate-500">Total energy draw</p><p className="mt-2 text-[22px] font-bold leading-none text-slate-900">{energy.power == null ? '—' : <>{formatNumber(energy.power)}<span className="ml-1 text-[11px] font-semibold">kW</span></>}</p></div>
              <span className="grid h-8 w-8 place-items-center rounded-md bg-violet-50 text-violet-700"><Zap size={15} /></span>
            </div>
            <p className="mt-3 text-[8px] text-slate-500">Energy consumed today <span className="font-semibold text-slate-700">{energy.energy == null ? '—' : `${formatNumber(energy.energy, 0)} kWh`}</span></p>
          </article>
        </section>

        <section aria-label="Sensor analytics" className="mb-4 grid grid-cols-1 gap-4 xl:grid-cols-[minmax(0,1.8fr)_minmax(270px,0.85fr)]">
          <TelemetryTrendCard
            metric={metric}
            onMetricChange={setMetric}
            onWarehouseChange={setTrendWarehouse}
            range={range}
            sensors={sensors}
            warehouse={trendWarehouse}
            warehouses={warehouses}
          />
          <WarehouseHealthCard onShowAttention={showAttention} sensors={sensors} />
        </section>

        {monitorError && <p className="mb-3 rounded-md border border-rose-200 bg-rose-50 px-3 py-2 text-[9px] text-rose-700" role="alert">{monitorError}</p>}

        <div id="live-sensors">
          <TelemetrySensorTable
            onInspect={setSelectedSensor}
            onPageChange={setPage}
            onSearchChange={handleSensorSearch}
            onStatusChange={handleStatusFilter}
            onToggleMonitor={handleMonitorToggle}
            onWarehouseChange={handleWarehouseFilter}
            page={page}
            pageCount={pageCount}
            pageSize={pageSize}
            search={sensorSearch}
            sensors={pageSensors}
            status={tableStatus}
            statusCounts={statusCounts}
            totalItems={filteredSensors.length}
            warehouse={tableWarehouse}
            warehouses={warehouses}
          />
        </div>

        <footer className="mt-4 flex flex-wrap items-center justify-between gap-2 text-[8px] text-slate-400">
          <span className="inline-flex items-center gap-1.5"><Clock3 size={11} /> Sensor data refreshes every 30 seconds</span>
          <span className="inline-flex items-center gap-1.5"><CircleHelp size={11} /> Thresholds and monitoring settings</span>
        </footer>
      </div>

      {showThresholds && <ThresholdSettingsModal onClose={() => setShowThresholds(false)} onSave={handleSaveSettings} settings={settings} />}
      {selectedSensor && <SensorDetailsDrawer onClose={() => setSelectedSensor(null)} sensor={selectedSensor} />}
      {toast && (
        <div className="fixed bottom-5 right-5 z-[100] flex items-center gap-2 rounded-lg bg-slate-900 px-4 py-3 text-[10px] font-medium text-white shadow-xl" role="status">
          <Check className="text-teal-300" size={14} /> {toast}
        </div>
      )}
    </main>
  )
}
