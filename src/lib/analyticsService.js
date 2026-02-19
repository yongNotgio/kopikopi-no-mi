import { supabase } from './supabase'

// Constants for Robusta ideal ranges
export const ROBUSTA_IDEALS = {
  elevation_m: { min: 600, max: 1200 },
  avg_temp_c: { min: 13, max: 26 },
  avg_humidity_pct: { min: 75, max: 85 },
  avg_rainfall_mm: { min: 150, max: 250 },
  soil_ph: { min: 5.6, max: 6.5 },
  pruning_interval_months: { min: 10, max: 18 },
  bean_moisture: { min: 10.5, max: 12.5 },
}

export const STATUS_COLORS = {
  'Critical Drop (>20%)': '#ef4444',
  'Moderate Drop (5-20%)': '#f97316',
  'Stable (±5%)': '#22c55e',
  'Improvement (>5%)': '#3b82f6',
}

export const RISK_COLORS = {
  Low: '#22c55e',
  Moderate: '#f59e0b',
  High: '#f97316',
  Critical: '#ef4444',
}

export const GRADE_COLORS = ['#1B5E20', '#66BB6A', '#C8E6C9']

// Calculate yield status based on delta percentage
export function getYieldStatus(currentYield, previousYield) {
  if (!previousYield || previousYield === 0) return 'N/A'
  const deltaPct = ((currentYield - previousYield) / previousYield) * 100
  if (deltaPct <= -20) return 'Critical Drop (>20%)'
  if (deltaPct <= -5) return 'Moderate Drop (5-20%)'
  if (deltaPct <= 5) return 'Stable (±5%)'
  return 'Improvement (>5%)'
}

// Calculate risk level based on yield decline
export function getRiskLevel(currentYield, previousYield) {
  if (!previousYield || previousYield === 0) return { level: 'Low', priority: 1 }
  const decline = ((previousYield - currentYield) / previousYield) * 100
  if (decline > 50) return { level: 'Critical', priority: 4 }
  if (decline > 30) return { level: 'High', priority: 3 }
  if (decline > 15) return { level: 'Moderate', priority: 2 }
  return { level: 'Low', priority: 1 }
}

// Fetch all analytics data for admin (all farms)
export async function fetchAdminAnalytics() {
  try {
    // Fetch users (farmers)
    const { data: users, error: usersErr } = await supabase
      .from('users')
      .select('*')
      .eq('role', 'farmer')

    if (usersErr) throw usersErr

    // Fetch all farms with user data
    const { data: farms, error: farmsErr } = await supabase
      .from('farms')
      .select('*, users!inner(*)')

    if (farmsErr) throw farmsErr

    // Fetch all clusters with farm data and stage data
    const { data: clusters, error: clustersErr } = await supabase
      .from('clusters')
      .select('*, farms!inner(*, users!inner(*)), cluster_stage_data(*)')

    if (clustersErr) throw clustersErr

    // Fetch all harvest records
    const { data: harvests, error: harvestsErr } = await supabase
      .from('harvest_records')
      .select('*')
      .order('actual_harvest_date', { ascending: true })

    if (harvestsErr) throw harvestsErr

    // Process and enrich data
    const processedClusters = (clusters || []).map(cluster => {
      const stageData = cluster.cluster_stage_data || []
      const latestStage = stageData.sort((a, b) => 
        new Date(b.created_at) - new Date(a.created_at)
      )[0] || {}

      const clusterHarvests = (harvests || []).filter(h => h.cluster_id === cluster.id)
      const latestHarvest = clusterHarvests.sort((a, b) => 
        new Date(b.actual_harvest_date) - new Date(a.actual_harvest_date)
      )[0] || {}

      const risk = getRiskLevel(
        parseFloat(latestHarvest.yield_kg) || 0,
        parseFloat(latestStage.pre_yield_kg) || 0
      )

      return {
        ...cluster,
        farm: cluster.farms,
        farmer: cluster.farms?.users,
        stageData: latestStage,
        latestHarvest,
        allHarvests: clusterHarvests,
        allStageData: stageData,
        riskLevel: risk.level,
        priority: risk.priority,
        yieldDecline: latestStage.pre_yield_kg > 0
          ? (((latestStage.pre_yield_kg - (latestHarvest.yield_kg || 0)) / latestStage.pre_yield_kg) * 100).toFixed(1)
          : 0,
      }
    })

    // Calculate aggregated stats
    const stats = {
      totalFarmers: users?.length || 0,
      totalFarms: farms?.length || 0,
      totalClusters: clusters?.length || 0,
    }

    // Aggregate yields from harvest records
    let totalYield = 0
    let totalPredicted = 0
    let totalPrevious = 0
    let gradeFine = 0
    let gradePremium = 0
    let gradeCommercial = 0

    processedClusters.forEach(cluster => {
      const harvests = cluster.allHarvests || []
      harvests.forEach(h => {
        totalYield += parseFloat(h.yield_kg) || 0
        gradeFine += parseFloat(h.grade_fine) || 0
        gradePremium += parseFloat(h.grade_premium) || 0
        gradeCommercial += parseFloat(h.grade_commercial) || 0
      })

      const stageData = cluster.allStageData || []
      stageData.forEach(sd => {
        totalPredicted += parseFloat(sd.predicted_yield) || 0
        totalPrevious += parseFloat(sd.pre_yield_kg) || 0
      })
    })

    stats.actualYield = Math.round(totalYield)
    stats.predictedYield = Math.round(totalPredicted)
    stats.previousYield = Math.round(totalPrevious)
    stats.gradeFine = Math.round(gradeFine)
    stats.gradePremium = Math.round(gradePremium)
    stats.gradeCommercial = Math.round(gradeCommercial)

    // Build yield trends by season
    const seasonMap = {}
    ;(harvests || []).forEach(h => {
      const season = h.season || 'Unknown'
      if (!seasonMap[season]) {
        seasonMap[season] = { actual: 0, fine: 0, premium: 0, commercial: 0, count: 0 }
      }
      seasonMap[season].actual += parseFloat(h.yield_kg) || 0
      seasonMap[season].fine += parseFloat(h.grade_fine) || 0
      seasonMap[season].premium += parseFloat(h.grade_premium) || 0
      seasonMap[season].commercial += parseFloat(h.grade_commercial) || 0
      seasonMap[season].count++
    })

    // Add predicted yields by season from stage data
    processedClusters.forEach(cluster => {
      const stageData = cluster.allStageData || []
      stageData.forEach(sd => {
        const season = sd.season || 'Unknown'
        if (!seasonMap[season]) {
          seasonMap[season] = { actual: 0, fine: 0, premium: 0, commercial: 0, count: 0, predicted: 0 }
        }
        seasonMap[season].predicted = (seasonMap[season].predicted || 0) + (parseFloat(sd.predicted_yield) || 0)
      })
    })

    const yieldTrends = Object.entries(seasonMap)
      .map(([season, vals]) => ({
        season,
        actual: Math.round(vals.actual),
        predicted: Math.round(vals.predicted || 0),
        fine: Math.round(vals.fine),
        premium: Math.round(vals.premium),
        commercial: Math.round(vals.commercial),
        avgYield: vals.count > 0 ? Math.round(vals.actual / vals.count) : 0,
      }))
      .sort((a, b) => a.season.localeCompare(b.season))

    return {
      users,
      farms,
      clusters: processedClusters,
      harvests,
      stats,
      yieldTrends,
    }
  } catch (error) {
    console.error('Error fetching admin analytics:', error)
    throw error
  }
}

// Fetch farm-specific analytics for a farmer
export async function fetchFarmerAnalytics(userId) {
  try {
    if (!userId) throw new Error('User ID is required')

    // Fetch user's farm
    const { data: farm, error: farmErr } = await supabase
      .from('farms')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle()

    if (farmErr) throw farmErr
    if (!farm) return null

    // Fetch clusters for this farm
    const { data: clusters, error: clustersErr } = await supabase
      .from('clusters')
      .select('*, cluster_stage_data(*)')
      .eq('farm_id', farm.id)
      .order('created_at', { ascending: true })

    if (clustersErr) throw clustersErr

    // Get cluster IDs for harvest records
    const clusterIds = (clusters || []).map(c => c.id)

    // Fetch harvest records for these clusters
    const { data: harvests, error: harvestsErr } = await supabase
      .from('harvest_records')
      .select('*')
      .in('cluster_id', clusterIds.length > 0 ? clusterIds : ['00000000-0000-0000-0000-000000000000'])
      .order('actual_harvest_date', { ascending: true })

    if (harvestsErr) throw harvestsErr

    // Process clusters with analytics
    const processedClusters = (clusters || []).map(cluster => {
      const stageData = cluster.cluster_stage_data || []
      const latestStage = stageData.sort((a, b) =>
        new Date(b.created_at) - new Date(a.created_at)
      )[0] || {}

      const clusterHarvests = (harvests || []).filter(h => h.cluster_id === cluster.id)
      const latestHarvest = clusterHarvests.sort((a, b) =>
        new Date(b.actual_harvest_date) - new Date(a.actual_harvest_date)
      )[0] || {}

      const risk = getRiskLevel(
        parseFloat(latestHarvest.yield_kg) || 0,
        parseFloat(latestStage.pre_yield_kg) || 0
      )

      return {
        ...cluster,
        stageData: latestStage,
        latestHarvest,
        allHarvests: clusterHarvests,
        allStageData: stageData,
        riskLevel: risk.level,
        priority: risk.priority,
        yieldStatus: getYieldStatus(
          parseFloat(latestHarvest.yield_kg) || 0,
          parseFloat(latestStage.pre_yield_kg) || 0
        ),
        yieldDecline: latestStage.pre_yield_kg > 0
          ? (((latestStage.pre_yield_kg - (latestHarvest.yield_kg || 0)) / latestStage.pre_yield_kg) * 100).toFixed(1)
          : 0,
      }
    })

    // Calculate farm stats
    let totalYield = 0
    let totalPredicted = 0
    let totalPrevious = 0
    let gradeFine = 0
    let gradePremium = 0
    let gradeCommercial = 0

    processedClusters.forEach(cluster => {
      const harvests = cluster.allHarvests || []
      harvests.forEach(h => {
        totalYield += parseFloat(h.yield_kg) || 0
        gradeFine += parseFloat(h.grade_fine) || 0
        gradePremium += parseFloat(h.grade_premium) || 0
        gradeCommercial += parseFloat(h.grade_commercial) || 0
      })

      const stageData = cluster.allStageData || []
      stageData.forEach(sd => {
        totalPredicted += parseFloat(sd.predicted_yield) || 0
        totalPrevious += parseFloat(sd.pre_yield_kg) || 0
      })
    })

    const stats = {
      totalClusters: clusters?.length || 0,
      totalTrees: (clusters || []).reduce((sum, c) => sum + (c.plant_count || 0), 0),
      actualYield: Math.round(totalYield),
      predictedYield: Math.round(totalPredicted),
      previousYield: Math.round(totalPrevious),
      gradeFine: Math.round(gradeFine),
      gradePremium: Math.round(gradePremium),
      gradeCommercial: Math.round(gradeCommercial),
    }

    // Build yield trends by season for this farm
    const seasonMap = {}
    ;(harvests || []).forEach(h => {
      const season = h.season || 'Unknown'
      if (!seasonMap[season]) {
        seasonMap[season] = { actual: 0, fine: 0, premium: 0, commercial: 0, count: 0, predicted: 0 }
      }
      seasonMap[season].actual += parseFloat(h.yield_kg) || 0
      seasonMap[season].fine += parseFloat(h.grade_fine) || 0
      seasonMap[season].premium += parseFloat(h.grade_premium) || 0
      seasonMap[season].commercial += parseFloat(h.grade_commercial) || 0
      seasonMap[season].count++
    })

    // Add predicted from stage data
    processedClusters.forEach(cluster => {
      const stageData = cluster.allStageData || []
      stageData.forEach(sd => {
        const season = sd.season || 'Unknown'
        if (!seasonMap[season]) {
          seasonMap[season] = { actual: 0, fine: 0, premium: 0, commercial: 0, count: 0, predicted: 0 }
        }
        seasonMap[season].predicted += parseFloat(sd.predicted_yield) || 0
      })
    })

    const yieldTrends = Object.entries(seasonMap)
      .map(([season, vals]) => ({
        season,
        actual: Math.round(vals.actual),
        predicted: Math.round(vals.predicted || 0),
        fine: Math.round(vals.fine),
        premium: Math.round(vals.premium),
        commercial: Math.round(vals.commercial),
        avgYield: vals.count > 0 ? Math.round(vals.actual / vals.count) : 0,
      }))
      .sort((a, b) => a.season.localeCompare(b.season))

    // Get unique seasons
    const seasons = [...new Set([
      ...Object.keys(seasonMap),
      ...(clusters || []).flatMap(c => 
        (c.cluster_stage_data || []).map(sd => sd.season)
      ).filter(Boolean)
    ])].sort()

    return {
      farm,
      clusters: processedClusters,
      harvests,
      stats,
      yieldTrends,
      seasons,
    }
  } catch (error) {
    console.error('Error fetching farmer analytics:', error)
    throw error
  }
}

// Generate recommendations based on cluster data
export function generateRecommendations(cluster) {
  const recs = []
  const stageData = cluster.stageData || cluster.cluster_stage_data?.[0] || {}

  const RECOMMENDATIONS = [
    {
      field: 'soil_ph',
      check: (val) => {
        const v = parseFloat(val)
        if (isNaN(v)) return null
        if (v < ROBUSTA_IDEALS.soil_ph.min) return {
          recommendation: `Soil pH too low (${v}) → Apply agricultural lime to raise pH toward ${ROBUSTA_IDEALS.soil_ph.min}–${ROBUSTA_IDEALS.soil_ph.max}.`,
          priority: 'High',
          ideal: `${ROBUSTA_IDEALS.soil_ph.min}–${ROBUSTA_IDEALS.soil_ph.max}`,
        }
        if (v > ROBUSTA_IDEALS.soil_ph.max) return {
          recommendation: `Soil pH too high (${v}) → Apply sulfur amendments to lower pH toward ${ROBUSTA_IDEALS.soil_ph.min}–${ROBUSTA_IDEALS.soil_ph.max}.`,
          priority: 'High',
          ideal: `${ROBUSTA_IDEALS.soil_ph.min}–${ROBUSTA_IDEALS.soil_ph.max}`,
        }
        return null
      },
    },
    {
      field: 'avg_temp_c',
      check: (val) => {
        const v = parseFloat(val)
        if (isNaN(v)) return null
        if (v < ROBUSTA_IDEALS.avg_temp_c.min) return {
          recommendation: `Temperature below optimum (${v}°C) → Consider windbreaks; monitor frost risk.`,
          priority: 'Medium',
          ideal: `${ROBUSTA_IDEALS.avg_temp_c.min}–${ROBUSTA_IDEALS.avg_temp_c.max}°C`,
        }
        if (v > ROBUSTA_IDEALS.avg_temp_c.max) return {
          recommendation: `Temperature above optimum (${v}°C) → Increase shade tree cover to cool canopy.`,
          priority: 'Medium',
          ideal: `${ROBUSTA_IDEALS.avg_temp_c.min}–${ROBUSTA_IDEALS.avg_temp_c.max}°C`,
        }
        return null
      },
    },
    {
      field: 'avg_rainfall_mm',
      check: (val) => {
        const v = parseFloat(val)
        if (isNaN(v)) return null
        if (v < ROBUSTA_IDEALS.avg_rainfall_mm.min) return {
          recommendation: `Rainfall below optimum (${v}mm) → Supplement with irrigation during dry months.`,
          priority: 'Medium',
          ideal: `${ROBUSTA_IDEALS.avg_rainfall_mm.min}–${ROBUSTA_IDEALS.avg_rainfall_mm.max}mm`,
        }
        if (v > ROBUSTA_IDEALS.avg_rainfall_mm.max) return {
          recommendation: `Rainfall above optimum (${v}mm) → Improve drainage; monitor fungal disease risk.`,
          priority: 'Medium',
          ideal: `${ROBUSTA_IDEALS.avg_rainfall_mm.min}–${ROBUSTA_IDEALS.avg_rainfall_mm.max}mm`,
        }
        return null
      },
    },
    {
      field: 'avg_humidity_pct',
      check: (val) => {
        const v = parseFloat(val)
        if (isNaN(v)) return null
        if (v < ROBUSTA_IDEALS.avg_humidity_pct.min) return {
          recommendation: `Humidity too low (${v}%) → Mulch around base; add shade trees.`,
          priority: 'Medium',
          ideal: `${ROBUSTA_IDEALS.avg_humidity_pct.min}–${ROBUSTA_IDEALS.avg_humidity_pct.max}%`,
        }
        if (v > ROBUSTA_IDEALS.avg_humidity_pct.max) return {
          recommendation: `Humidity too high (${v}%) → Improve airflow; apply preventive fungicide.`,
          priority: 'Medium',
          ideal: `${ROBUSTA_IDEALS.avg_humidity_pct.min}–${ROBUSTA_IDEALS.avg_humidity_pct.max}%`,
        }
        return null
      },
    },
    {
      field: 'pruning_interval_months',
      check: (val) => {
        const v = parseFloat(val)
        if (isNaN(v)) return null
        if (v > ROBUSTA_IDEALS.pruning_interval_months.max) return {
          recommendation: `Pruning overdue (${v} months) → Prune immediately after harvest for vigour.`,
          priority: 'High',
          ideal: `${ROBUSTA_IDEALS.pruning_interval_months.min}–${ROBUSTA_IDEALS.pruning_interval_months.max} months`,
        }
        if (v < ROBUSTA_IDEALS.pruning_interval_months.min) return {
          recommendation: `Pruning too frequent (${v} months) → Allow full recovery between cycles.`,
          priority: 'High',
          ideal: `${ROBUSTA_IDEALS.pruning_interval_months.min}–${ROBUSTA_IDEALS.pruning_interval_months.max} months`,
        }
        return null
      },
    },
    {
      field: 'bean_moisture',
      check: (val) => {
        const v = parseFloat(val)
        if (isNaN(v)) return null
        if (v < ROBUSTA_IDEALS.bean_moisture.min) return {
          recommendation: `Bean moisture too low (${v}%) → Review drying duration; risk of brittle beans.`,
          priority: 'High',
          ideal: `${ROBUSTA_IDEALS.bean_moisture.min}–${ROBUSTA_IDEALS.bean_moisture.max}%`,
        }
        if (v > ROBUSTA_IDEALS.bean_moisture.max) return {
          recommendation: `Bean moisture too high (${v}%) → Extend drying; risk of mould and grade downgrade.`,
          priority: 'High',
          ideal: `${ROBUSTA_IDEALS.bean_moisture.min}–${ROBUSTA_IDEALS.bean_moisture.max}%`,
        }
        return null
      },
    },
    {
      field: 'fertilizer_frequency',
      check: (val) => {
        if (!val || val === 'never') return {
          recommendation: 'No fertilizer application → Establish fertilization schedule with NPK or organic compost.',
          priority: 'High',
          ideal: 'At least sometimes (1-2x/year)',
        }
        if (val === 'rarely') return {
          recommendation: 'Fertilizer too infrequent → Increase to at least 1×/year (sometimes).',
          priority: 'Medium',
          ideal: 'At least sometimes (1-2x/year)',
        }
        return null
      },
    },
    {
      field: 'pesticide_frequency',
      check: (val) => {
        if (!val || val === 'never') return {
          recommendation: 'No pesticide applied → Establish a pest monitoring schedule.',
          priority: 'Low',
          ideal: 'At least rarely for pest prevention',
        }
        return null
      },
    },
    {
      field: 'shade_tree_present',
      check: (val) => {
        if (val === false || val === 'false' || val === 'No') return {
          recommendation: 'No shade trees → Plant Madre de Cacao or banana to improve grade quality and moisture retention.',
          priority: 'Medium',
          ideal: 'Present',
        }
        return null
      },
    },
  ]

  RECOMMENDATIONS.forEach(({ field, check }) => {
    const result = check(stageData[field])
    if (result) {
      recs.push({
        factor: field.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
        value: stageData[field],
        ...result,
        clusterName: cluster.cluster_name,
        clusterId: cluster.id,
      })
    }
  })

  return recs
}

// Export data to CSV
export function exportToCSV(data, filename) {
  if (!data || data.length === 0) return

  const headers = Object.keys(data[0])
  const csvContent = [
    headers.join(','),
    ...data.map(row =>
      headers.map(h => {
        const val = row[h]
        if (val === null || val === undefined) return ''
        if (typeof val === 'string' && (val.includes(',') || val.includes('"'))) {
          return `"${val.replace(/"/g, '""')}"`
        }
        return val
      }).join(',')
    ),
  ].join('\n')

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = filename
  link.click()
  URL.revokeObjectURL(link.href)
}
