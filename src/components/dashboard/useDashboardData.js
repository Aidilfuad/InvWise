import { useCallback, useEffect, useState } from 'react'
import { isSupabaseConfigured, supabase } from '../../lib/supabase'

const seedWarehouses = [
  { id: 'seed-cold', name: 'Cold Storage A', code: 'A-01' },
  { id: 'seed-main', name: 'Main Warehouse B', code: 'B-02' },
  { id: 'seed-distribution', name: 'Distribution C', code: 'C-03' },
  { id: 'seed-east', name: 'East Warehouse D', code: 'D-04' },
]

const seedItems = [
  { id: 'seed-labels', name: 'Thermal labels 4×6', sku: 'SKU-LBL-042', barcode: '9556123400421', categoryId: 'seed-category-packaging', unitId: 'seed-unit-roll', categoryName: 'Packaging', unitName: 'Roll', unitAbbreviation: 'rl', quantity: 12, minimumStock: 40, unitPrice: 18.5, levels: { 'seed-cold': 12 }, locationId: 'seed-cold', binLocation: 'A-02 · Bin 04', notes: '' },
  { id: 'seed-gloves', name: 'Nitrile gloves · M', sku: 'SKU-PPE-018', barcode: '9556123400186', categoryId: 'seed-category-safety', unitId: 'seed-unit-box', categoryName: 'Safety & PPE', unitName: 'Box', unitAbbreviation: 'box', quantity: 8, minimumStock: 30, unitPrice: 24, levels: { 'seed-main': 8 }, locationId: 'seed-main', binLocation: 'B-01 · Bin 12', notes: '' },
  { id: 'seed-wrap', name: 'Pallet wrap 500mm', sku: 'SKU-PKG-006', barcode: '9556123400063', categoryId: 'seed-category-packaging', unitId: 'seed-unit-roll', categoryName: 'Packaging', unitName: 'Roll', unitAbbreviation: 'rl', quantity: 5, minimumStock: 20, unitPrice: 32, levels: { 'seed-main': 5 }, locationId: 'seed-main', binLocation: 'B-03 · Bin 02', notes: '' },
  { id: 'seed-box', name: 'Insulated shipping box', sku: 'SKU-PKG-024', barcode: '9556123400247', categoryId: 'seed-category-packaging', unitId: 'seed-unit-each', categoryName: 'Packaging', unitName: 'Each', unitAbbreviation: 'ea', quantity: 125, minimumStock: 24, unitPrice: 46, levels: { 'seed-distribution': 125 }, locationId: 'seed-distribution', binLocation: 'C-02 · Bin 08', notes: '' },
  { id: 'seed-sensor', name: 'Temperature sensor probe', sku: 'SKU-HW-031', barcode: '9556123400315', categoryId: 'seed-category-hardware', unitId: 'seed-unit-each', categoryName: 'Hardware', unitName: 'Each', unitAbbreviation: 'ea', quantity: 24, minimumStock: 6, unitPrice: 72, levels: { 'seed-cold': 24 }, locationId: 'seed-cold', binLocation: 'A-04 · Bin 01', notes: '' },
  { id: 'seed-cleaner', name: 'Food-safe surface cleaner', sku: 'SKU-CLN-012', barcode: '9556123400124', categoryId: 'seed-category-cleaning', unitId: 'seed-unit-bottle', categoryName: 'Cleaning', unitName: 'Bottle', unitAbbreviation: 'bt', quantity: 0, minimumStock: 12, unitPrice: 14.5, levels: { 'seed-east': 0 }, locationId: 'seed-east', binLocation: 'D-01 · Bin 03', notes: '' },
]

const seedMovements = [
  { id: 'seed-movement-1', itemId: 'seed-labels', itemName: 'Thermal labels 4×6', sku: 'SKU-LBL-042', type: 'receipt', quantity: 240, warehouseName: 'Main Warehouse B', occurredAt: new Date('2026-10-24T10:42:00-04:00') },
  { id: 'seed-movement-2', itemId: 'seed-gloves', itemName: 'Nitrile gloves · M', sku: 'SKU-PPE-018', type: 'issue', quantity: 48, warehouseName: 'Cold Storage A', occurredAt: new Date('2026-10-24T10:38:00-04:00') },
  { id: 'seed-movement-3', itemId: 'seed-wrap', itemName: 'Pallet wrap 500mm', sku: 'SKU-PKG-006', type: 'adjustment', quantity: 12, warehouseName: 'Main Warehouse B', occurredAt: new Date('2026-10-24T10:31:00-04:00') },
  { id: 'seed-movement-4', itemId: 'seed-box', itemName: 'Insulated shipping box', sku: 'SKU-PKG-024', type: 'receipt', quantity: 120, warehouseName: 'Distribution C', occurredAt: new Date('2026-10-24T10:24:00-04:00') },
]

const seedTelemetry = [
  {
    name: 'Cold Storage A',
    temperature: 4.2,
    humidity: 58,
    energy: 3.8,
    temperatureSeries: [4.1, 4.3, 4.2, 4.4, 4.3, 4.5, 4.4, 4.6, 4.4, 4.5, 4.7, 4.5, 4.6, 4.4, 4.5, 4.3, 4.2],
    humiditySeries: [55, 56, 55, 57, 56, 58, 57, 59, 57, 58, 60, 58, 59, 57, 58, 58, 58],
    energySeries: [3.4, 3.5, 3.6, 3.5, 3.7, 3.8, 3.7, 3.9, 3.8, 3.7, 3.9, 3.8, 4.0, 3.8, 3.9, 3.8, 3.8],
  },
  {
    name: 'Main Warehouse B',
    temperature: 22.8,
    humidity: 46,
    energy: 5.1,
    temperatureSeries: [22.5, 22.6, 22.7, 22.6, 22.8, 22.7, 22.9, 22.8, 23, 22.8, 22.9, 22.7, 22.8, 22.9, 22.7, 22.8, 22.8],
    humiditySeries: [44, 45, 44, 45, 46, 45, 47, 46, 45, 46, 47, 46, 45, 46, 46, 47, 46],
    energySeries: [4.7, 4.8, 4.9, 4.8, 5, 4.9, 5.1, 5, 5.2, 5.1, 5.3, 5.1, 5.2, 5, 5.1, 5.1, 5.1],
  },
]

const seedAlerts = [
  { id: 'seed-alert-1', title: 'Sensor B-07 offline', subtitle: 'Main Warehouse B · 8 min ago', severity: 'Warning', message: 'Sensor B-07 has not reported recently.' },
  { id: 'seed-alert-2', title: 'Gateway firmware update', subtitle: 'Version 2.8.1 available', severity: 'Info', message: 'A new gateway firmware version is available.' },
]

function createSeedData() {
  return {
    items: seedItems.map((item) => {
      const location = seedWarehouses.find((warehouse) => warehouse.id === item.locationId)
      return {
        ...item,
        locationName: location?.name ?? '',
        locationCode: location?.code ?? '',
        binLocations: item.locationId ? { [item.locationId]: item.binLocation } : {},
        levels: { ...item.levels },
      }
    }),
    warehouses: seedWarehouses.map((warehouse) => ({ ...warehouse })),
    movements: seedMovements.map((movement) => ({ ...movement })),
    telemetry: seedTelemetry.map((zone) => ({ ...zone })),
    alerts: seedAlerts.map((alert) => ({ ...alert })),
    activeAlertCount: 3,
    summary: { totalStockValue: 148920, totalSkus: 1284, lowStockAlerts: 14, activeWarehouses: 4, inStock: 84, lowStock: 11, outOfStock: 5 },
    currencyCode: 'USD',
    exchangeRateUsdMyr: 4.25,
    units: [
      { id: 'seed-unit-each', name: 'Each', abbreviation: 'ea', is_active: true },
      { id: 'seed-unit-box', name: 'Box', abbreviation: 'box', is_active: true },
      { id: 'seed-unit-roll', name: 'Roll', abbreviation: 'rl', is_active: true },
      { id: 'seed-unit-bottle', name: 'Bottle', abbreviation: 'bt', is_active: true },
    ],
    categories: [
      { id: 'seed-category-safety', name: 'Safety & PPE', is_active: true },
      { id: 'seed-category-packaging', name: 'Packaging', is_active: true },
      { id: 'seed-category-hardware', name: 'Hardware', is_active: true },
      { id: 'seed-category-cleaning', name: 'Cleaning', is_active: true },
    ],
    barcodeFieldAvailable: true,
    binLocationFieldAvailable: true,
    profile: null,
    live: false,
  }
}

function numberValue(value, fallback = 0) {
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : fallback
}

function relatedRow(value) {
  return Array.isArray(value) ? value[0] : value
}

function sensorZone(sensor) {
  const description = `${sensor?.sensor_name ?? ''} ${sensor?.sensor_code ?? ''}`.toLowerCase()
  return description.includes('cold') || description.includes('storage a') || description.includes('zone a')
    ? 'Cold Storage A'
    : 'Main Warehouse B'
}

function makeSeries(value, count = 17) {
  return Array.from({ length: count }, () => numberValue(value))
}

function formatRelativeTime(dateValue) {
  if (!dateValue) return 'just now'
  const date = new Date(dateValue)
  if (Number.isNaN(date.getTime())) return 'just now'
  const minutes = Math.max(0, Math.floor((Date.now() - date.getTime()) / 60000))
  return minutes < 1 ? 'just now' : `${minutes} min ago`
}

function buildLiveData({
  inventoryRows,
  stockRows,
  barcodeRows,
  binLocationRows,
  locationRows,
  movementRows,
  inventoryAlertRows,
  sensorRows,
  sensorAlertRows,
  energyRows,
  inventoryCount,
  units,
  categories,
  profile,
  currencyCode,
  exchangeRateUsdMyr,
}) {
  const warehouseById = new Map(locationRows.map((location) => [location.id, location]))
  const categoryById = new Map((categories ?? []).map((category) => [category.id, category]))
  const unitById = new Map((units ?? []).map((unit) => [unit.id, unit]))
  const barcodeById = new Map((barcodeRows ?? []).map((row) => [row.id, row.barcode]))
  const binByItemAndLocation = new Map((binLocationRows ?? []).map((row) => [
    `${row.item_id}:${row.location_id}`,
    row.bin_location,
  ]))
  const stockByItem = new Map()
  for (const stock of stockRows) {
    const itemLevels = stockByItem.get(stock.item_id) ?? {}
    itemLevels[stock.location_id] = numberValue(stock.quantity)
    stockByItem.set(stock.item_id, itemLevels)
  }

  const items = inventoryRows
    .filter((item) => item.is_active !== false && item.is_archived !== true)
    .map((item) => {
      const levels = stockByItem.get(item.id) ?? {}
      const quantity = Object.values(levels).reduce((sum, value) => sum + numberValue(value), 0)
      const locationId = Object.keys(levels).find((id) => numberValue(levels[id]) > 0) ?? Object.keys(levels)[0] ?? null
      const category = categoryById.get(item.category_id)
      const unit = unitById.get(item.unit_id)
      return {
        id: item.id,
        sku: item.sku ?? '',
        name: item.name ?? 'Unnamed item',
        barcode: barcodeById.get(item.id) ?? '',
        description: item.description ?? '',
        notes: item.notes ?? '',
        minimumStock: numberValue(item.minimum_stock ?? item.min_stock ?? item.reorder_level),
        unitPrice: numberValue(item.unit_price),
        unitId: item.unit_id,
        categoryId: item.category_id,
        categoryName: category?.name ?? 'Uncategorized',
        unitName: unit?.name ?? 'Unit',
        unitAbbreviation: unit?.abbreviation ?? 'ea',
        quantity,
        levels: { ...levels },
        locationId,
        locationName: locationId ? warehouseById.get(locationId)?.name ?? '' : '',
        locationCode: locationId ? warehouseById.get(locationId)?.code ?? '' : '',
        binLocation: locationId ? binByItemAndLocation.get(`${item.id}:${locationId}`) ?? '' : '',
        binLocations: Object.fromEntries(Object.keys(levels).map((id) => [
          id,
          binByItemAndLocation.get(`${item.id}:${id}`) ?? '',
        ])),
        isActive: item.is_active !== false,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
      }
    })

  const lowAlertIds = new Set()
  const outAlertIds = new Set()
  for (const alert of inventoryAlertRows ?? []) {
    const kind = `${alert.alert_type ?? ''} ${alert.alert_level ?? ''} ${alert.severity ?? ''} ${alert.type ?? ''} ${alert.status ?? ''}`.toLowerCase()
    const itemId = alert.item_id ?? alert.inventory_item_id
    if (!itemId) continue
    if (kind.includes('out') && kind.includes('stock')) outAlertIds.add(itemId)
    else if (kind.includes('low') && kind.includes('stock')) lowAlertIds.add(itemId)
  }

  let lowStockCount = 0
  let outOfStockCount = 0
  for (const item of items) {
    if (outAlertIds.size > 0) {
      if (outAlertIds.has(item.id)) outOfStockCount += 1
    } else if (item.quantity <= 0) {
      outOfStockCount += 1
    }

    if (lowAlertIds.size > 0) {
      if (lowAlertIds.has(item.id) && !outAlertIds.has(item.id)) lowStockCount += 1
    } else if (item.quantity > 0 && item.quantity <= item.minimumStock) {
      lowStockCount += 1
    }
  }

  const itemById = new Map(items.map((item) => [item.id, item]))
  const movements = movementRows.map((row) => {
    const item = itemById.get(row.item_id)
    const locationId = row.destination_location_id ?? row.source_location_id
    const otherLocationId = row.destination_location_id && row.source_location_id
      ? row.source_location_id
      : null
    return {
      id: row.id,
      itemId: row.item_id,
      itemName: item?.name ?? 'Unknown item',
      sku: item?.sku ?? '',
      type: row.movement_type ?? 'adjustment',
      quantity: numberValue(row.quantity),
      warehouseName: otherLocationId
        ? `${warehouseById.get(otherLocationId)?.name ?? 'Warehouse'} → ${warehouseById.get(locationId)?.name ?? 'Warehouse'}`
        : warehouseById.get(locationId)?.name ?? '—',
      occurredAt: new Date(row.occurred_at),
    }
  })

  const zones = seedTelemetry.map((zone) => ({
    ...zone,
    temperatureSeries: makeSeries(zone.temperature),
    humiditySeries: makeSeries(zone.humidity),
    energySeries: makeSeries(zone.energy),
  }))
  const zoneByName = new Map(zones.map((zone) => [zone.name, zone]))
  const sensorById = new Map()
  for (const row of sensorRows ?? []) {
    const sensor = relatedRow(row.sensors)
    if (!sensor) continue
    sensorById.set(row.sensor_id, sensor)
    const zone = zoneByName.get(sensorZone(sensor))
    if (!zone) continue
    const kind = `${sensor.sensor_type ?? ''} ${sensor.sensor_name ?? ''}`.toLowerCase()
    const value = row.value_numeric == null ? Number.parseFloat(row.value_text) : numberValue(row.value_numeric)
    if (!Number.isFinite(value)) continue
    if (kind.includes('temperature') || kind.includes('temp')) {
      zone.temperature = value
      zone.temperatureSeries = makeSeries(value)
    } else if (kind.includes('humidity')) {
      zone.humidity = value
      zone.humiditySeries = makeSeries(value)
    } else if (kind.includes('energy') || kind.includes('power')) {
      zone.energy = value
      zone.energySeries = makeSeries(value)
    }
  }
  for (const row of [...(energyRows ?? [])].reverse()) {
    const sensor = sensorById.get(row.sensor_id)
    const zone = zoneByName.get(sensorZone(sensor))
    if (zone) zone.energySeries.push(numberValue(row.power))
  }
  for (const zone of zones) {
    zone.energySeries = zone.energySeries.slice(-17)
  }

  const alerts = (sensorAlertRows ?? []).map((alert) => {
    const sensor = relatedRow(alert.sensors)
    return {
      id: alert.id,
      title: alert.message?.split(':')[0] ?? alert.alert_type?.replaceAll('_', ' ') ?? 'Sensor alert',
      subtitle: `${sensor?.sensor_name ?? 'Telemetry sensor'} · ${formatRelativeTime(alert.detected_at)}`,
      severity: alert.severity === 'critical' || alert.severity === 'warning' ? 'Warning' : 'Info',
      message: alert.message ?? '',
    }
  })

  const inStockCount = Math.max(0, items.length - lowStockCount - outOfStockCount)
  const total = Math.max(items.length, 1)

  return {
    items,
    warehouses: locationRows.map((location) => ({ id: location.id, name: location.name, code: location.code ?? '', isActive: location.is_active !== false })),
    movements,
    telemetry: zones,
    alerts,
    activeAlertCount: alerts.length + (inventoryAlertRows?.length ?? 0),
    summary: {
      totalStockValue: items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0),
      totalSkus: inventoryCount ?? items.length,
      lowStockAlerts: lowStockCount,
      activeWarehouses: locationRows.filter((location) => location.is_active !== false).length,
      inStock: Math.round(inStockCount / total * 100),
      lowStock: Math.round(lowStockCount / total * 100),
      outOfStock: Math.round(outOfStockCount / total * 100),
    },
    currencyCode,
    exchangeRateUsdMyr,
    units: units ?? [],
    categories: categories ?? [],
    barcodeFieldAvailable: barcodeRows !== null,
    binLocationFieldAvailable: binLocationRows !== null,
    profile,
    live: true,
  }
}

async function readQuery(query, name, issues) {
  try {
    const { data, error } = await query
    if (error) {
      issues.push(`${name}: ${error.message}`)
      return null
    }
    return data
  } catch (error) {
    issues.push(`${name}: ${error instanceof Error ? error.message : 'request failed'}`)
    return null
  }
}

async function readCount(query, name, issues) {
  try {
    const { count, error } = await query
    if (error) {
      issues.push(`${name}: ${error.message}`)
      return null
    }
    return count ?? 0
  } catch (error) {
    issues.push(`${name}: ${error instanceof Error ? error.message : 'request failed'}`)
    return null
  }
}

async function readOptionalPages(queryFactory, name, issues, missingColumn) {
  const rows = []
  const pageSize = 500
  for (let from = 0; from < 10000; from += pageSize) {
    let page
    try {
      const { data, error } = await queryFactory().range(from, from + pageSize - 1)
      if (error) {
        if (error.code === '42703' || error.message?.toLowerCase().includes(missingColumn)) return null
        issues.push(`${name}: ${error.message}`)
        return null
      }
      page = data
    } catch (error) {
      issues.push(`${name}: ${error instanceof Error ? error.message : 'request failed'}`)
      return null
    }
    rows.push(...page)
    if (page.length < pageSize) return rows
  }
  issues.push(`${name}: result exceeds the 10,000 row inventory limit`)
  return null
}

async function readPages(queryFactory, name, issues) {
  const rows = []
  const pageSize = 500
  const maxRows = 10000
  for (let from = 0; from < maxRows; from += pageSize) {
    const page = await readQuery(queryFactory().range(from, from + pageSize - 1), name, issues)
    if (!page) return null
    rows.push(...page)
    if (page.length < pageSize) return rows
  }
  issues.push(`${name}: result exceeds the 10,000 row dashboard limit`)
  return null
}

export default function useDashboardData(session) {
  const [data, setData] = useState(createSeedData)
  const [source, setSource] = useState('demo')
  const [loading, setLoading] = useState(Boolean(supabase && session?.user))
  const [error, setError] = useState('')

  const refresh = useCallback(async () => {
    if (!isSupabaseConfigured || !supabase || !session?.user) {
      return
    }

    const issues = []
    const profileRows = await readQuery(
      supabase.from('profiles').select('id,full_name,role').eq('auth_user_id', session.user.id).maybeSingle(),
      'Profile',
      issues,
    )
    setLoading(true)
    const profile = profileRows ?? null
    const currencyRows = profile?.id
      ? await readQuery(
        supabase.from('user_settings').select('currency_code').eq('profile_id', profile.id).maybeSingle(),
        'Currency preference',
        issues,
      )
      : null
    const rateRows = await readQuery(
      supabase.from('app_settings').select('exchange_rate_usd_myr').eq('id', 'exchange_rate_usd_myr').maybeSingle(),
      'Currency exchange rate',
      issues,
    )

    const [
      inventoryRows,
      inventoryCount,
      stockRows,
      barcodeRows,
      binLocationRows,
      locationRows,
      movementRows,
      inventoryAlertRows,
      sensorRows,
      sensorAlertRows,
      energyRows,
      units,
      categories,
    ] = await Promise.all([
      readPages(
        () => supabase.from('inventory_items')
          .select('id,sku,name,description,notes,minimum_stock,unit_price,is_active,is_archived,unit_id,category_id,created_at,updated_at')
          .eq('is_active', true)
          .eq('is_archived', false)
          .order('name'),
        'Inventory',
        issues,
      ),
      readCount(
        supabase.from('inventory_items')
          .select('id', { count: 'exact', head: true })
          .eq('is_active', true)
          .eq('is_archived', false),
        'Inventory count',
        issues,
      ),
      readPages(
        () => supabase.from('stock_levels').select('item_id,location_id,quantity').order('item_id'),
        'Stock levels',
        issues,
      ),
      import.meta.env.VITE_INVENTORY_METADATA_FIELDS_ENABLED === 'true'
        ? readOptionalPages(
          () => supabase.from('inventory_items').select('id,barcode').order('id'),
          'Barcode metadata',
          issues,
          'barcode',
        )
        : Promise.resolve(null),
      import.meta.env.VITE_INVENTORY_METADATA_FIELDS_ENABLED === 'true'
        ? readOptionalPages(
          () => supabase.from('stock_levels').select('item_id,location_id,bin_location').order('item_id').order('location_id'),
          'Bin and zone metadata',
          issues,
          'bin_location',
        )
        : Promise.resolve(null),
      readQuery(supabase.from('warehouse_locations').select('id,name,code,is_active').order('name'), 'Warehouses', issues),
      readQuery(
        supabase.from('stock_movements')
          .select('id,item_id,movement_type,quantity,source_location_id,destination_location_id,occurred_at')
          .order('occurred_at', { ascending: false })
          .limit(8),
        'Stock movements',
        issues,
      ),
      readQuery(supabase.from('inventory_alerts').select('*'), 'Inventory alerts', issues),
      readQuery(
        supabase.from('sensor_status')
          .select('sensor_id,value_numeric,value_text,last_seen,sensors(sensor_code,sensor_name,sensor_type)')
          .order('last_seen', { ascending: false })
          .limit(50),
        'Sensor readings',
        issues,
      ),
      readQuery(
        supabase.from('sensor_alerts')
          .select('id,sensor_id,alert_type,severity,status,message,detected_at,sensors(sensor_name)')
          .eq('status', 'active')
          .order('detected_at', { ascending: false })
          .limit(20),
        'Sensor alerts',
        issues,
      ),
      readQuery(
        supabase.from('energy_readings')
          .select('sensor_id,power,recorded_at')
          .gte('recorded_at', new Date(Date.now() - 60 * 60 * 1000).toISOString())
          .order('recorded_at', { ascending: false })
          .limit(200),
        'Energy history',
        issues,
      ),
      readQuery(supabase.from('units').select('id,name,abbreviation,description,is_active').order('name'), 'Units', issues),
      readQuery(supabase.from('categories').select('id,name,description,is_active').order('name'), 'Categories', issues),
    ])

    if (!inventoryRows || !stockRows || !locationRows) {
      setData(createSeedData())
      setSource('demo')
      setError(`Live dashboard data is unavailable. Showing sample data.${issues[0] ? ` ${issues[0]}` : ''}`)
      setLoading(false)
      return
    }

    const nextData = buildLiveData({
      inventoryRows,
      stockRows,
      barcodeRows,
      binLocationRows,
      locationRows,
      movementRows: movementRows ?? [],
      inventoryAlertRows: inventoryAlertRows ?? [],
      sensorRows: sensorRows ?? [],
      sensorAlertRows: sensorAlertRows ?? [],
      energyRows: energyRows ?? [],
      inventoryCount,
      units: units ?? [],
      categories: categories ?? [],
      profile,
      currencyCode: currencyRows?.currency_code ?? 'MYR',
      exchangeRateUsdMyr: numberValue(rateRows?.exchange_rate_usd_myr, 4.25),
    })

    if (!movementRows) nextData.movements = createSeedData().movements
    if (!sensorRows) nextData.telemetry = createSeedData().telemetry
    if (!sensorAlertRows) {
      nextData.alerts = createSeedData().alerts
      nextData.activeAlertCount = 3
    }
    setData(nextData)
    setSource('live')
    setError(issues.length > 0 ? `Some live data could not be loaded: ${issues[0]}` : '')
    setLoading(false)
  }, [session])

  useEffect(() => {
    let active = true
    void Promise.resolve().then(() => (active ? refresh() : undefined)).catch((loadError) => {
      if (!active) return
      setError(loadError instanceof Error ? loadError.message : 'Unable to load dashboard data.')
      setLoading(false)
    })
    return () => {
      active = false
    }
  }, [refresh])

  useEffect(() => {
    if (!supabase || !session?.user) return undefined
    const channel = supabase
      .channel('invwise-dashboard-updates')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'stock_levels' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'stock_movements' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'inventory_items' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sensor_status' }, refresh)
      .on('postgres_changes', { event: '*', schema: 'public', table: 'sensor_alerts' }, refresh)
      .subscribe()
    return () => {
      supabase.removeChannel(channel)
    }
  }, [refresh, session])

  function applyLocalAdjustment({ itemId, locationId, quantity, add, movementId }) {
    setData((current) => {
      const item = current.items.find((row) => row.id === itemId)
      if (!item) return current
      const nextQuantity = numberValue(item.levels[locationId]) + (add ? quantity : -quantity)
      if (nextQuantity < 0) return current
      const totalQuantity = item.quantity + (add ? quantity : -quantity)
      const previousStatus = item.quantity <= 0 ? 'out' : item.quantity <= item.minimumStock ? 'low' : 'in'
      const nextStatus = totalQuantity <= 0 ? 'out' : totalQuantity <= item.minimumStock ? 'low' : 'in'
      const percentageStep = 100 / Math.max(current.summary.totalSkus, current.items.length, 1)
      const itemLevels = { ...item.levels, [locationId]: nextQuantity }
      const nextItems = current.items.map((row) => row.id === itemId
        ? { ...row, levels: itemLevels, quantity: Object.values(itemLevels).reduce((sum, value) => sum + numberValue(value), 0) }
        : row)
      const locationName = current.warehouses.find((warehouse) => warehouse.id === locationId)?.name ?? 'Warehouse'
      const movement = {
        id: movementId,
        itemId,
        itemName: item.name,
        sku: item.sku,
        type: add ? 'receipt' : 'issue',
        quantity,
        warehouseName: locationName,
        occurredAt: new Date(),
      }
      return {
        ...current,
        items: nextItems,
        movements: [movement, ...current.movements].slice(0, 8),
        summary: {
          ...current.summary,
          totalStockValue: current.summary.totalStockValue + (add ? 1 : -1) * quantity * item.unitPrice,
          lowStockAlerts: Math.max(0, current.summary.lowStockAlerts + (nextStatus === 'low' ? 1 : 0) - (previousStatus === 'low' ? 1 : 0)),
          inStock: Math.round(current.summary.inStock + ((nextStatus === 'in' ? 1 : 0) - (previousStatus === 'in' ? 1 : 0)) * percentageStep),
          lowStock: Math.round(current.summary.lowStock + ((nextStatus === 'low' ? 1 : 0) - (previousStatus === 'low' ? 1 : 0)) * percentageStep),
          outOfStock: Math.round(current.summary.outOfStock + ((nextStatus === 'out' ? 1 : 0) - (previousStatus === 'out' ? 1 : 0)) * percentageStep),
        },
      }
    })
  }

  async function adjustStock({ itemId, locationId, quantity, add, notes }) {
    const item = data.items.find((row) => row.id === itemId)
    if (!item || quantity <= 0) throw new Error('Select an item and enter a quantity greater than zero.')
    const currentQuantity = numberValue(item.levels[locationId])
    if (!add && currentQuantity < quantity) throw new Error('Cannot remove more stock than is available at this location.')
    if (supabase && source !== 'live') throw new Error('Live inventory could not be loaded. Refresh and retry before saving.')
    if (supabase && isSupabaseConfigured && !data.profile?.id) {
      throw new Error('Your workspace profile could not be verified.')
    }

    const previousData = data
    const localMovementId = `local-${Date.now()}`
    applyLocalAdjustment({ itemId, locationId, quantity, add, movementId: localMovementId })
    if (!supabase || !isSupabaseConfigured) return

    let updatedQuantity = currentQuantity
    try {
      const { data: currentStock, error: stockError } = await supabase
        .from('stock_levels')
        .select('quantity')
        .eq('item_id', itemId)
        .eq('location_id', locationId)
        .maybeSingle()
      if (stockError) throw stockError
      updatedQuantity = numberValue(currentStock?.quantity) + (add ? quantity : -quantity)
      if (updatedQuantity < 0) throw new Error('Cannot remove more stock than is available at this location.')

      const { error: updateError } = await supabase.from('stock_levels').upsert({
        item_id: itemId,
        location_id: locationId,
        quantity: updatedQuantity,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'item_id,location_id' })
      if (updateError) throw updateError

      const profile = data.profile
      const { data: movement, error: movementError } = await supabase
        .from('stock_movements')
        .insert({
          item_id: itemId,
          movement_type: add ? 'receipt' : 'issue',
          quantity,
          source_location_id: add ? null : locationId,
          destination_location_id: add ? locationId : null,
          notes: notes.trim() || null,
          performed_by: profile.id,
          occurred_at: new Date().toISOString(),
        })
        .select('id')
        .single()
      if (movementError) {
        const { error: rollbackError } = await supabase.from('stock_levels').upsert({
          item_id: itemId,
          location_id: locationId,
          quantity: currentStock?.quantity ?? 0,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'item_id,location_id' })
        if (rollbackError) {
          throw new Error(`${movementError.message} The stock rollback failed: ${rollbackError.message}`)
        }
        throw movementError
      }
      setData((current) => {
        const currentItem = current.items.find((row) => row.id === itemId)
        const previousLevel = numberValue(currentItem?.levels[locationId])
        const levels = { ...currentItem?.levels, [locationId]: updatedQuantity }
        const nextQuantity = Object.values(levels).reduce((sum, value) => sum + numberValue(value), 0)
        return {
          ...current,
          items: current.items.map((row) => row.id === itemId
            ? { ...row, levels, quantity: nextQuantity }
            : row),
          movements: current.movements.map((row) => row.id === localMovementId ? { ...row, id: movement.id } : row),
          summary: {
            ...current.summary,
            totalStockValue: current.summary.totalStockValue + (updatedQuantity - previousLevel) * (currentItem?.unitPrice ?? 0),
          },
        }
      })
    } catch (error) {
      setData(previousData)
      throw new Error(error instanceof Error ? error.message : 'Unable to save the stock adjustment.')
    }
  }

  async function recordStockMovement({
    itemId,
    mode,
    quantity,
    locationId,
    destinationLocationId,
    direction,
    reason,
    notes,
  }) {
    const item = data.items.find((row) => row.id === itemId)
    const numericQuantity = Number(quantity)
    if (!item || !Number.isFinite(numericQuantity) || numericQuantity <= 0) {
      throw new Error('Choose an item and enter a quantity greater than zero.')
    }

    let movementType
    let sourceLocationId = null
    let targetLocationId = null
    if (mode === 'stock-in') {
      movementType = 'receipt'
      targetLocationId = locationId
    } else if (mode === 'stock-out') {
      movementType = 'issue'
      sourceLocationId = locationId
    } else if (mode === 'transfer') {
      movementType = 'transfer'
      sourceLocationId = locationId
      targetLocationId = destinationLocationId
    } else if (mode === 'adjustment') {
      movementType = direction === 'remove' ? 'issue' : 'receipt'
      if (direction === 'remove') sourceLocationId = locationId
      else targetLocationId = locationId
    } else {
      throw new Error('Choose a valid stock movement type.')
    }

    if (!sourceLocationId && !targetLocationId) {
      throw new Error('Choose a warehouse for this stock movement.')
    }
    if (sourceLocationId && targetLocationId && sourceLocationId === targetLocationId) {
      throw new Error('Choose two different warehouses for a transfer.')
    }
    if (supabase && source !== 'live') {
      throw new Error('Live inventory could not be loaded. Refresh and retry before saving.')
    }

    const affectedLocations = [...new Set([sourceLocationId, targetLocationId].filter(Boolean))]
    const previousQuantities = new Map()
    const updatedQuantities = new Map()
    const now = new Date().toISOString()
    let warning = ''

    if (!supabase || !isSupabaseConfigured) {
      for (const id of affectedLocations) {
        const currentQuantity = numberValue(item.levels[id])
        previousQuantities.set(id, currentQuantity)
        const delta = id === sourceLocationId ? -numericQuantity : numericQuantity
        const nextQuantity = currentQuantity + delta
        if (nextQuantity < 0) {
          throw new Error(`Only ${currentQuantity} units are available at this warehouse.`)
        }
        updatedQuantities.set(id, nextQuantity)
      }

      const sourceName = data.warehouses.find((row) => row.id === sourceLocationId)?.name
      const destinationName = data.warehouses.find((row) => row.id === targetLocationId)?.name
      const movement = {
        id: `local-${Date.now()}`,
        itemId,
        itemName: item.name,
        sku: item.sku,
        type: movementType,
        quantity: numericQuantity,
        warehouseName: movementType === 'transfer'
          ? `${sourceName} → ${destinationName}`
          : sourceName ?? destinationName ?? 'Warehouse',
        occurredAt: new Date(now),
      }
      setData((current) => {
        const nextItems = current.items.map((row) => {
          if (row.id !== itemId) return row
          const levels = { ...row.levels, ...Object.fromEntries(updatedQuantities) }
          return {
            ...row,
            levels,
            quantity: Object.values(levels).reduce((sum, value) => sum + numberValue(value), 0),
            locationId: row.locationId ?? targetLocationId ?? sourceLocationId,
          }
        })
        const stockDelta = movementType === 'receipt'
          ? numericQuantity
          : movementType === 'issue'
            ? -numericQuantity
            : 0
        return {
          ...current,
          items: nextItems,
          movements: [movement, ...current.movements].slice(0, 8),
          summary: {
            ...current.summary,
            totalStockValue: current.summary.totalStockValue + stockDelta * item.unitPrice,
          },
        }
      })
      return { warning }
    }

    if (!data.profile?.id) throw new Error('Your workspace profile could not be verified.')

    for (const id of affectedLocations) {
      const { data: stock, error: stockError } = await supabase
        .from('stock_levels')
        .select('quantity')
        .eq('item_id', itemId)
        .eq('location_id', id)
        .maybeSingle()
      if (stockError) throw stockError

      const currentQuantity = numberValue(stock?.quantity)
      previousQuantities.set(id, currentQuantity)
      const delta = id === sourceLocationId ? -numericQuantity : numericQuantity
      const nextQuantity = currentQuantity + delta
      if (nextQuantity < 0) {
        throw new Error(`Only ${currentQuantity} units are available at this warehouse.`)
      }
      updatedQuantities.set(id, nextQuantity)
    }

    try {
      for (const id of affectedLocations) {
        const { error: updateError } = await supabase.from('stock_levels').upsert({
          item_id: itemId,
          location_id: id,
          quantity: updatedQuantities.get(id),
          updated_at: now,
        }, { onConflict: 'item_id,location_id' })
        if (updateError) throw updateError
      }

      const { data: movement, error: movementError } = await supabase
        .from('stock_movements')
        .insert({
          item_id: itemId,
          movement_type: movementType,
          quantity: numericQuantity,
          source_location_id: sourceLocationId,
          destination_location_id: targetLocationId,
          reference: reason?.trim() || null,
          notes: notes?.trim() || null,
          performed_by: data.profile.id,
          occurred_at: now,
        })
        .select('id')
        .single()
      if (movementError) throw movementError

      try {
        const { error: activityError } = await supabase.from('activity_logs').insert({
          actor_user_id: session?.user?.id,
          actor_name: data.profile.full_name || session?.user?.email?.split('@')[0] || 'User',
          category: 'Inventory',
          action: movementType === 'receipt' ? 'Receipt' : movementType === 'issue' ? 'Issue' : 'Transfer',
          description: `${movementType === 'receipt' ? 'Receipt' : movementType === 'issue' ? 'Issue' : 'Transfer'}: ${numericQuantity} units for ${item.name}.`,
          entity_type: 'inventory_movement',
          entity_id: movement.id,
          metadata: {
            item_id: itemId,
            quantity: numericQuantity,
            reason: reason?.trim() || null,
            notes: notes?.trim() || null,
            source_location_id: sourceLocationId,
            destination_location_id: targetLocationId,
          },
        })
        if (activityError) throw activityError
      } catch (activityError) {
        warning = `The stock movement was saved, but activity logging failed: ${activityError instanceof Error ? activityError.message : 'Please contact your administrator.'}`
      }
    } catch (error) {
      let rollbackMessage = ''
      for (const id of [...previousQuantities.keys()].reverse()) {
        const { error: rollbackError } = await supabase.from('stock_levels').upsert({
          item_id: itemId,
          location_id: id,
          quantity: previousQuantities.get(id),
          updated_at: new Date().toISOString(),
        }, { onConflict: 'item_id,location_id' })
        if (rollbackError) rollbackMessage = rollbackError.message
      }
      if (rollbackMessage) {
        throw new Error(`${error instanceof Error ? error.message : 'Unable to save the stock movement.'} Stock levels could not be rolled back: ${rollbackMessage}`)
      }
      throw error instanceof Error ? error : new Error('Unable to save the stock movement.')
    }

    await refresh()
    return { warning }
  }

  async function saveInventoryItem(values) {
    const itemId = values.itemId
    const currentItem = itemId ? data.items.find((row) => row.id === itemId) : null
    const name = values.name.trim()
    const sku = values.sku.trim()
    const barcode = values.barcode?.trim() ?? ''
    const binLocation = values.binLocation?.trim() ?? ''
    if (!name || !sku || !values.unitId || !values.locationId) {
      throw new Error('Enter an item name and SKU, and choose a unit and warehouse.')
    }
    if (data.items.some((row) => row.id !== itemId && row.sku.toLowerCase() === sku.toLowerCase())) {
      throw new Error('That SKU is already in use. Enter a unique SKU.')
    }
    if (barcode && data.items.some((row) => row.id !== itemId && row.barcode?.toLowerCase() === barcode.toLowerCase())) {
      throw new Error('That barcode is already assigned to another item.')
    }
    if (barcode && !data.barcodeFieldAvailable) {
      throw new Error('Barcode storage is not available yet. Apply the InvWise inventory metadata migration first.')
    }
    if (binLocation && !data.binLocationFieldAvailable) {
      throw new Error('Bin and zone storage is not available yet. Apply the InvWise inventory metadata migration first.')
    }

    const quantity = Number(values.quantity)
    const minimumStock = Number(values.minimumStock)
    const unitPrice = Number(values.unitPrice)
    if ([quantity, minimumStock, unitPrice].some((value) => !Number.isFinite(value) || value < 0)) {
      throw new Error('Quantity, minimum stock, and unit price must be zero or greater.')
    }
    if (supabase && source !== 'live') {
      throw new Error('Live inventory could not be loaded. Refresh and retry before saving.')
    }

    const localId = itemId ?? `local-item-${Date.now()}`
    const nextItem = {
      ...currentItem,
      id: localId,
      name,
      sku,
      barcode,
      categoryId: values.categoryId || null,
      categoryName: data.categories.find((row) => row.id === values.categoryId)?.name ?? 'Uncategorized',
      unitId: values.unitId,
      unitName: data.units.find((row) => row.id === values.unitId)?.name ?? 'Unit',
      unitAbbreviation: data.units.find((row) => row.id === values.unitId)?.abbreviation ?? 'ea',
      minimumStock,
      unitPrice,
      notes: values.notes?.trim() ?? '',
      locationId: values.locationId,
      locationName: data.warehouses.find((row) => row.id === values.locationId)?.name ?? '',
      binLocation,
      levels: { ...(currentItem?.levels ?? {}), [values.locationId]: quantity },
      quantity: Object.values({ ...(currentItem?.levels ?? {}), [values.locationId]: quantity })
        .reduce((sum, value) => sum + numberValue(value), 0),
    }

    if (!supabase || !isSupabaseConfigured) {
      setData((current) => ({
        ...current,
        items: itemId
          ? current.items.map((row) => row.id === itemId ? nextItem : row)
          : [nextItem, ...current.items],
        summary: {
          ...current.summary,
          totalSkus: itemId ? current.summary.totalSkus : current.summary.totalSkus + 1,
          totalStockValue: current.summary.totalStockValue +
            (itemId
              ? nextItem.quantity * unitPrice - (currentItem?.quantity ?? 0) * (currentItem?.unitPrice ?? 0)
              : nextItem.quantity * unitPrice),
        },
      }))
      return { warning: '' }
    }

    if (!data.profile?.id) throw new Error('Your workspace profile could not be verified.')
    const payload = {
      sku,
      name,
      category_id: values.categoryId || null,
      unit_id: values.unitId,
      minimum_stock: minimumStock,
      unit_price: unitPrice,
      notes: values.notes?.trim() || null,
    }
    if (data.barcodeFieldAvailable) payload.barcode = barcode || null
    if (!itemId) {
      payload.description = values.description?.trim() || null
      payload.is_active = true
    }

    let savedItemId = itemId
    let warning = ''
    if (itemId) {
      const { data: updated, error: itemError } = await supabase
        .from('inventory_items')
        .update({ ...payload, updated_at: new Date().toISOString() })
        .eq('id', itemId)
        .select('id')
        .maybeSingle()
      if (itemError) throw itemError
      if (!updated) throw new Error('Item not found, or you do not have permission to update it.')
    } else {
      const { data: inserted, error: itemError } = await supabase
        .from('inventory_items')
        .insert(payload)
        .select('id')
        .single()
      if (itemError) throw itemError
      savedItemId = inserted.id
    }

    const stockPayload = {
      item_id: savedItemId,
      location_id: values.locationId,
      quantity,
      updated_at: new Date().toISOString(),
    }
    if (data.binLocationFieldAvailable) stockPayload.bin_location = binLocation || null
    const stockOperation = itemId
      ? supabase.from('stock_levels').upsert(stockPayload, { onConflict: 'item_id,location_id' })
      : supabase.from('stock_levels').insert(stockPayload)
    const { error: stockError } = await stockOperation
    if (stockError) {
      if (!itemId) {
        const { error: cleanupError } = await supabase.from('inventory_items').delete().eq('id', savedItemId)
        if (cleanupError) {
          await refresh()
          throw new Error(`The item was created, but its opening stock could not be saved (${stockError.message}); cleanup also failed (${cleanupError.message}).`)
        }
      } else {
        await refresh()
        throw new Error(`The item details were updated, but its stock location could not be saved: ${stockError.message}`)
      }
      throw new Error(`Unable to save the opening stock quantity: ${stockError.message}`)
    }

    try {
      const { error: activityError } = await supabase.from('activity_logs').insert({
        actor_user_id: session?.user?.id,
        actor_name: data.profile.full_name || session?.user?.email?.split('@')[0] || 'User',
        category: 'Inventory',
        action: itemId ? 'Update Item' : 'Create Item',
        description: `${itemId ? 'Updated' : 'Created'} inventory item ${name} (SKU ${sku}).`,
        entity_type: 'inventory_item',
        entity_id: savedItemId,
        metadata: { item_name: name, sku, quantity, location_id: values.locationId },
      })
      if (activityError) throw activityError
    } catch (activityError) {
      warning = `The item was saved, but activity logging failed: ${activityError instanceof Error ? activityError.message : 'Please contact your administrator.'}`
    }

    await refresh()
    return { warning }
  }

  async function archiveInventoryItem(itemId) {
    const item = data.items.find((row) => row.id === itemId)
    if (!item) throw new Error('Inventory item not found.')
    if (!supabase || !isSupabaseConfigured) {
      setData((current) => ({
        ...current,
        items: current.items.filter((row) => row.id !== itemId),
        summary: {
          ...current.summary,
          totalSkus: Math.max(0, current.summary.totalSkus - 1),
          totalStockValue: Math.max(0, current.summary.totalStockValue - item.quantity * item.unitPrice),
        },
      }))
      return
    }
    if (source !== 'live') throw new Error('Live inventory could not be loaded. Refresh and retry before archiving.')
    const { error: archiveError } = await supabase.rpc('archive_inventory_item', {
      p_item_id: itemId,
    })
    if (archiveError) throw archiveError
    await refresh()
  }

  async function saveCategory({ name, description = '' }) {
    const cleanedName = name.trim()
    if (!cleanedName) throw new Error('Enter a category name.')
    if (data.categories.some((row) => row.name.toLowerCase() === cleanedName.toLowerCase())) {
      throw new Error('A category with this name already exists.')
    }
    if (!supabase || !isSupabaseConfigured) {
      setData((current) => ({
        ...current,
        categories: [...current.categories, { id: `local-category-${Date.now()}`, name: cleanedName, description, is_active: true }],
      }))
      return
    }
    if (source !== 'live') throw new Error('Live categories could not be loaded. Refresh and retry.')
    const { error: categoryError } = await supabase.from('categories').insert({
      name: cleanedName,
      description: description.trim() || null,
      is_active: true,
    })
    if (categoryError) throw categoryError
    await refresh()
  }

  async function setCategoryActive({ id, active }) {
    if (!supabase || !isSupabaseConfigured) {
      setData((current) => ({
        ...current,
        categories: current.categories.map((row) => row.id === id ? { ...row, is_active: active } : row),
      }))
      return
    }
    if (source !== 'live') throw new Error('Live categories could not be loaded. Refresh and retry.')
    const { error: categoryError } = await supabase.from('categories').update({ is_active: active }).eq('id', id)
    if (categoryError) throw categoryError
    await refresh()
  }

  async function saveUnit({ name, abbreviation, description = '' }) {
    const cleanedName = name.trim()
    const cleanedAbbreviation = abbreviation.trim()
    if (!cleanedName || !cleanedAbbreviation) throw new Error('Enter a unit name and abbreviation.')
    if (data.units.some((row) => row.abbreviation.toLowerCase() === cleanedAbbreviation.toLowerCase())) {
      throw new Error('A unit with this abbreviation already exists.')
    }
    if (!supabase || !isSupabaseConfigured) {
      setData((current) => ({
        ...current,
        units: [...current.units, { id: `local-unit-${Date.now()}`, name: cleanedName, abbreviation: cleanedAbbreviation, description, is_active: true }],
      }))
      return
    }
    if (source !== 'live') throw new Error('Live units could not be loaded. Refresh and retry.')
    const { error: unitError } = await supabase.from('units').insert({
      name: cleanedName,
      abbreviation: cleanedAbbreviation,
      description: description.trim() || null,
      is_active: true,
    })
    if (unitError) throw unitError
    await refresh()
  }

  async function setUnitActive({ id, active }) {
    if (!supabase || !isSupabaseConfigured) {
      setData((current) => ({
        ...current,
        units: current.units.map((row) => row.id === id ? { ...row, is_active: active } : row),
      }))
      return
    }
    if (source !== 'live') throw new Error('Live units could not be loaded. Refresh and retry.')
    const { error: unitError } = await supabase.from('units').update({ is_active: active }).eq('id', id)
    if (unitError) throw unitError
    await refresh()
  }

  async function addInventory(values) {
    if (supabase && source !== 'live') throw new Error('Live inventory could not be loaded. Refresh and retry before saving.')
    const localItem = {
      id: `local-item-${Date.now()}`,
      name: values.name.trim(),
      sku: values.sku.trim(),
      quantity: numberValue(values.quantity),
      minimumStock: numberValue(values.minimumStock),
      unitPrice: numberValue(values.unitPrice),
      unitId: values.unitId,
      categoryId: values.categoryId || null,
      levels: { [values.locationId]: numberValue(values.quantity) },
    }

    const previousData = data
    setData((current) => {
      const oldTotal = Math.max(current.summary.totalSkus, 1)
      const newTotal = oldTotal + 1
      const stockStatus = localItem.quantity <= 0
        ? 'outOfStock'
        : localItem.quantity <= localItem.minimumStock
          ? 'lowStock'
          : 'inStock'
      const counts = {
        inStock: (current.summary.inStock * oldTotal) / 100,
        lowStock: (current.summary.lowStock * oldTotal) / 100,
        outOfStock: (current.summary.outOfStock * oldTotal) / 100,
      }
      counts[stockStatus] += 1
      return {
        ...current,
        items: [localItem, ...current.items],
        summary: {
          ...current.summary,
          totalSkus: current.summary.totalSkus + 1,
          totalStockValue: current.summary.totalStockValue + localItem.quantity * localItem.unitPrice,
          lowStockAlerts: current.summary.lowStockAlerts + (stockStatus === 'lowStock' ? 1 : 0),
          inStock: Math.round((counts.inStock / newTotal) * 100),
          lowStock: Math.round((counts.lowStock / newTotal) * 100),
          outOfStock: Math.round((counts.outOfStock / newTotal) * 100),
        },
      }
    })
    if (!supabase || !isSupabaseConfigured) return

    let itemCreated = false
    try {
      const { data: inserted, error: itemError } = await supabase
        .from('inventory_items')
        .insert({
          sku: localItem.sku,
          name: localItem.name,
          category_id: localItem.categoryId,
          unit_id: localItem.unitId,
          minimum_stock: localItem.minimumStock,
          unit_price: localItem.unitPrice,
          notes: values.notes.trim() || null,
          is_active: true,
        })
        .select('id')
        .single()
      if (itemError) throw itemError
      itemCreated = true

      const { error: stockError } = await supabase.from('stock_levels').insert({
        item_id: inserted.id,
        location_id: values.locationId,
        quantity: localItem.quantity,
        updated_at: new Date().toISOString(),
      })
      if (stockError) {
        await refresh()
        throw new Error(`The item was created, but its initial stock could not be saved: ${stockError.message}`)
      }
      await refresh()
    } catch (error) {
      if (!itemCreated) setData(previousData)
      throw error instanceof Error ? error : new Error('Unable to add this inventory item.')
    }
  }

  return {
    data,
    source,
    loading,
    error,
    refresh,
    adjustStock,
    addInventory,
    recordStockMovement,
    saveInventoryItem,
    archiveInventoryItem,
    saveCategory,
    setCategoryActive,
    saveUnit,
    setUnitActive,
  }
}
