import { useState, useEffect } from 'react'
import { useAuth } from '../../context/AuthContext'
import { useFarm } from '../../context/FarmContext'
import {
  Lightbulb,
  AlertTriangle,
  CheckCircle,
  AlertCircle,
  ChevronDown,
  Filter,
  TrendingDown,
  TrendingUp,
  Minus,
  X,
  RefreshCw,
  Download,
} from 'lucide-react'
import { fetchFarmerAnalytics, generateRecommendations, exportToCSV, ROBUSTA_IDEALS } from '../../lib/analyticsService'
import './Recommendations.css'

// Rules engine for identifying issues - enhanced to use DB data
function analyzeCluster(cluster) {
  const issues = []
  const sd = cluster.stageData || {}

  // Check fertilizer
  if (!sd.fertilizerType && !sd.fertilizer_type) {
    issues.push({
      factor: 'Insufficient fertilizer application',
      severity: 'high',
      explanation: 'No fertilizer type has been recorded. Coffee plants require regular fertilization for optimal yield.',
      recommendation: 'Apply NPK (14-14-14) fertilizer at the start of the rainy season. For mature trees, apply 200-300g per tree, 2-3 times per year.',
    })
  }

  // Check pesticide
  const pestFreq = sd.pesticideFrequency || sd.pesticide_frequency
  if (!pestFreq) {
    issues.push({
      factor: 'Lack of pesticide use',
      severity: 'medium',
      explanation: 'No pesticide application frequency recorded. Plants may be vulnerable to pest infestation.',
      recommendation: 'Conduct regular pest scouting. Apply approved insecticides for Coffee Berry Borer (CBB) prevention. Consider integrated pest management (IPM) practices.',
    })
  }

  // Check pruning
  const lastPruned = sd.lastPrunedDate || sd.last_pruned_date
  if (!lastPruned) {
    issues.push({
      factor: 'Delayed or missed pruning',
      severity: 'medium',
      explanation: 'No pruning date recorded. Unpruned trees have reduced air circulation and light penetration.',
      recommendation: 'Prune coffee trees annually after harvest season. Remove dead, diseased, and crossing branches. Maintain optimal canopy shape for light exposure.',
    })
  }

  // Check soil pH
  const pH = parseFloat(sd.soilPh || sd.soil_ph)
  if (pH && (pH < ROBUSTA_IDEALS.soilPh.min || pH > ROBUSTA_IDEALS.soilPh.max)) {
    issues.push({
      factor: 'Extreme or imbalanced soil pH',
      severity: pH < 5.0 || pH > 7.0 ? 'high' : 'medium',
      explanation: `Soil pH is ${pH}. Coffee thrives in slightly acidic soil (pH ${ROBUSTA_IDEALS.soilPh.min}-${ROBUSTA_IDEALS.soilPh.max}). Current pH may affect nutrient uptake.`,
      recommendation: pH < ROBUSTA_IDEALS.soilPh.min
        ? 'Apply agricultural lime to raise soil pH. Test soil every 6 months to monitor changes.'
        : 'Apply sulfur or organic matter to lower soil pH. Ensure proper drainage to prevent alkalinity buildup.',
    })
  }

  // Check shade trees
  const shadeTrees = sd.shadeTrees || sd.shade_trees
  if (shadeTrees === 'No' || shadeTrees === false) {
    issues.push({
      factor: 'Poor shade tree management',
      severity: 'low',
      explanation: 'No shade trees present. Shade trees help regulate temperature and improve bean quality.',
      recommendation: 'Plant shade trees like Madre de Cacao (Gliricidia) or Ipil-Ipil at 6-8m spacing. Maintain 40-60% shade coverage for Arabica varieties.',
    })
  }

  // Check temperature
  const temp = parseFloat(sd.monthlyTemperature || sd.temperature)
  if (temp && (temp < ROBUSTA_IDEALS.temperature.min || temp > ROBUSTA_IDEALS.temperature.max)) {
    issues.push({
      factor: 'Weather or climate stress',
      severity: 'medium',
      explanation: `Monthly temperature is ${temp}°C. Optimal range for coffee is ${ROBUSTA_IDEALS.temperature.min}-${ROBUSTA_IDEALS.temperature.max}°C.`,
      recommendation: temp > ROBUSTA_IDEALS.temperature.max
        ? 'Increase shade coverage. Consider mulching to reduce soil temperature. Plant windbreaks if exposed to hot winds.'
        : 'Protect young plants with covers during cold periods. Avoid planting in frost-prone areas.',
    })
  }

  // Check yield decline
  const prevYield = parseFloat(sd.previousYield || sd.pre_yield_kg)
  const currentYield = parseFloat(sd.currentYield || sd.actual_yield)
  if (prevYield && currentYield && currentYield < prevYield * 0.7) {
    issues.push({
      factor: 'Significant yield decline detected',
      severity: 'high',
      explanation: `Current yield (${currentYield}kg) is significantly lower than previous yield (${prevYield}kg). A decline of more than 30% warrants investigation.`,
      recommendation: 'Conduct comprehensive soil testing. Review fertilizer program. Check for pest and disease presence. Evaluate pruning schedule and plant age.',
    })
  }

  // Check humidity
  const humidity = parseFloat(sd.humidity)
  if (humidity && (humidity < ROBUSTA_IDEALS.humidity.min || humidity > ROBUSTA_IDEALS.humidity.max)) {
    issues.push({
      factor: 'Non-optimal humidity level',
      severity: humidity < 40 || humidity > 85 ? 'high' : 'low',
      explanation: `Average humidity is ${humidity}%. Optimal range for coffee is ${ROBUSTA_IDEALS.humidity.min}–${ROBUSTA_IDEALS.humidity.max}%.`,
      recommendation: humidity < ROBUSTA_IDEALS.humidity.min
        ? 'Increase mulching around plant bases to retain soil moisture. Consider installing shade structures to reduce evaporation.'
        : 'Improve air circulation through pruning. Ensure adequate spacing between trees. Monitor for fungal diseases common in high-humidity conditions.',
    })
  }

  // Check rainfall
  const rainfall = parseFloat(sd.rainfall)
  if (rainfall && (rainfall < ROBUSTA_IDEALS.rainfall.min || rainfall > ROBUSTA_IDEALS.rainfall.max)) {
    issues.push({
      factor: 'Abnormal rainfall levels',
      severity: rainfall < 50 || rainfall > 350 ? 'high' : 'medium',
      explanation: `Monthly rainfall is ${rainfall}mm. Coffee generally needs ${ROBUSTA_IDEALS.rainfall.min}–${ROBUSTA_IDEALS.rainfall.max}mm of monthly rainfall for healthy growth.`,
      recommendation: rainfall < ROBUSTA_IDEALS.rainfall.min
        ? 'Consider supplemental irrigation during dry spells. Apply mulch to conserve soil moisture.'
        : 'Ensure proper drainage to prevent waterlogging and root rot. Check for erosion on slopes.',
    })
  }

  // Check fertilizer frequency
  const fertFreq = sd.fertilizerFrequency || sd.fertilizer_frequency
  if (fertFreq === 'Never' || fertFreq === 'Rarely') {
    issues.push({
      factor: 'Infrequent fertilizer application',
      severity: fertFreq === 'Never' ? 'high' : 'medium',
      explanation: `Fertilizer application is "${fertFreq}". Inadequate fertilization leads to nutrient deficiency and reduced yields.`,
      recommendation: 'Apply fertilizer at least once a year. Recommended schedule: NPK at start of rainy season, and organic compost mid-season. Increase to 3-4 times per year for mature bearing trees.',
    })
  }

  // Check pesticide type missing
  const pestType = sd.pesticideType || sd.pesticide_type
  if (pestFreq && pestFreq !== 'Never' && !pestType) {
    issues.push({
      factor: 'Pesticide type not specified',
      severity: 'low',
      explanation: 'Pesticide application frequency is recorded but the type (Organic/Non-Organic) is not specified.',
      recommendation: 'Record the pesticide type for better tracking. Consider switching to organic pesticides where possible for sustainable farming.',
    })
  }

  return issues
}

function getPerformanceLevel(cluster) {
  const issues = analyzeCluster(cluster)
  const highCount = issues.filter((i) => i.severity === 'high').length
  const medCount = issues.filter((i) => i.severity === 'medium').length

  if (highCount >= 2) return 'poor'
  if (highCount >= 1 || medCount >= 2) return 'moderate'
  return 'good'
}

export default function Recommendations() {
  const { user } = useAuth()
  const { getAllClusters } = useFarm()
  const [performanceFilter, setPerformanceFilter] = useState('')
  const [seasonFilter, setSeasonFilter] = useState('')
  const [selectedCluster, setSelectedCluster] = useState(null)
  const [loading, setLoading] = useState(true)
  const [dbClusters, setDbClusters] = useState([])

  useEffect(() => {
    if (user?.id) {
      fetchData()
    }
  }, [user?.id])

  const fetchData = async () => {
    setLoading(true)
    try {
      const data = await fetchFarmerAnalytics(user.id)
      
      // Process clusters from DB
      const processed = data.clusters?.map(c => {
        const sd = c.stageData || {}
        return {
          id: c.id,
          clusterName: c.cluster_name,
          plantStage: c.plant_stage,
          plantCount: c.plant_count,
          variety: c.variety,
          stageData: {
            variety: c.variety || sd.variety,
            datePlanted: c.date_planted,
            harvestSeason: sd.season,
            predictedYield: sd.predicted_yield,
            currentYield: c.latestHarvest?.yield_kg || 0,
            previousYield: sd.pre_yield_kg,
            temperature: sd.temperature,
            humidity: sd.humidity,
            rainfall: sd.rainfall,
            soil_ph: sd.soil_ph,
            fertilizer_type: sd.fertilizer_type,
            fertilizer_frequency: sd.fertilizer_frequency,
            pesticide_type: sd.pesticide_type,
            pesticide_frequency: sd.pesticide_frequency,
            shade_trees: sd.shade_trees,
            last_pruned_date: sd.last_pruned_date,
          },
        }
      }) || []
      
      setDbClusters(processed)
    } catch (err) {
      console.error('Error fetching data:', err)
    }
    setLoading(false)
  }

  // Combine context and DB clusters
  const contextClusters = getAllClusters()
  const allClusters = dbClusters.length > 0 ? dbClusters : contextClusters
  
  const clustersWithAnalysis = allClusters.map((c) => ({
    ...c,
    issues: analyzeCluster(c),
    performance: getPerformanceLevel(c),
  }))

  // Get unique seasons
  const seasons = [...new Set(allClusters.map((c) => c.stageData?.harvestSeason).filter(Boolean))]

  // Sort by urgency
  const sortOrder = { poor: 0, moderate: 1, good: 2 }
  const sorted = [...clustersWithAnalysis].sort(
    (a, b) => sortOrder[a.performance] - sortOrder[b.performance]
  )

  let filtered = performanceFilter
    ? sorted.filter((c) => c.performance === performanceFilter)
    : sorted

  if (seasonFilter) {
    filtered = filtered.filter((c) => c.stageData?.harvestSeason?.includes(seasonFilter))
  }

  const perfConfig = {
    poor: { label: 'Poor', icon: TrendingDown, color: '#dc2626', bg: '#fef2f2' },
    moderate: { label: 'Moderate', icon: Minus, color: '#d97706', bg: '#fffbeb' },
    good: { label: 'Good', icon: TrendingUp, color: '#16a34a', bg: '#f0fdf4' },
  }

  const severityConfig = {
    high: { label: 'High', icon: AlertCircle, color: '#dc2626' },
    medium: { label: 'Medium', icon: AlertTriangle, color: '#d97706' },
    low: { label: 'Low', icon: Lightbulb, color: '#3b82f6' },
  }

  const poorCount = clustersWithAnalysis.filter((c) => c.performance === 'poor').length
  const moderateCount = clustersWithAnalysis.filter((c) => c.performance === 'moderate').length
  const goodCount = clustersWithAnalysis.filter((c) => c.performance === 'good').length

  const handleExport = () => {
    const exportData = filtered.map(c => ({
      'Cluster': c.clusterName,
      'Stage': c.plantStage,
      'Performance': c.performance,
      'Issues Count': c.issues.length,
      'High Severity': c.issues.filter(i => i.severity === 'high').length,
      'Medium Severity': c.issues.filter(i => i.severity === 'medium').length,
      'Low Severity': c.issues.filter(i => i.severity === 'low').length,
    }))
    exportToCSV(exportData, `recommendations_${new Date().toISOString().split('T')[0]}.csv`)
  }

  if (loading) {
    return (
      <div className="reco-loading">
        <div className="reco-loading-spinner"></div>
        <p>Analyzing clusters...</p>
      </div>
    )
  }

  return (
    <div className="reco-page">
      <div className="reco-header">
        <div>
          <h1>Decision Support & Recommendations</h1>
          <p>Actionable insights to improve yield and farm management</p>
        </div>
        <div className="harvest-filters">
          <button className="reco-refresh-btn" onClick={fetchData}>
            <RefreshCw size={16} /> Refresh
          </button>
          <button className="reco-export-btn" onClick={handleExport}>
            <Download size={16} /> Export
          </button>
          <div className="filter-select">
            <Filter size={16} />
            <select value={seasonFilter} onChange={(e) => setSeasonFilter(e.target.value)}>
              <option value="">All Seasons</option>
              {seasons.map((s) => (
                <option key={s} value={s}>{s}</option>
              ))}
            </select>
            <ChevronDown size={14} />
          </div>
          <div className="filter-select">
            <Filter size={16} />
            <select value={performanceFilter} onChange={(e) => setPerformanceFilter(e.target.value)}>
              <option value="">All Performance</option>
              <option value="poor">Poor / Declining</option>
              <option value="moderate">Moderate</option>
              <option value="good">Good</option>
            </select>
            <ChevronDown size={14} />
          </div>
        </div>
      </div>

      {/* Summary Cards */}
      <div className="reco-summary">
        <div className="reco-sum-card reco-sum-card--critical">
          <AlertCircle size={20} />
          <div>
            <span className="reco-sum-value">{poorCount}</span>
            <span className="reco-sum-label">Critical</span>
          </div>
        </div>
        <div className="reco-sum-card reco-sum-card--moderate">
          <AlertTriangle size={20} />
          <div>
            <span className="reco-sum-value">{moderateCount}</span>
            <span className="reco-sum-label">Moderate Issues</span>
          </div>
        </div>
        <div className="reco-sum-card reco-sum-card--good">
          <CheckCircle size={20} />
          <div>
            <span className="reco-sum-value">{goodCount}</span>
            <span className="reco-sum-label">Performing Well</span>
          </div>
        </div>
      </div>

      {/* Cluster List with Performance */}
      <div className="reco-content">
        <div className="reco-list">
          {filtered.length === 0 ? (
            <div className="reco-empty">
              <Lightbulb size={48} />
              <h3>No clusters to analyze</h3>
              <p>Add clusters to get actionable recommendations</p>
            </div>
          ) : (
            filtered.map((cluster) => {
              const perf = perfConfig[cluster.performance]
              const PerfIcon = perf.icon
              return (
                <div
                  key={cluster.id}
                  className={`reco-item ${selectedCluster?.id === cluster.id ? 'active' : ''}`}
                  onClick={() => setSelectedCluster(cluster)}
                >
                  <div className="reco-item-left">
                    <div
                      className="reco-perf-badge"
                      style={{ background: perf.bg, color: perf.color }}
                    >
                      <PerfIcon size={16} />
                    </div>
                    <div>
                      <h4>{cluster.clusterName}</h4>
                      <span className="reco-farm-name">{cluster.plantStage}</span>
                    </div>
                  </div>
                  <div className="reco-item-right">
                    <span
                      className="reco-perf-label"
                      style={{ color: perf.color }}
                    >
                      {perf.label} Yield
                    </span>
                    <span className="reco-issue-count">
                      {cluster.issues.length} issue{cluster.issues.length !== 1 ? 's' : ''}
                    </span>
                  </div>
                </div>
              )
            })
          )}
        </div>

        {/* Detail Overlay */}
        {selectedCluster && (
          <div className="reco-detail">
            <div className="detail-header">
              <h3>
                <Lightbulb size={18} /> {selectedCluster.clusterName}
              </h3>
              <button className="modal-close" onClick={() => setSelectedCluster(null)}>
                <X size={18} />
              </button>
            </div>

            {selectedCluster.issues.length === 0 ? (
              <div className="reco-no-issues">
                <CheckCircle size={32} />
                <h4>No issues identified</h4>
                <p>This cluster is performing well. Continue current management practices.</p>
              </div>
            ) : (
              <div className="reco-issues">
                {selectedCluster.issues.map((issue, idx) => {
                  const sev = severityConfig[issue.severity]
                  const SevIcon = sev.icon
                  return (
                    <div key={idx} className="reco-issue-card">
                      <div className="issue-header">
                        <SevIcon size={16} style={{ color: sev.color }} />
                        <span className="issue-factor">{issue.factor}</span>
                        <span className="issue-severity" style={{ color: sev.color }}>
                          {sev.label}
                        </span>
                      </div>
                      <p className="issue-explanation">{issue.explanation}</p>
                      <div className="issue-reco">
                        <span className="reco-tag">Recommendation</span>
                        <p>{issue.recommendation}</p>
                      </div>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  )
}
