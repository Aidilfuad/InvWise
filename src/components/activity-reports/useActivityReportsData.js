import { useCallback, useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from '../../lib/supabase'

const eventTemplates = [
  {
    category: 'Stock Movements',
    event: 'Stock received',
    description: 'Nitrile Gloves · M',
    detail: 'SKU-PPE-018 · PO-2026-0842',
    actor: 'Alex Morgan',
    role: 'Warehouse admin',
    warehouse: 'Main warehouse',
    location: 'A-02 · Bin 04',
    badge: 'Stock In',
    value: '+50 units',
    reference: 'PO-2026-0842',
  },
  {
    category: 'Inventory',
    event: 'Item details updated',
    description: 'Safety Helmet · White',
    detail: 'SKU-PPE-002 · Unit price changed from $17.50 to $18.00',
    actor: 'Priya Shah',
    role: 'Inventory manager',
    warehouse: 'Main warehouse',
    location: 'Catalog update',
    badge: 'Updated',
    value: '',
    reference: 'SKU-PPE-002',
  },
  {
    category: 'Telemetry',
    event: 'Temperature threshold exceeded',
    description: 'Cold Room T-04',
    detail: '9.2°C detected · Limit: 8.0°C',
    actor: 'InvWise System',
    role: 'Automated rule',
    warehouse: 'East warehouse',
    location: 'Cold storage · Zone B',
    badge: 'Sensor event',
    value: '',
    reference: 'T-04',
  },
  {
    category: 'Stock Movements',
    event: 'Stock dispatched',
    description: 'Packing Tape · 48mm',
    detail: 'SKU-PKG-041 · SO-2026-0618',
    actor: 'Jordan Lee',
    role: 'Warehouse operator',
    warehouse: 'East warehouse',
    location: 'B-03 · Bin 08',
    badge: 'Stock Out',
    value: '−24 units',
    reference: 'SO-2026-0618',
  },
  {
    category: 'User/System',
    event: 'Team member invited',
    description: 'olivia.chen@acme.com',
    detail: 'Role: Warehouse operator',
    actor: 'Alex Morgan',
    role: 'Workspace admin',
    warehouse: 'All warehouses',
    location: 'Workspace access',
    badge: 'User invited',
    value: '',
    reference: 'USR-2026-0118',
  },
  {
    category: 'Stock Movements',
    event: 'Stock transferred',
    description: 'Steel Hex Bolt · M10',
    detail: 'SKU-HDW-103 · TR-2026-0114',
    actor: 'Priya Shah',
    role: 'Inventory manager',
    warehouse: 'Main → West warehouse',
    location: 'C-04 · Bin 02',
    badge: 'Transfer',
    value: '120 units',
    reference: 'TR-2026-0114',
  },
]

const activityTargets = {
  Inventory: 64,
  'Stock Movements': 86,
  Telemetry: 56,
  'User/System': 42,
}

function createSeedActivities() {
  const counts = Object.fromEntries(Object.keys(activityTargets).map((category) => [category, 0]))
  const now = Date.now()
  return Array.from({ length: 248 }, (_, index) => {
    let category
    if (index < eventTemplates.length) {
      category = eventTemplates[index].category
    } else {
      category = Object.keys(activityTargets)
        .filter((name) => counts[name] < activityTargets[name])
        .sort((left, right) => counts[left] / activityTargets[left] - counts[right] / activityTargets[right])[0]
    }

    counts[category] += 1
    const categoryTemplates = eventTemplates.filter((template) => template.category === category)
    const template = index < eventTemplates.length
      ? eventTemplates[index]
      : categoryTemplates[(counts[category] - 1) % categoryTemplates.length]
    const occurredAt = new Date(now - index * 60 * 1000)
    return {
      ...template,
      id: `sample-event-${index + 1}`,
      reference: index < eventTemplates.length ? template.reference : `${template.reference}-${String(index + 1).padStart(4, '0')}`,
      occurredAt,
      sourceTable: 'sample',
    }
  })
}

const alertTemplates = [
  ['critical', 'Cold room temperature too high', 'T-04 · 9.2°C detected · Threshold 8.0°C', 'East warehouse', 'Cold storage · Zone B', 'Telemetry'],
  ['critical', 'Stretch Wrap - 500mm is out of stock', 'SKU-PKG-026 · 0 units · Minimum stock: 30', 'Main warehouse', 'A-02 · Bin 04', 'Inventory'],
  ['critical', 'Warehouse gateway is offline', 'GW-W03 · No heartbeat for 15 minutes', 'West warehouse', 'Loading dock · Zone A', 'Telemetry'],
  ['warning', 'Nitrile Gloves - M below minimum', 'SKU-PPE-018 · 24 units · Minimum stock: 50', 'Main warehouse', 'A-02 · Bin 04', 'Inventory'],
  ['warning', 'Sensor battery is running low', 'TH-012 · 12% battery remaining', 'East warehouse', 'Cold storage · Zone B', 'Telemetry'],
  ['info', 'New firmware update available', 'GW-M01 · Version 2.8.1 is ready to install', 'Main warehouse', 'Gateway · Zone A', 'Telemetry'],
]

function createSeedAlerts() {
  const now = Date.now()
  const activeSeverities = [
    'critical', 'critical', 'critical',
    'warning', 'warning', 'warning', 'warning', 'warning', 'warning', 'warning',
    'info', 'info',
  ]
  return Array.from({ length: 16 }, (_, index) => {
    const template = alertTemplates[index % alertTemplates.length]
    const status = index < 12 ? 'active' : 'acknowledged'
    const severity = index < 12 ? activeSeverities[index] : 'warning'
    return {
      id: `sample-alert-${index + 1}`,
      severity,
      title: template[1],
      detail: template[2],
      warehouse: template[3],
      location: template[4],
      type: template[5],
      status,
      detectedAt: new Date(now - index * 7 * 60 * 1000),
      sourceTable: 'sample',
    }
  })
}

const seedActivities = createSeedActivities()
const seedAlerts = createSeedAlerts()

function categoryForLog(row) {
  const value = `${row.category ?? ''} ${row.action ?? ''} ${row.entity_type ?? ''}`.toLowerCase()
  if (value.includes('telemetry') || value.includes('sensor')) return 'Telemetry'
  if (value.includes('user') || value.includes('system') || value.includes('security') || value.includes('workspace')) return 'User/System'
  if (value.includes('movement') || value.includes('receipt') || value.includes('issue') || value.includes('transfer') || value.includes('stock')) {
    return 'Stock Movements'
  }
  return 'Inventory'
}

function friendlyMovement(type) {
  const labels = {
    receipt: 'Stock received',
    issue: 'Stock dispatched',
    adjustment: 'Stock adjusted',
    transfer: 'Stock transferred',
    return: 'Stock returned',
  }
  return labels[String(type ?? '').toLowerCase()] ?? 'Stock movement'
}

async function readRows(queryFactory, name, issues) {
  try {
    const { data, error } = await queryFactory()
    if (error) {
      issues.push(`${name}: ${error.message}`)
      return []
    }
    return data ?? []
  } catch (error) {
    issues.push(`${name}: ${error instanceof Error ? error.message : String(error)}`)
    return []
  }
}

function createLocationLabel(sourceId, destinationId, warehouses, metadata = {}) {
  const locationName = (id) => warehouses.find((row) => row.id === id)?.name
  const source = metadata.source_location_name || locationName(sourceId)
  const destination = metadata.destination_location_name || locationName(destinationId)
  if (source && destination && sourceId !== destinationId) return `${source} → ${destination}`
  return metadata.location_name || locationName(destinationId || sourceId) || 'All warehouses'
}

function mapActivityRows(rows, itemsById, warehouses, profilesByAuthId) {
  return rows.map((row) => {
    const metadata = row.metadata && typeof row.metadata === 'object' ? row.metadata : {}
    const item = itemsById.get(metadata.item_id || row.entity_id)
    const category = categoryForLog(row)
    const sourceId = metadata.source_location_id
    const destinationId = metadata.destination_location_id
    const actorProfile = profilesByAuthId.get(row.actor_user_id)
    return {
      id: row.id,
      category,
      event: row.action || row.description || 'Workspace activity',
      description: row.description || '',
      detail: [
        item?.name,
        metadata.sku || item?.sku,
        metadata.reference || metadata.stock_movement_id,
        metadata.quantity != null ? `${metadata.quantity} units` : '',
      ].filter(Boolean).join(' · ') || row.entity_type || '',
      actor: row.actor_name || actorProfile?.full_name || 'InvWise System',
      role: actorProfile?.role || (row.actor_user_id ? 'Workspace member' : 'Automated rule'),
      warehouse: createLocationLabel(sourceId || metadata.location_id, destinationId || metadata.location_id, warehouses, metadata),
      location: metadata.bin_location || metadata.zone_name || metadata.location_name || '',
      reference: metadata.reference || metadata.stock_movement_id || row.entity_id || '',
      occurredAt: new Date(row.occurred_at),
      sourceTable: 'activity_logs',
    }
  })
}

function mapMovementRows(rows, itemsById, warehouses, profilesById) {
  return rows.map((row) => {
    const item = itemsById.get(row.item_id)
    const from = row.source_location_id
    const to = row.destination_location_id
    const actor = profilesById.get(row.performed_by)
    return {
      id: `movement-${row.id}`,
      category: 'Stock Movements',
      event: friendlyMovement(row.movement_type),
      description: item?.name || 'Inventory item',
      detail: [item?.sku, row.reference || row.notes].filter(Boolean).join(' · '),
      actor: actor?.full_name || 'InvWise System',
      role: actor?.role || (row.performed_by ? 'Workspace member' : 'Automated rule'),
      warehouse: createLocationLabel(from, to, warehouses),
      location: '',
      reference: row.reference || row.id,
      occurredAt: new Date(row.occurred_at),
      sourceTable: 'stock_movements',
    }
  })
}

function mapSensorAlert(row) {
  const sensor = Array.isArray(row.sensors) ? row.sensors[0] : row.sensors
  return {
    id: row.id,
    title: row.message || row.alert_type?.replaceAll('_', ' ') || 'Sensor alert',
    detail: sensor?.sensor_name ? `${sensor.sensor_name} · ${row.message || row.alert_type}` : row.message || row.alert_type,
    warehouse: 'Sensor network',
    location: sensor?.sensor_name || '',
    severity: row.severity || 'warning',
    status: row.status || 'active',
    type: 'Telemetry',
    detectedAt: new Date(row.detected_at),
    resolvedAt: row.resolved_at ? new Date(row.resolved_at) : null,
    sourceTable: 'sensor_alerts',
  }
}

function mapInventoryAlert(row, itemsById, warehouses) {
  const itemId = row.item_id || row.inventory_item_id
  const item = itemsById.get(itemId)
  const locationId = row.location_id || row.warehouse_location_id
  const quantity = Number(row.quantity ?? row.current_quantity ?? item?.quantity ?? 0)
  const outOfStock = quantity <= 0
  const type = String(row.alert_type || row.type || (outOfStock ? 'out_of_stock' : 'low_stock'))
  return {
    id: row.id || `${itemId || 'item'}-${locationId || 'location'}-${type}`,
    title: row.message || `${item?.name || 'Inventory item'} ${outOfStock ? 'is out of stock' : 'below minimum'}`,
    detail: [item?.sku, `${quantity} units`, row.minimum_stock != null ? `Minimum stock: ${row.minimum_stock}` : 'Replenishment required'].filter(Boolean).join(' · '),
    warehouse: warehouses.find((warehouse) => warehouse.id === locationId)?.name || 'All warehouses',
    location: row.bin_location || row.zone_name || '',
    severity: outOfStock ? 'critical' : 'warning',
    status: row.status || 'active',
    type: 'Inventory',
    detectedAt: new Date(row.detected_at || row.created_at || Date.now()),
    sourceTable: 'inventory_alerts',
    itemId,
  }
}

export default function useActivityReportsData({ items = [], warehouses = [] }) {
  const [activities, setActivities] = useState(seedActivities)
  const [alerts, setAlerts] = useState(seedAlerts)
  const [movements, setMovements] = useState([])
  const [source, setSource] = useState('sample')
  const [loading, setLoading] = useState(Boolean(supabase && isSupabaseConfigured))
  const [error, setError] = useState('')
  const [rules, setRules] = useState({
    voltage_warning_threshold: 250,
    current_warning_threshold: 10,
    offline_timeout_minutes: 5,
    realtime_enabled: true,
  })

  const refresh = useCallback(async () => {
    if (!supabase || !isSupabaseConfigured) {
      setActivities(seedActivities)
      setAlerts(seedAlerts)
      setMovements([])
      setSource('sample')
      setLoading(false)
      setError('')
      return
    }

    setLoading(true)
    const issues = []
    const [activityRows, movementRows, sensorRows, inventoryAlertRows, settingsRows] = await Promise.all([
      readRows(
        () => supabase.from('activity_logs')
          .select('id,occurred_at,actor_user_id,actor_name,category,action,description,entity_type,entity_id,metadata')
          .order('occurred_at', { ascending: false })
          .limit(500),
        'activity log',
        issues,
      ),
      readRows(
        () => supabase.from('stock_movements')
          .select('id,item_id,movement_type,quantity,source_location_id,destination_location_id,reference,notes,performed_by,occurred_at')
          .order('occurred_at', { ascending: false })
          .limit(500),
        'stock movements',
        issues,
      ),
      readRows(
        () => supabase.from('sensor_alerts')
          .select('id,sensor_id,alert_type,severity,status,message,detected_at,resolved_at,sensors(sensor_name)')
          .order('detected_at', { ascending: false })
          .limit(500),
        'sensor alerts',
        issues,
      ),
      readRows(
        () => supabase.from('inventory_alerts').select('*').limit(500),
        'inventory alerts',
        issues,
      ),
      readRows(
        () => supabase.from('telemetry_settings')
          .select('voltage_warning_threshold,current_warning_threshold,offline_timeout_minutes,realtime_enabled')
          .eq('id', 'default')
          .maybeSingle()
          .then(({ data, error: queryError }) => ({ data: data ? [data] : [], error: queryError })),
        'telemetry settings',
        issues,
      ),
    ])

    const authIds = [...new Set(activityRows.map((row) => row.actor_user_id).filter(Boolean))]
    const profileIds = [...new Set(movementRows.map((row) => row.performed_by).filter(Boolean))]
    const [actorProfiles, movementProfiles] = await Promise.all([
      authIds.length
        ? readRows(() => supabase.from('profiles').select('auth_user_id,full_name,role').in('auth_user_id', authIds), 'activity actors', issues)
        : Promise.resolve([]),
      profileIds.length
        ? readRows(() => supabase.from('profiles').select('id,full_name,role').in('id', profileIds), 'movement actors', issues)
        : Promise.resolve([]),
    ])

    const itemsById = new Map(items.map((item) => [item.id, item]))
    const profilesByAuthId = new Map(actorProfiles.map((profile) => [profile.auth_user_id, profile]))
    const profilesById = new Map(movementProfiles.map((profile) => [profile.id, profile]))
    const mappedActivities = mapActivityRows(activityRows, itemsById, warehouses, profilesByAuthId)
    const movementEvents = mapMovementRows(movementRows, itemsById, warehouses, profilesById)
    const activityMovementIds = new Set(activityRows
      .filter((row) => row.entity_type === 'inventory_movement')
      .map((row) => row.entity_id))
    const combinedActivities = [
      ...mappedActivities,
      ...movementEvents.filter((row) => !activityMovementIds.has(row.reference)),
    ].sort((left, right) => right.occurredAt.getTime() - left.occurredAt.getTime())

    const mappedAlerts = [
      ...sensorRows.map(mapSensorAlert),
      ...inventoryAlertRows.map((row) => mapInventoryAlert(row, itemsById, warehouses)),
    ].sort((left, right) => right.detectedAt.getTime() - left.detectedAt.getTime())

    const telemetrySettings = settingsRows[0]
    if (telemetrySettings) setRules({
      voltage_warning_threshold: Number(telemetrySettings.voltage_warning_threshold) || 250,
      current_warning_threshold: Number(telemetrySettings.current_warning_threshold) || 10,
      offline_timeout_minutes: Number(telemetrySettings.offline_timeout_minutes) || 5,
      realtime_enabled: telemetrySettings.realtime_enabled !== false,
    })

    const hasLiveRows = combinedActivities.length > 0 || mappedAlerts.length > 0
    setActivities(hasLiveRows ? combinedActivities : seedActivities)
    setAlerts(mappedAlerts.length > 0 ? mappedAlerts : seedAlerts)
    setMovements(movementEvents)
    setSource(hasLiveRows ? 'live' : 'sample')
    setError(issues.length > 0
      ? `Some live sources are unavailable; available records are shown. ${issues[0]}`
      : '')
    setLoading(false)
  }, [items, warehouses])

  useEffect(() => {
    let active = true
    void Promise.resolve().then(() => (active ? refresh() : undefined)).catch((error) => {
      if (!active) return
      setActivities(seedActivities)
      setAlerts(seedAlerts)
      setMovements([])
      setSource('sample')
      const message = error instanceof Error ? error.message : 'Unexpected data loading error.'
      setError(`Live activity could not be loaded. Showing sample records. ${message}`)
      setLoading(false)
    })
    return () => {
      active = false
    }
  }, [refresh])

  useEffect(() => {
    if (!supabase || !isSupabaseConfigured) return undefined
    const channel = supabase
      .channel('invwise-activity-reports')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'activity_logs' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'stock_movements' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sensor_alerts' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'stock_levels' }, refresh)
      .subscribe()
    return () => {
      supabase.removeChannel(channel)
    }
  }, [refresh])

  const updateAlert = useCallback(async (alertId, status) => {
    const alert = alerts.find((row) => row.id === alertId)
    if (!alert) throw new Error('This alert is no longer available.')
    if (!['acknowledged', 'resolved'].includes(status)) throw new Error('Choose a valid alert status.')
    if (alert.sourceTable === 'inventory_alerts') {
      throw new Error('Inventory alerts clear automatically when stock is replenished.')
    }

    if (supabase && isSupabaseConfigured && alert.sourceTable === 'sensor_alerts') {
      const updates = { status }
      if (status === 'resolved') updates.resolved_at = new Date().toISOString()
      const { error: updateError } = await supabase
        .from('sensor_alerts')
        .update(updates)
        .eq('id', alertId)
      if (updateError) throw new Error(updateError.message)
    }

    setAlerts((current) => current.map((row) => (
      row.id === alertId ? { ...row, status, ...(status === 'resolved' ? { resolvedAt: new Date() } : {}) } : row
    )))
  }, [alerts])

  const saveRules = useCallback(async (nextRules) => {
    const values = {
      id: 'default',
      voltage_warning_threshold: Number(nextRules.voltage_warning_threshold),
      current_warning_threshold: Number(nextRules.current_warning_threshold),
      offline_timeout_minutes: Number(nextRules.offline_timeout_minutes),
      realtime_enabled: Boolean(nextRules.realtime_enabled),
    }
    if (
      !Number.isFinite(values.voltage_warning_threshold) || values.voltage_warning_threshold <= 0 ||
      !Number.isFinite(values.current_warning_threshold) || values.current_warning_threshold <= 0 ||
      !Number.isInteger(values.offline_timeout_minutes) || values.offline_timeout_minutes < 2 || values.offline_timeout_minutes > 60
    ) {
      throw new Error('Enter positive voltage/current thresholds and an offline timeout between 2 and 60 minutes.')
    }

    if (supabase && isSupabaseConfigured) {
      const { error: saveError } = await supabase.from('telemetry_settings').upsert(values)
      if (saveError) throw new Error(saveError.message)
    }
    setRules(values)
  }, [])

  return {
    activities,
    alerts,
    movements,
    source,
    loading,
    error,
    rules,
    refresh,
    updateAlert,
    saveRules,
  }
}
