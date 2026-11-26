import { useCallback, useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from '../../lib/supabase'

const defaultSettings = {
  voltage_warning_threshold: 250,
  current_warning_threshold: 10,
  offline_timeout_minutes: 5,
  realtime_enabled: true,
}

const seedLocations = [
  { name: 'Shah Alam', count: 48, optimal: 46, warning: 0, offline: 2, zone: 'Zone A · Cold storage' },
  { name: 'Klang', count: 32, optimal: 30, warning: 1, offline: 1, zone: 'Zone B · Loading dock' },
  { name: 'Johor Bahru', count: 28, optimal: 26, warning: 1, offline: 1, zone: 'Zone A · General storage' },
  { name: 'Penang', count: 20, optimal: 17, warning: 1, offline: 2, zone: 'Zone C · Freezer room' },
]

const seedAlerts = [
  {
    id: 'seed-alert-loading-dock',
    sensorName: 'Loading dock B2',
    message: 'Temperature is above its optimal range.',
    severity: 'warning',
    detectedAt: new Date(Date.now() - 8 * 60 * 1000),
    status: 'active',
  },
  {
    id: 'seed-alert-freezer',
    sensorName: 'Freezer unit C4',
    message: 'No heartbeat received within the offline timeout.',
    severity: 'critical',
    detectedAt: new Date(Date.now() - 14 * 60 * 1000),
    status: 'active',
  },
]

function makeSeries(value, metric, offset) {
  return Array.from({ length: 24 }, (_, index) => {
    const variance = Math.sin((index + offset) * 0.85) * (metric === 'power' ? 1.8 : 0.7)
    return Number(Math.max(0, value + variance).toFixed(1))
  })
}

function makeSeedSensor(id, name, code, location, metric, reading, status, lastSeenMinutes) {
  const units = { temperature: '°C', humidity: '%', power: 'kW', voltage: 'V' }
  const defaults = { temperature: '18–26 °C', humidity: '35–65 %', power: '0–60 kW', voltage: '220–250 V' }
  return {
    id: `seed-sensor-${id}`,
    code,
    name,
    warehouse: location.name,
    zone: location.zone,
    metric,
    reading,
    unit: units[metric],
    threshold: defaults[metric],
    status,
    lastSeen: new Date(Date.now() - lastSeenMinutes * 60 * 1000),
    monitored: true,
    monitorField: null,
    trend: makeSeries(reading, metric, id),
  }
}

function createSeedSensors() {
  const byName = new Map(seedLocations.map((location) => [location.name, location]))
  const rows = [
    makeSeedSensor(1, 'Cold storage A1', 'SNS-T001', byName.get('Shah Alam'), 'temperature', 22.4, 'optimal', 0.2),
    makeSeedSensor(2, 'Loading dock B2', 'SNS-T014', byName.get('Klang'), 'temperature', 27.8, 'warning', 0.13),
    makeSeedSensor(3, 'Storage humidity', 'SNS-H008', byName.get('Johor Bahru'), 'humidity', 48, 'optimal', 0.3),
    makeSeedSensor(4, 'Main power meter', 'SNS-P003', byName.get('Shah Alam'), 'power', 42.8, 'optimal', 0.08),
    makeSeedSensor(5, 'Freezer unit C4', 'SNS-T022', byName.get('Penang'), 'temperature', -6, 'offline', 14),
    makeSeedSensor(6, 'Voltage monitor', 'SNS-V006', byName.get('Klang'), 'voltage', 231.6, 'optimal', 0.35),
  ]
  let nextId = rows.length + 1

  for (const location of seedLocations) {
    const currentRows = rows.filter((row) => row.warehouse === location.name)
    const remaining = {
      optimal: location.optimal - currentRows.filter((row) => row.status === 'optimal').length,
      warning: location.warning - currentRows.filter((row) => row.status === 'warning').length,
      offline: location.offline - currentRows.filter((row) => row.status === 'offline').length,
    }
    const metricCycle = ['temperature', 'humidity', 'power', 'voltage']
    for (const status of ['optimal', 'warning', 'offline']) {
      for (let count = 0; count < remaining[status]; count += 1) {
        const metric = metricCycle[(nextId - 1) % metricCycle.length]
        const values = { temperature: 22.4, humidity: 48, power: 12.6, voltage: 231.6 }
        const value = status === 'warning' && metric === 'temperature' ? 27.8 : values[metric]
        rows.push(makeSeedSensor(
          nextId,
          `${metric === 'power' ? 'Power meter' : metric === 'voltage' ? 'Voltage monitor' : metric === 'humidity' ? 'Storage humidity' : 'Temperature sensor'} ${String(nextId).padStart(2, '0')}`,
          `SNS-${String(nextId).padStart(3, '0')}`,
          location,
          metric,
          value,
          status,
          status === 'offline' ? 14 + (nextId % 9) : status === 'warning' ? 4 : 0.2 + (nextId % 18) / 10,
        ))
        nextId += 1
      }
    }
  }
  return rows
}

const fallbackSensors = createSeedSensors()

function parseNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  const parsed = Number.parseFloat(String(value ?? '').replace(',', '.'))
  return Number.isFinite(parsed) ? parsed : null
}

function parseMeasurement(text, symbol) {
  const match = String(text ?? '').match(new RegExp(`(?:^|[,;\\s])${symbol}\\s*:\\s*(-?\\d+(?:\\.\\d+)?)`, 'i'))
  return match ? parseNumber(match[1]) : null
}

function metricFor(sensor) {
  const description = `${sensor.sensor_type ?? ''} ${sensor.sensor_name ?? ''} ${sensor.sensor_code ?? ''}`.toLowerCase()
  if (description.includes('humidity')) return 'humidity'
  if (description.includes('temperature') || description.includes('temp')) return 'temperature'
  if (description.includes('voltage')) return 'voltage'
  if (description.includes('power') || description.includes('energy') || description.includes('dds669')) return 'power'
  return 'reading'
}

function locationFor(sensor, warehouses) {
  const id = sensor.warehouse_location_id ?? sensor.location_id
  const location = warehouses.find((row) => row.id === id)
  const explicitName = sensor.warehouse_name ?? sensor.location_name
  const warehouse = typeof explicitName === 'string' && explicitName.trim()
    ? explicitName.trim()
    : location?.name || 'Sensor network'
  const zone = sensor.zone_name ?? sensor.zone ?? sensor.area ?? 'Sensor zone'
  return { warehouse, zone: String(zone) }
}

function statusFor(metric, reading, lastSeen, timeoutMinutes, activeAlert) {
  if (activeAlert?.alert_type === 'sensor_offline') return 'offline'
  if (activeAlert) return 'warning'
  const ageMinutes = lastSeen ? Math.max(0, (Date.now() - lastSeen.getTime()) / 60000) : Infinity
  if (ageMinutes > timeoutMinutes) return 'offline'
  if (ageMinutes > 2) return 'warning'
  if (reading == null) return 'warning'
  if (metric === 'temperature' && (reading < 18 || reading > 26)) return 'warning'
  if (metric === 'humidity' && (reading < 35 || reading > 65)) return 'warning'
  if (metric === 'voltage' && reading > 250) return 'warning'
  return 'optimal'
}

function mapLiveSensors(rows, energyRows, alertRows, settings, warehouses, overrides) {
  const energyBySensor = new Map()
  for (const row of energyRows) {
    const values = energyBySensor.get(row.sensor_id) ?? []
    values.push(row)
    energyBySensor.set(row.sensor_id, values)
  }
  const alertBySensor = new Map()
  for (const row of alertRows.filter((alert) => alert.status === 'active')) {
    if (!alertBySensor.has(row.sensor_id)) alertBySensor.set(row.sensor_id, row)
  }

  return rows.map((row) => {
    const sensor = Array.isArray(row.sensors) ? row.sensors[0] : row.sensors ?? {}
    const id = row.sensor_id
    const metric = metricFor(sensor)
    const readings = energyBySensor.get(id) ?? []
    const latestEnergy = readings[readings.length - 1]
    const text = row.value_text ?? ''
    const numeric = parseNumber(row.value_numeric) ?? parseNumber(text)
    const reading = metric === 'voltage'
      ? parseMeasurement(text, 'V') ?? parseNumber(latestEnergy?.voltage) ?? numeric
      : metric === 'power'
        ? parseNumber(latestEnergy?.power) ?? numeric
        : numeric
    const unit = { temperature: '°C', humidity: '%', power: 'kW', voltage: 'V' }[metric] ?? ''
    const threshold = {
      temperature: '18–26 °C',
      humidity: '35–65 %',
      power: '0–60 kW',
      voltage: `≤ ${settings.voltage_warning_threshold} V`,
    }[metric] ?? 'Configured range'
    const lastSeen = row.last_seen ? new Date(row.last_seen) : null
    const location = locationFor(sensor, warehouses)
    const alert = alertBySensor.get(id)
    const monitorField = typeof sensor.is_monitored === 'boolean'
      ? 'is_monitored'
      : typeof sensor.monitoring_enabled === 'boolean'
        ? 'monitoring_enabled'
        : null
    let trend = readings.map((item) => metric === 'voltage'
      ? parseNumber(item.voltage)
      : parseNumber(item.power)).filter((value) => value != null)

    return {
      id,
      code: String(sensor.sensor_code ?? id),
      name: String(sensor.sensor_name ?? sensor.sensor_code ?? 'Sensor'),
      warehouse: location.warehouse,
      zone: location.zone,
      metric,
      reading,
      unit,
      threshold,
      status: statusFor(metric, reading, lastSeen, settings.offline_timeout_minutes, alert),
      lastSeen,
      monitored: overrides[id] ?? (monitorField ? sensor[monitorField] : true),
      monitorField,
      trend,
      rawSensorId: sensor.id ?? id,
    }
  })
}

async function queryRows(name, queryFactory, issues) {
  try {
    const { data, error } = await queryFactory()
    if (error) {
      issues.push(`${name}: ${error.message}`)
      return null
    }
    return data ?? []
  } catch (error) {
    issues.push(`${name}: ${error instanceof Error ? error.message : String(error)}`)
    return null
  }
}

function mapAlerts(rows) {
  return rows.map((row) => {
    const sensor = Array.isArray(row.sensors) ? row.sensors[0] : row.sensors
    return {
      id: row.id,
      sensorId: row.sensor_id,
      sensorName: sensor?.sensor_name || 'Telemetry sensor',
      message: row.message || row.alert_type?.replaceAll('_', ' ') || 'Sensor alert',
      severity: row.severity || 'warning',
      status: row.status || 'active',
      detectedAt: new Date(row.detected_at),
    }
  })
}

export default function useTelemetryData({ range, warehouses = [] }) {
  const [sensors, setSensors] = useState(fallbackSensors)
  const [alerts, setAlerts] = useState(seedAlerts)
  const [energyRows, setEnergyRows] = useState([])
  const [settings, setSettings] = useState(defaultSettings)
  const [monitorOverrides, setMonitorOverrides] = useState({})
  const [source, setSource] = useState('sample')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const refresh = useCallback(async () => {
    if (!supabase || !isSupabaseConfigured) {
      setSensors(fallbackSensors.map((sensor) => ({ ...sensor, monitored: monitorOverrides[sensor.id] ?? true })))
      setAlerts(seedAlerts)
      setEnergyRows([])
      setSettings(defaultSettings)
      setSource('sample')
      setLoading(false)
      setError('')
      return
    }

    setLoading(true)
    const issues = []
    const since = new Date(Date.now() - (range === '30d' ? 30 : range === '7d' ? 7 : 1) * 24 * 60 * 60 * 1000).toISOString()
    const [statusRows, readings, alertRows, settingsRows] = await Promise.all([
      queryRows(
        'Sensor status',
        () => supabase.from('sensor_status')
          .select('sensor_id,value_numeric,value_text,last_seen,sensors(*)')
          .order('last_seen', { ascending: false }),
        issues,
      ),
      queryRows(
        'Energy readings',
        () => supabase.from('energy_readings')
          .select('sensor_id,voltage,current,power,energy,recorded_at')
          .gte('recorded_at', since)
          .order('recorded_at', { ascending: true })
          .limit(2000),
        issues,
      ),
      queryRows(
        'Sensor alerts',
        () => supabase.from('sensor_alerts')
          .select('id,sensor_id,alert_type,severity,status,message,detected_at,resolved_at,sensors(sensor_name)')
          .order('detected_at', { ascending: false })
          .limit(500),
        issues,
      ),
      queryRows(
        'Telemetry settings',
        async () => {
          const { data, error: queryError } = await supabase.from('telemetry_settings')
            .select('id,voltage_warning_threshold,current_warning_threshold,offline_timeout_minutes,realtime_enabled')
            .eq('id', 'default')
            .maybeSingle()
          return { data: data ? [data] : [], error: queryError }
        },
        issues,
      ),
    ])

    const nextSettings = { ...defaultSettings, ...(settingsRows?.[0] ?? {}) }
    const mappedAlerts = alertRows?.length ? mapAlerts(alertRows) : seedAlerts
    const mappedSensors = statusRows?.length
      ? mapLiveSensors(statusRows, readings ?? [], alertRows ?? [], nextSettings, warehouses, monitorOverrides)
      : fallbackSensors.map((sensor) => ({ ...sensor, monitored: monitorOverrides[sensor.id] ?? true }))

    setSettings(nextSettings)
    setAlerts(mappedAlerts)
    setEnergyRows(readings ?? [])
    setSensors(mappedSensors)
    setSource(statusRows?.length ? 'live' : 'sample')
    setError(issues.length ? `Some telemetry sources are unavailable; available readings are shown. ${issues[0]}` : '')
    setLoading(false)
  }, [monitorOverrides, range, warehouses])

  useEffect(() => {
    let active = true
    void Promise.resolve().then(() => (active ? refresh() : undefined)).catch((refreshError) => {
      if (!active) return
      setSensors(fallbackSensors)
      setAlerts(seedAlerts)
      setSource('sample')
      setError(`Live telemetry could not be loaded. Showing sample readings. ${refreshError instanceof Error ? refreshError.message : String(refreshError)}`)
      setLoading(false)
    })
    return () => {
      active = false
    }
  }, [refresh])

  useEffect(() => {
    if (!supabase || !isSupabaseConfigured || !settings.realtime_enabled) return undefined
    const channel = supabase
      .channel('invwise-telemetry-page')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sensor_status' }, refresh)
      .subscribe()
    const intervalId = window.setInterval(refresh, 30000)
    return () => {
      window.clearInterval(intervalId)
      supabase.removeChannel(channel)
    }
  }, [refresh, settings.realtime_enabled])

  const saveSettings = useCallback(async (values) => {
    const next = {
      voltage_warning_threshold: Number(values.voltage_warning_threshold),
      current_warning_threshold: Number(values.current_warning_threshold),
      offline_timeout_minutes: Number(values.offline_timeout_minutes),
      realtime_enabled: Boolean(values.realtime_enabled),
    }
    if (
      !Number.isFinite(next.voltage_warning_threshold) || next.voltage_warning_threshold <= 0 ||
      !Number.isFinite(next.current_warning_threshold) || next.current_warning_threshold <= 0 ||
      !Number.isInteger(next.offline_timeout_minutes) || next.offline_timeout_minutes < 2 || next.offline_timeout_minutes > 60
    ) {
      throw new Error('Enter positive voltage/current thresholds and an offline timeout between 2 and 60 minutes.')
    }

    const previous = settings
    setSettings(next)
    if (supabase && isSupabaseConfigured) {
      const { error: saveError } = await supabase.from('telemetry_settings').upsert({ id: 'default', ...next })
      if (saveError) {
        setSettings(previous)
        throw new Error(saveError.message)
      }
    }
  }, [settings])

  const setMonitored = useCallback(async (sensorId, monitored) => {
    const sensor = sensors.find((row) => row.id === sensorId)
    if (!sensor) throw new Error('This sensor is no longer available.')
    const previous = sensor.monitored
    setMonitorOverrides((current) => ({ ...current, [sensorId]: monitored }))
    setSensors((current) => current.map((row) => row.id === sensorId ? { ...row, monitored } : row))

    if (sensor.monitorField && supabase && isSupabaseConfigured) {
      const { error: updateError } = await supabase.from('sensors')
        .update({ [sensor.monitorField]: monitored })
        .eq('id', sensor.rawSensorId)
      if (updateError) {
        setMonitorOverrides((current) => ({ ...current, [sensorId]: previous }))
        setSensors((current) => current.map((row) => row.id === sensorId ? { ...row, monitored: previous } : row))
        throw new Error(updateError.message)
      }
      return true
    }
    return false
  }, [sensors])

  return { sensors, alerts, energyRows, settings, source, loading, error, refresh, saveSettings, setMonitored }
}
