import { useEffect, useMemo, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, Save } from 'lucide-react'
import { useFarm } from '../../context/FarmContext'
import './ClusterDetail.css'

const STAGE_OPTIONS = [
  { value: 'seed-sapling', label: 'Seed / Sapling' },
  { value: 'tree', label: 'Tree' },
  { value: 'flowering', label: 'Flowering / Fruit-bearing' },
  { value: 'ready-to-harvest', label: 'Ready to Harvest' },
]

const SECTION_FIELDS = {
  overview: [
    { name: 'datePlanted', label: 'Date Planted', type: 'date' },
    { name: 'numberOfPlants', label: 'Number of Plants', type: 'number' },
    { name: 'variety', label: 'Variety', type: 'text' },
    { name: 'monthlyTemperature', label: 'Monthly Temperature (deg C)', type: 'number' },
    { name: 'rainfall', label: 'Monthly Rainfall (mm)', type: 'number' },
    { name: 'humidity', label: 'Monthly Humidity (%)', type: 'number' },
    { name: 'soilPh', label: 'Soil pH', type: 'number', step: '0.1' },
  ],
  harvest: [
    { name: 'lastHarvestedDate', label: 'Last Harvested Date', type: 'date' },
    { name: 'harvestDate', label: 'Harvest Date', type: 'date' },
    { name: 'estimatedHarvestDate', label: 'Estimated Harvest Date', type: 'date' },
    { name: 'harvestSeason', label: 'Harvest Season', type: 'text' },
    { name: 'previousYield', label: 'Previous Yield (kg)', type: 'number' },
    { name: 'predictedYield', label: 'Predicted Yield (kg)', type: 'number' },
    { name: 'currentYield', label: 'Current Harvest (kg)', type: 'number' },
    { name: 'gradeFine', label: 'Grade Fine (%)', type: 'number' },
    { name: 'gradePremium', label: 'Grade Premium (%)', type: 'number' },
    { name: 'gradeCommercial', label: 'Grade Commercial (%)', type: 'number' },
    { name: 'preLastHarvestDate', label: 'Previous Last Harvest Date', type: 'date' },
    { name: 'preTotalTrees', label: 'Previous Total Trees', type: 'number' },
    { name: 'preYieldKg', label: 'Previous Yield (kg)', type: 'number' },
    { name: 'preGradeFine', label: 'Previous Fine Grade (kg)', type: 'number' },
    { name: 'preGradePremium', label: 'Previous Premium Grade (kg)', type: 'number' },
    { name: 'preGradeCommercial', label: 'Previous Commercial Grade (kg)', type: 'number' },
    { name: 'postCurrentYield', label: 'Predicted Yield (kg)', type: 'number' },
    { name: 'postGradeFine', label: 'Predicted Fine (%)', type: 'number' },
    { name: 'postGradePremium', label: 'Predicted Premium (%)', type: 'number' },
    { name: 'postGradeCommercial', label: 'Predicted Commercial (%)', type: 'number' },
    { name: 'defectCount', label: 'Defect Count', type: 'number' },
    { name: 'beanMoisture', label: 'Bean Moisture (%)', type: 'number' },
    { name: 'beanScreenSize', label: 'Bean Screen Size', type: 'text' },
  ],
  pruning: [
    { name: 'lastPrunedDate', label: 'Last Pruned Date', type: 'date' },
    { name: 'shadeTrees', label: 'Shade Trees', type: 'select', options: ['Yes', 'No'] },
  ],
  fertilize: [
    { name: 'fertilizerFrequency', label: 'Fertilizer Frequency', type: 'text' },
    { name: 'fertilizerType', label: 'Fertilizer Type', type: 'text' },
    { name: 'soilPh', label: 'Soil pH', type: 'number', step: '0.1' },
  ],
  pesticide: [
    { name: 'pesticideType', label: 'Pesticide Type', type: 'text' },
    { name: 'pesticideFrequency', label: 'Pesticide Frequency', type: 'text' },
  ],
}

const SECTION_TITLES = {
  overview: 'Overview',
  harvest: 'Harvest',
  pruning: 'Pruning',
  fertilize: 'Fertilize',
  pesticide: 'Pesticide',
}

function formatDateLocal(date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export default function ClusterDetail() {
  const { clusterId, section = 'overview' } = useParams()
  const navigate = useNavigate()
  const { getCluster, updateCluster } = useFarm()
  const cluster = getCluster(clusterId)
  const [form, setForm] = useState({})
  const [saving, setSaving] = useState(false)
  const isHarvestSection = section === 'harvest'
  const isReadyToHarvest = cluster?.plantStage === 'ready-to-harvest'
  const isHarvestLocked = isHarvestSection && !isReadyToHarvest

  const fields = useMemo(() => SECTION_FIELDS[section] || [], [section])

  useEffect(() => {
    if (!SECTION_FIELDS[section]) {
      navigate(`/clusters/${clusterId}/overview`, { replace: true })
      return
    }
    const nextForm = {}
    fields.forEach((field) => {
      nextForm[field.name] = cluster?.stageData?.[field.name] ?? ''
    })
    setForm(nextForm)
  }, [cluster, clusterId, fields, navigate, section])

  if (!cluster) {
    return (
      <div className="cluster-detail-page">
        <button className="back-btn" onClick={() => navigate('/dashboard')}>
          <ArrowLeft size={18} /> Back to Dashboard
        </button>
        <div className="empty-state">
          <h3>Cluster not found</h3>
        </div>
      </div>
    )
  }

  const handleFieldChange = (e) => {
    setForm((prev) => ({ ...prev, [e.target.name]: e.target.value }))
  }

  const handleStageChange = async (e) => {
    const nextStage = e.target.value
    const updates = { plantStage: nextStage }

    // When cluster enters flowering stage, auto-compute estimated harvest date (+11 months).
    if (nextStage === 'flowering') {
      const now = new Date()
      const estimate = new Date(now.getFullYear(), now.getMonth() + 11, now.getDate())
      updates.stageData = {
        ...(cluster.stageData || {}),
        estimatedHarvestDate: formatDateLocal(estimate),
      }
    }

    await updateCluster(cluster.id, updates)
  }

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    await updateCluster(cluster.id, {
      stageData: {
        ...(cluster.stageData || {}),
        ...form,
      },
    })
    setSaving(false)
  }

  return (
    <div className="cluster-detail-page">
      <div className="cd-header">
        <button className="back-btn" onClick={() => navigate('/dashboard')}>
          <ArrowLeft size={18} /> Back
        </button>
        <div className="cd-title">
          <h1>{cluster.clusterName}</h1>
          <p>Area: {cluster.areaSize} ha | Plants: {cluster.plantCount}</p>
        </div>
        <div className="cd-stage">
          <label>Plant Stage</label>
          <select value={cluster.plantStage} onChange={handleStageChange}>
            {STAGE_OPTIONS.map((stage) => (
              <option key={stage.value} value={stage.value}>
                {stage.label}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div className="cd-card">
        <h2>{SECTION_TITLES[section]}</h2>
        {isHarvestLocked && (
          <p className="cd-lock-note">
            Harvest form is disabled. Change cluster stage to Ready to Harvest to enable input.
          </p>
        )}
        <form className="cd-form" onSubmit={handleSave}>
          <div className="cd-form-grid">
            {fields.map((field) => (
              <div className="form-group" key={field.name}>
                <label>{field.label}</label>
                {field.type === 'select' ? (
                  <select
                    name={field.name}
                    value={form[field.name] ?? ''}
                    onChange={handleFieldChange}
                    disabled={isHarvestLocked}
                  >
                    <option value="">Select...</option>
                    {field.options.map((opt) => (
                      <option key={opt} value={opt}>
                        {opt}
                      </option>
                    ))}
                  </select>
                ) : (
                  <input
                    name={field.name}
                    type={field.type}
                    step={field.step}
                    value={form[field.name] ?? ''}
                    onChange={handleFieldChange}
                    placeholder={field.label}
                    disabled={isHarvestLocked}
                  />
                )}
              </div>
            ))}
          </div>
          <div className="cd-actions">
            <button type="submit" className="cd-save-btn" disabled={saving || isHarvestLocked}>
              <Save size={16} /> {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}
