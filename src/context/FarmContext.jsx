import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import { supabase } from '../lib/supabase'
import { useAuth } from './AuthContext'

const FarmContext = createContext(null)

export function FarmProvider({ children }) {
  const { user, authUser } = useAuth()
  const [farm, setFarm] = useState(null)
  const [clusters, setClusters] = useState([])
  const [loading, setLoading] = useState(false)

  // ── Fetch farm + clusters when user logs in ──────────────────
  const fetchFarmData = useCallback(async () => {
    if (!authUser) {
      setFarm(null)
      setClusters([])
      setLoading(false)
      return
    }
    
    try {
      setLoading(true)

      // Get user's farm — use maybeSingle() so no error if row doesn't exist yet
      const { data: farmRow, error: farmErr } = await supabase
        .from('farms')
        .select('*')
        .eq('user_id', authUser.id)
        .maybeSingle()

      if (farmErr) {
        console.error('Error fetching farm:', farmErr.message)
        setLoading(false)
        return
      }

      if (farmRow) {
        setFarm(farmRow)

        // Get clusters for this farm
        const { data: clusterRows, error: clusterErr } = await supabase
          .from('clusters')
          .select('*, cluster_stage_data(*)')
          .eq('farm_id', farmRow.id)
          .order('created_at', { ascending: true })

        if (clusterErr) {
          console.error('Error fetching clusters:', clusterErr.message)
          setClusters([])
        } else {
          setClusters(
            (clusterRows || []).map((c) => ({
              id: c.id,
              clusterName: c.cluster_name,
              areaSize: c.area_size_sqm,
              plantCount: c.plant_count,
              plantStage: c.plant_stage,
              createdAt: c.created_at,
              variety: c.variety,
              stageData: c.cluster_stage_data?.[0]
                ? mapStageDataFromDb(c.cluster_stage_data[0])
                : null,
              harvestRecords: [], // loaded on demand
            }))
          )
        }
      } else {
        // Auto-create a farm row for the user so clusters can be added
        const { data: newFarm, error: createErr } = await supabase
          .from('farms')
          .insert({ user_id: authUser.id, farm_name: 'My Farm' })
          .select()
          .single()
        
        if (createErr) {
          console.error('Error creating farm:', createErr.message)
        } else {
          setFarm(newFarm)
        }
        setClusters([])
      }
    } catch (err) {
      console.error('fetchFarmData error:', err)
    } finally {
      setLoading(false)
    }
  }, [authUser])

  useEffect(() => {
    fetchFarmData()
  }, [fetchFarmData])

  // ── Farm info update ──────────────────────────────────────────
  const setFarmInfo = async (farmData) => {
    if (!farm) return
    const { data } = await supabase
      .from('farms')
      .update({
        farm_name: farmData.farmName,
        farm_area: farmData.farmArea || null,
        elevation_m: farmData.elevation || null,
        overall_tree_count: farmData.overallTreeCount || null,
      })
      .eq('id', farm.id)
      .select()
      .single()
    if (data) setFarm(data)
  }

  // ── Add cluster ───────────────────────────────────────────────
  const addCluster = async (cluster) => {
    if (!farm) return null
    const { data, error } = await supabase
      .from('clusters')
      .insert({
        farm_id: farm.id,
        cluster_name: cluster.clusterName,
        area_size_sqm: cluster.areaSize,
        plant_count: cluster.plantCount,
        plant_stage: cluster.plantStage,
        variety: cluster.variety || null,
      })
      .select()
      .single()

    if (error) {
      console.error('Error adding cluster:', error.message)
      return null
    }

    const newCluster = {
      id: data.id,
      clusterName: data.cluster_name,
      areaSize: data.area_size_sqm,
      plantCount: data.plant_count,
      plantStage: data.plant_stage,
      variety: data.variety,
      createdAt: data.created_at,
      stageData: null,
      harvestRecords: [],
    }
    setClusters((prev) => [...prev, newCluster])
    return newCluster
  }

  // ── Update cluster (basic fields + stage data) ────────────────
  const updateCluster = async (clusterId, updates) => {
    // Update basic cluster fields if present
    const basicFields = {}
    if (updates.clusterName !== undefined) basicFields.cluster_name = updates.clusterName
    if (updates.areaSize !== undefined) basicFields.area_size_sqm = updates.areaSize
    if (updates.plantCount !== undefined) basicFields.plant_count = updates.plantCount
    if (updates.plantStage !== undefined) basicFields.plant_stage = updates.plantStage
    if (updates.variety !== undefined) basicFields.variety = updates.variety

    if (Object.keys(basicFields).length > 0) {
      await supabase.from('clusters').update(basicFields).eq('id', clusterId)
    }

    // Upsert stage data if present
    if (updates.stageData) {
      const dbStageData = mapStageDataToDb(updates.stageData)
      dbStageData.cluster_id = clusterId

      await supabase
        .from('cluster_stage_data')
        .upsert(dbStageData, { onConflict: 'cluster_id,season' })
    }

    // Update local state
    setClusters((prev) =>
      prev.map((c) =>
        c.id === clusterId
          ? {
              ...c,
              ...(updates.clusterName !== undefined && { clusterName: updates.clusterName }),
              ...(updates.areaSize !== undefined && { areaSize: updates.areaSize }),
              ...(updates.plantCount !== undefined && { plantCount: updates.plantCount }),
              ...(updates.plantStage !== undefined && { plantStage: updates.plantStage }),
              ...(updates.stageData !== undefined && { stageData: updates.stageData }),
            }
          : c
      )
    )
  }

  // ── Delete cluster ────────────────────────────────────────────
  const deleteCluster = async (clusterId) => {
    await supabase.from('clusters').delete().eq('id', clusterId)
    setClusters((prev) => prev.filter((c) => c.id !== clusterId))
  }

  // ── Add harvest record ────────────────────────────────────────
  const addHarvestRecord = async (clusterId, record) => {
    const { data, error } = await supabase
      .from('harvest_records')
      .insert({
        cluster_id: clusterId,
        season: record.season || null,
        yield_kg: record.yieldKg != null ? [record.yieldKg] : null,
        grade_fine: record.gradeFine != null ? [record.gradeFine] : null,
        grade_premium: record.gradePremium != null ? [record.gradePremium] : null,
        grade_commercial: record.gradeCommercial != null ? [record.gradeCommercial] : null,
        fine_pct: record.finePct != null ? [record.finePct] : null,
        premium_pct: record.premiumPct != null ? [record.premiumPct] : null,
        commercial_pct: record.commercialPct != null ? [record.commercialPct] : null,
        notes: record.notes ? [record.notes] : null,
      })
      .select()
      .single()

    if (error) {
      console.error('Error adding harvest record:', error.message)
      return
    }

    setClusters((prev) =>
      prev.map((c) =>
        c.id === clusterId
          ? { ...c, harvestRecords: [...(c.harvestRecords || []), data] }
          : c
      )
    )
  }

  // ── Helpers ───────────────────────────────────────────────────
  const getCluster = (clusterId) => clusters.find((c) => c.id === clusterId)

  const getAllClusters = () => {
    return clusters.map((c) => ({ ...c, farmName: farm?.farm_name || 'My Farm' }))
  }

  const getHarvestReadyClusters = () => {
    return getAllClusters().filter((c) =>
      ['ready-to-harvest', 'flowering', 'fruit-bearing'].includes(c.plantStage)
    )
  }

  return (
    <FarmContext.Provider
      value={{
        farm,
        setFarmInfo,
        clusters,
        loading,
        addCluster,
        updateCluster,
        deleteCluster,
        addHarvestRecord,
        getCluster,
        getAllClusters,
        getHarvestReadyClusters,
        refreshData: fetchFarmData,
      }}
    >
      {children}
    </FarmContext.Provider>
  )
}

export function useFarm() {
  const context = useContext(FarmContext)
  if (!context) throw new Error('useFarm must be used within FarmProvider')
  return context
}

// ── DB ↔ JS field mapping helpers ─────────────────────────────

function mapStageDataFromDb(row) {
  return {
    season: row.season || '',
    datePlanted: row.date_planted || '',
    plantAgeMonths: row.plant_age_months ?? '',
    numberOfPlants: row.number_of_plants ?? '',
    fertilizerType: row.fertilizer_type || '',
    fertilizerFrequency: row.fertilizer_frequency || '',
    pesticideType: row.pesticide_type || '',
    pesticideFrequency: row.pesticide_frequency || '',
    lastPrunedDate: row.last_pruned_date || '',
    previousPrunedDate: row.previous_pruned_date || '',
    pruningIntervalMonths: row.pruning_interval_months ?? '',
    shadeTreePresent: row.shade_tree_present ?? false,
    shadeTreeSpecies: row.shade_tree_species || '',
    soilPh: row.soil_ph ?? '',
    avgTempC: row.avg_temp_c ?? '',
    avgRainfallMm: row.avg_rainfall_mm ?? '',
    avgHumidityPct: row.avg_humidity_pct ?? '',
    actualFloweringDate: row.actual_flowering_date || '',
    estimatedFloweringDate: row.estimated_flowering_date || '',
    estimatedHarvestDate: row.estimated_harvest_date || '',
    actualHarvestDate: row.actual_harvest_date || '',
    preLastHarvestDate: row.pre_last_harvest_date || '',
    preTotalTrees: row.pre_total_trees ?? '',
    preYieldKg: row.pre_yield_kg ?? '',
    preGradeFine: row.pre_grade_fine ?? '',
    preGradePremium: row.pre_grade_premium ?? '',
    preGradeCommercial: row.pre_grade_commercial ?? '',
    previousFinePct: row.previous_fine_pct ?? '',
    previousPremiumPct: row.previous_premium_pct ?? '',
    previousCommercialPct: row.previous_commercial_pct ?? '',
    defectCount: row.defect_count ?? '',
    beanMoisture: row.bean_moisture ?? '',
    beanScreenSize: row.bean_screen_size || '',
    predictedYield: row.predicted_yield ?? '',
  }
}

function mapStageDataToDb(sd) {
  const num = (v) => (v === '' || v === null || v === undefined ? null : parseFloat(v))
  const int = (v) => (v === '' || v === null || v === undefined ? null : parseInt(v))
  const str = (v) => (v === '' ? null : v || null)
  const dt = (v) => (v === '' ? null : v || null)
  const bool = (v) => (v === true || v === 'true' || v === 'Yes' || v === 'yes' ? true : false)

  return {
    season: str(sd.season),
    date_planted: dt(sd.datePlanted),
    plant_age_months: int(sd.plantAgeMonths),
    number_of_plants: int(sd.numberOfPlants),
    fertilizer_type: str(sd.fertilizerType),
    fertilizer_frequency: str(sd.fertilizerFrequency),
    pesticide_type: str(sd.pesticideType),
    pesticide_frequency: str(sd.pesticideFrequency),
    last_pruned_date: dt(sd.lastPrunedDate),
    previous_pruned_date: dt(sd.previousPrunedDate),
    pruning_interval_months: int(sd.pruningIntervalMonths),
    shade_tree_present: bool(sd.shadeTreePresent),
    shade_tree_species: str(sd.shadeTreeSpecies),
    soil_ph: num(sd.soilPh),
    avg_temp_c: num(sd.avgTempC),
    avg_rainfall_mm: num(sd.avgRainfallMm),
    avg_humidity_pct: num(sd.avgHumidityPct),
    actual_flowering_date: dt(sd.actualFloweringDate),
    estimated_flowering_date: dt(sd.estimatedFloweringDate),
    estimated_harvest_date: dt(sd.estimatedHarvestDate),
    actual_harvest_date: dt(sd.actualHarvestDate),
    pre_last_harvest_date: dt(sd.preLastHarvestDate),
    pre_total_trees: int(sd.preTotalTrees),
    pre_yield_kg: num(sd.preYieldKg),
    pre_grade_fine: num(sd.preGradeFine),
    pre_grade_premium: num(sd.preGradePremium),
    pre_grade_commercial: num(sd.preGradeCommercial),
    previous_fine_pct: num(sd.previousFinePct),
    previous_premium_pct: num(sd.previousPremiumPct),
    previous_commercial_pct: num(sd.previousCommercialPct),
    defect_count: int(sd.defectCount),
    bean_moisture: num(sd.beanMoisture),
    bean_screen_size: str(sd.beanScreenSize),
    predicted_yield: num(sd.predictedYield),
  }
}
