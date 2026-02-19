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
  Info,
} from 'lucide-react'
import {
  BarChart, Bar, PieChart, Pie, Cell, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
} from 'recharts'
import { fetchFarmerAnalytics, generateRecommendations, exportToCSV, ROBUSTA_IDEALS, arrLastFloat } from '../../lib/analyticsService'
import './Recommendations.css'

// Priority colors matching Streamlit
const PRIORITY_COLORS = {
  High: '#dc2626',
  Medium: '#f97316',
  Low: '#22c55e',
}

// Rules engine for identifying issues - enhanced to use DB data
function analyzeCluster(cluster) {
  const issues = []
  const sd = cluster.stageData || {}

  // Check fertilizer
  if (!sd.fertilizerType && !sd.fertilizer_type) {
    issues.push({
      factor: 'fertilizer_type',
      severity: 'high',
      explanation: 'No fertilizer type has been recorded. Coffee plants require regular fertilization for optimal yield.',
      recommendation: 'Apply NPK (14-14-14) fertilizer at the start of the rainy season. For mature trees, apply 200-300g per tree, 2-3 times per year.',
    })
  }

  // Check pesticide
  const pestFreq = sd.pesticideFrequency || sd.pesticide_frequency
  if (!pestFreq) {
    issues.push({
      factor: 'pesticide_frequency',
      severity: 'medium',
      explanation: 'No pesticide application frequency recorded. Plants may be vulnerable to pest infestation.',
      recommendation: 'Conduct regular pest scouting. Apply approved insecticides for Coffee Berry Borer (CBB) prevention. Consider integrated pest management (IPM) practices.',
    })
  }

  // Check pruning
  const lastPruned = sd.lastPrunedDate || sd.last_pruned_date
  if (!lastPruned) {
    issues.push({
      factor: 'pruning_interval',
      severity: 'medium',
      explanation: 'No pruning date recorded. Unpruned trees have reduced air circulation and light penetration.',
      recommendation: 'Prune coffee trees annually after harvest season. Remove dead, diseased, and crossing branches. Maintain optimal canopy shape for light exposure.',
    })
  }

  // Check soil pH
  const pH = parseFloat(sd.soilPh || sd.soil_ph)
  if (pH && (pH < ROBUSTA_IDEALS.soil_ph.min || pH > ROBUSTA_IDEALS.soil_ph.max)) {
    issues.push({
      factor: 'soil_ph',
      severity: pH < 5.0 || pH > 7.0 ? 'high' : 'medium',
      value: pH,
      ideal: `${ROBUSTA_IDEALS.soil_ph.min}–${ROBUSTA_IDEALS.soil_ph.max}`,
      explanation: `Soil pH is ${pH}. Coffee thrives in slightly acidic soil (pH ${ROBUSTA_IDEALS.soil_ph.min}-${ROBUSTA_IDEALS.soil_ph.max}). Current pH may affect nutrient uptake.`,
      recommendation: pH < ROBUSTA_IDEALS.soil_ph.min
        ? 'Apply agricultural lime to raise soil pH. Test soil every 6 months to monitor changes.'
        : 'Apply sulfur or organic matter to lower soil pH. Ensure proper drainage to prevent alkalinity buildup.',
    })
  }

  // Check shade trees
  const shadeTrees = sd.shadeTreePresent || sd.shade_tree_present
  if (shadeTrees === 'No' || shadeTrees === false || !shadeTrees) {
    issues.push({
      factor: 'shade_tree_present',
      severity: 'low',
      value: 'absent',
      ideal: 'present',
      explanation: 'No shade trees present. Shade trees help regulate temperature and improve bean quality.',
      recommendation: 'Plant shade trees like Madre de Cacao (Gliricidia) or banana at 6-8m spacing. Maintain 40-60% shade coverage.',
    })
  }

  // Check temperature
  const temp = parseFloat(sd.avgTempC || sd.avg_temp_c)
  if (temp && (temp < ROBUSTA_IDEALS.avg_temp_c.min || temp > ROBUSTA_IDEALS.avg_temp_c.max)) {
    issues.push({
      factor: 'avg_temp_c',
      severity: 'medium',
      value: temp,
      ideal: `${ROBUSTA_IDEALS.avg_temp_c.min}–${ROBUSTA_IDEALS.avg_temp_c.max}`,
      explanation: `Temperature is ${temp}°C. Optimal range for coffee is ${ROBUSTA_IDEALS.avg_temp_c.min}-${ROBUSTA_IDEALS.avg_temp_c.max}°C.`,
      recommendation: temp > ROBUSTA_IDEALS.avg_temp_c.max
        ? 'Increase shade coverage. Consider mulching to reduce soil temperature. Plant windbreaks if exposed to hot winds.'
        : 'Protect young plants with covers during cold periods. Avoid planting in frost-prone areas.',
    })
  }

  // Check humidity
  const humidity = parseFloat(sd.avgHumidityPct || sd.avg_humidity_pct)
  if (humidity && (humidity < ROBUSTA_IDEALS.avg_humidity_pct.min || humidity > ROBUSTA_IDEALS.avg_humidity_pct.max)) {
    issues.push({
      factor: 'avg_humidity_pct',
      severity: humidity < 40 || humidity > 90 ? 'high' : 'low',
      value: humidity,
      ideal: `${ROBUSTA_IDEALS.avg_humidity_pct.min}–${ROBUSTA_IDEALS.avg_humidity_pct.max}`,
      explanation: `Average humidity is ${humidity}%. Optimal range is ${ROBUSTA_IDEALS.avg_humidity_pct.min}–${ROBUSTA_IDEALS.avg_humidity_pct.max}%.`,
      recommendation: humidity < ROBUSTA_IDEALS.avg_humidity_pct.min
        ? 'Increase mulching around plant bases to retain soil moisture.'
        : 'Improve air circulation through pruning. Monitor for fungal diseases.',
    })
  }

  // Check rainfall
  const rainfall = parseFloat(sd.avgRainfallMm || sd.avg_rainfall_mm)
  if (rainfall && (rainfall < ROBUSTA_IDEALS.avg_rainfall_mm.min || rainfall > ROBUSTA_IDEALS.avg_rainfall_mm.max)) {
    issues.push({
      factor: 'avg_rainfall_mm',
      severity: rainfall < 50 || rainfall > 350 ? 'high' : 'medium',
      value: rainfall,
      ideal: `${ROBUSTA_IDEALS.avg_rainfall_mm.min}–${ROBUSTA_IDEALS.avg_rainfall_mm.max}`,
      explanation: `Monthly rainfall is ${rainfall}mm. Coffee needs ${ROBUSTA_IDEALS.avg_rainfall_mm.min}–${ROBUSTA_IDEALS.avg_rainfall_mm.max}mm monthly.`,
      recommendation: rainfall < ROBUSTA_IDEALS.avg_rainfall_mm.min
        ? 'Consider supplemental irrigation during dry spells. Apply mulch to conserve moisture.'
        : 'Ensure proper drainage to prevent waterlogging and root rot.',
    })
  }

  // Check yield decline against previous harvest record's total
  const prevYield = parseFloat(sd.previousYield || sd.preYieldKg || sd.pre_yield_kg)
  const currentYield = parseFloat(sd.currentYield || sd.actualYield || sd.actual_yield)
  if (prevYield && currentYield && currentYield < prevYield * 0.8) {
    issues.push({
      factor: 'yield_decline',
      severity: currentYield < prevYield * 0.7 ? 'high' : 'medium',
      value: `${((1 - currentYield / prevYield) * 100).toFixed(0)}%`,
      ideal: '< 5%',
      explanation: `Current yield (${currentYield}kg) is significantly lower than previous (${prevYield}kg).`,
      recommendation: 'Conduct comprehensive soil testing. Review fertilizer program. Check for pest/disease presence.',
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
  const [showIdealRanges, setShowIdealRanges] = useState(false)

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
            variety: c.variety,
            datePlanted: c.date_planted,
            harvestSeason: sd.season,
            predictedYield: sd.predicted_yield,
            currentYield: arrLastFloat(c.latestHarvest?.yield_kg),
            previousYield: c.previousHarvestYield || sd.pre_yield_kg || 0,
            avgTempC: sd.avgTempC || sd.avg_temp_c,
            avgHumidityPct: sd.avgHumidityPct || sd.avg_humidity_pct,
            avgRainfallMm: sd.avgRainfallMm || sd.avg_rainfall_mm,
            soil_ph: sd.soil_ph,
            fertilizer_type: sd.fertilizer_type,
            fertilizer_frequency: sd.fertilizer_frequency,
            pesticide_type: sd.pesticide_type,
            pesticide_frequency: sd.pesticide_frequency,
            shadeTreePresent: sd.shadeTreePresent || sd.shade_tree_present,
            last_pruned_date: sd.last_pruned_date,
            elevation_m: sd.elevation_m || data.farm?.elevation_m,
            pruning_interval_months: sd.pruning_interval_months,
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

  // Aggregate all recommendations for charts
  const allRecommendations = filtered.flatMap(c => 
    c.issues.map(issue => ({
      ...issue,
      clusterName: c.clusterName,
      priority: issue.severity === 'high' ? 'High' : issue.severity === 'medium' ? 'Medium' : 'Low',
    }))
  )

  // Priority counts for metrics
  const priorityCounts = {
    High: allRecommendations.filter(r => r.priority === 'High').length,
    Medium: allRecommendations.filter(r => r.priority === 'Medium').length,
    Low: allRecommendations.filter(r => r.priority === 'Low').length,
  }

  // Build chart data: recommendations by factor
  const factorCounts = {}
  allRecommendations.forEach(rec => {
    const factor = rec.factor
    if (!factorCounts[factor]) {
      factorCounts[factor] = { High: 0, Medium: 0, Low: 0 }
    }
    factorCounts[factor][rec.priority]++
  })
  const factorChartData = Object.entries(factorCounts).map(([factor, counts]) => ({
    factor: factor.replace(/_/g, ' '),
    High: counts.High,
    Medium: counts.Medium,
    Low: counts.Low,
    total: counts.High + counts.Medium + counts.Low,
  })).sort((a, b) => b.total - a.total)

  // Priority pie chart data
  const priorityPieData = Object.entries(priorityCounts)
    .filter(([, count]) => count > 0)
    .map(([priority, count]) => ({ name: priority, value: count }))

  // Build radar chart data for selected cluster
  const buildRadarData = (cluster) => {
    if (!cluster) return []
    const sd = cluster.stageData || {}
    const features = [
      { field: 'soil_ph', label: 'Soil pH', min: 4, max: 8 },
      { field: 'temperature', label: 'Temp (°C)', min: 10, max: 35 },
      { field: 'humidity', label: 'Humidity (%)', min: 50, max: 100 },
      { field: 'rainfall', label: 'Rainfall (mm)', min: 50, max: 400 },
    ]
    
    return features.map(f => {
      const val = parseFloat(sd[f.field])
      const ideal = ROBUSTA_IDEALS[f.field === 'temperature' ? 'avg_temp_c' : f.field === 'humidity' ? 'avg_humidity_pct' : f.field === 'rainfall' ? 'avg_rainfall_mm' : f.field]
      const idealMid = ideal ? (ideal.min + ideal.max) / 2 : null
      const normalizedVal = val ? ((val - f.min) / (f.max - f.min)) * 100 : null
      const normalizedIdeal = idealMid ? ((idealMid - f.min) / (f.max - f.min)) * 100 : 50
      return {
        feature: f.label,
        value: normalizedVal,
        ideal: normalizedIdeal,
        actual: val,
      }
    }).filter(d => d.value !== null)
  }

  const radarData = buildRadarData(selectedCluster)

  const perfConfig = {
    poor: { label: 'Poor', icon: TrendingDown, color: '#dc2626', bg: '#fef2f2' },
    moderate: { label: 'Moderate', icon: Minus, color: '#d97706', bg: '#fffbeb' },
    good: { label: 'Good', icon: TrendingUp, color: '#16a34a', bg: '#f0fdf4' },
  }

  const severityConfig = {
    high: { label: 'High', icon: AlertCircle, color: '#dc2626' },
    medium: { label: 'Medium', icon: AlertTriangle, color: '#d97706' },
    low: { label: 'Low', icon: Lightbulb, color: '#22c55e' },
  }

  const handleExport = () => {
    const exportData = allRecommendations.map(rec => ({
      'Cluster': rec.clusterName,
      'Factor': rec.factor,
      'Priority': rec.priority,
      'Current Value': rec.value || 'N/A',
      'Ideal Range': rec.ideal || 'N/A',
      'Recommendation': rec.recommendation,
    }))
    exportToCSV(exportData, `recommendations_${new Date().toISOString().split('T')[0]}.csv`)
  }

  // Ideal ranges table data
  const idealRangesData = Object.entries(ROBUSTA_IDEALS).map(([key, range]) => ({
    factor: key.replace(/_/g, ' '),
    min: range.min,
    max: range.max,
  }))

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
          <h1>Agronomic Recommendations</h1>
          <p>Rule-based guidance aligned to Robusta ideal ranges</p>
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
        </div>
      </div>

      {/* Priority Summary Cards (Streamlit-style) */}
      <div className="reco-priority-summary">
        <div className="reco-priority-card priority-high">
          <AlertCircle size={24} />
          <div>
            <span className="priority-count">{priorityCounts.High}</span>
            <span className="priority-label">High Priority</span>
          </div>
        </div>
        <div className="reco-priority-card priority-medium">
          <AlertTriangle size={24} />
          <div>
            <span className="priority-count">{priorityCounts.Medium}</span>
            <span className="priority-label">Medium Priority</span>
          </div>
        </div>
        <div className="reco-priority-card priority-low">
          <CheckCircle size={24} />
          <div>
            <span className="priority-count">{priorityCounts.Low}</span>
            <span className="priority-label">Low Priority</span>
          </div>
        </div>
      </div>

      {/* Charts Section */}
      {allRecommendations.length > 0 && (
        <div className="reco-charts-grid">
          {/* Recommendations by Factor - Bar Chart */}
          <div className="reco-chart-card">
            <h3>Recommendations by Factor</h3>
            <p>Clusters affected by each issue type</p>
            <ResponsiveContainer width="100%" height={280}>
              <BarChart data={factorChartData} layout="vertical" margin={{ left: 20 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis type="number" fontSize={11} tick={{ fill: '#64748b' }} />
                <YAxis dataKey="factor" type="category" fontSize={10} width={100} tick={{ fill: '#64748b' }} />
                <Tooltip />
                <Legend />
                <Bar dataKey="High" stackId="a" fill={PRIORITY_COLORS.High} name="High" />
                <Bar dataKey="Medium" stackId="a" fill={PRIORITY_COLORS.Medium} name="Medium" />
                <Bar dataKey="Low" stackId="a" fill={PRIORITY_COLORS.Low} name="Low" />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Priority Distribution - Pie Chart */}
          <div className="reco-chart-card">
            <h3>Priority Distribution</h3>
            <p>Breakdown of recommendation urgency</p>
            <ResponsiveContainer width="100%" height={280}>
              <PieChart>
                <Pie
                  data={priorityPieData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={90}
                  dataKey="value"
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {priorityPieData.map((entry) => (
                    <Cell key={entry.name} fill={PRIORITY_COLORS[entry.name]} />
                  ))}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Ideal Ranges Section */}
      <div className="reco-ideal-section">
        <div className="reco-ideal-header" onClick={() => setShowIdealRanges(!showIdealRanges)}>
          <h3><Info size={18} /> Robusta Ideal Ranges</h3>
          <ChevronDown size={18} className={showIdealRanges ? 'rotated' : ''} />
        </div>
        {showIdealRanges && (
          <div className="reco-ideal-table">
            <table>
              <thead>
                <tr>
                  <th>Factor</th>
                  <th>Min</th>
                  <th>Max</th>
                </tr>
              </thead>
              <tbody>
                {idealRangesData.map(row => (
                  <tr key={row.factor}>
                    <td>{row.factor}</td>
                    <td>{row.min}</td>
                    <td>{row.max}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Cluster List with Recommendations */}
      <div className="reco-content">
        <div className="reco-list">
          <div className="reco-list-header">
            <h3>Clusters ({filtered.length})</h3>
            <div className="filter-select small">
              <select value={performanceFilter} onChange={(e) => setPerformanceFilter(e.target.value)}>
                <option value="">All Status</option>
                <option value="poor">Needs Attention</option>
                <option value="moderate">Moderate</option>
                <option value="good">Good</option>
              </select>
            </div>
          </div>
          {filtered.length === 0 ? (
            <div className="reco-empty">
              <CheckCircle size={48} />
              <h3>All clusters within ideal ranges</h3>
              <p>No recommendations needed at this time</p>
            </div>
          ) : (
            filtered.map((cluster) => {
              const perf = perfConfig[cluster.performance]
              const PerfIcon = perf.icon
              const highCount = cluster.issues.filter(i => i.severity === 'high').length
              const medCount = cluster.issues.filter(i => i.severity === 'medium').length
              return (
                <div
                  key={cluster.id}
                  className={`reco-item ${selectedCluster?.id === cluster.id ? 'active' : ''}`}
                  onClick={() => setSelectedCluster(cluster)}
                >
                  <div className="reco-item-left">
                    <div className="reco-perf-badge" style={{ background: perf.bg, color: perf.color }}>
                      <PerfIcon size={16} />
                    </div>
                    <div>
                      <h4>{cluster.clusterName}</h4>
                      <span className="reco-cluster-stage">{cluster.plantStage}</span>
                    </div>
                  </div>
                  <div className="reco-item-right">
                    {highCount > 0 && <span className="reco-badge high">{highCount} High</span>}
                    {medCount > 0 && <span className="reco-badge medium">{medCount} Med</span>}
                    <span className="reco-issue-count">{cluster.issues.length} total</span>
                  </div>
                </div>
              )
            })
          )}
        </div>

        {/* Detail Panel */}
        {selectedCluster && (
          <div className="reco-detail">
            <div className="detail-header">
              <h3><Lightbulb size={18} /> {selectedCluster.clusterName}</h3>
              <button className="modal-close" onClick={() => setSelectedCluster(null)}>
                <X size={18} />
              </button>
            </div>

            {/* Radar Chart for Cluster vs Ideal */}
            {radarData.length > 0 && (
              <div className="reco-radar-section">
                <h4>Cluster vs Ideal Ranges</h4>
                <ResponsiveContainer width="100%" height={250}>
                  <RadarChart data={radarData}>
                    <PolarGrid />
                    <PolarAngleAxis dataKey="feature" fontSize={11} />
                    <PolarRadiusAxis angle={30} domain={[0, 100]} tick={false} />
                    <Radar name="Ideal" dataKey="ideal" stroke="#22c55e" fill="#22c55e" fillOpacity={0.3} />
                    <Radar name="Actual" dataKey="value" stroke="#4A7C59" fill="#4A7C59" fillOpacity={0.5} />
                    <Legend />
                    <Tooltip formatter={(val, name, props) => {
                      if (name === 'Actual') return [props.payload.actual, 'Actual Value']
                      return [val.toFixed(0) + '%', name]
                    }} />
                  </RadarChart>
                </ResponsiveContainer>
              </div>
            )}

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
                    <div key={idx} className={`reco-issue-card priority-${issue.severity}`}>
                      <div className="issue-header">
                        <SevIcon size={16} style={{ color: sev.color }} />
                        <span className="issue-factor">{issue.factor.replace(/_/g, ' ')}</span>
                        <span className="issue-severity" style={{ background: sev.color }}>
                          {sev.label}
                        </span>
                      </div>
                      {issue.value && (
                        <div className="issue-values">
                          <span>Current: <strong>{issue.value}</strong></span>
                          {issue.ideal && <span>Ideal: <strong>{issue.ideal}</strong></span>}
                        </div>
                      )}
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
