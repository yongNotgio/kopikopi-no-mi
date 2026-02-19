import { useState, useEffect } from 'react'
import { useAuth } from '../../context/AuthContext'
import { useFarm } from '../../context/FarmContext'
import {
  BarChart3,
  Filter,
  ChevronDown,
  X,
  TrendingUp,
  Coffee,
  Layers,
  Calendar,
  Mountain,
  RefreshCw,
  Download,
} from 'lucide-react'
import {
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from 'recharts'
import { fetchFarmerAnalytics, exportToCSV, GRADE_COLORS } from '../../lib/analyticsService'
import './HarvestRecords.css'

export default function HarvestRecords() {
  const { user } = useAuth()
  const { getAllClusters, farm } = useFarm()
  const [seasonFilter, setSeasonFilter] = useState('')
  const [selectedCluster, setSelectedCluster] = useState(null)
  const [loading, setLoading] = useState(true)
  const [dbClusters, setDbClusters] = useState([])
  const [harvestRecords, setHarvestRecords] = useState([])

  useEffect(() => {
    if (user?.id) {
      fetchData()
    }
  }, [user?.id])

  const fetchData = async () => {
    setLoading(true)
    try {
      const data = await fetchFarmerAnalytics(user.id)
      
      // Process clusters with harvest data
      const processedClusters = data.clusters?.map(c => {
        const sd = c.stageData || {}
        const harvests = c.harvests || []
        const latestHarvest = harvests[0]
        
        return {
          id: c.id,
          clusterName: c.cluster_name,
          plantStage: c.plant_stage,
          plantCount: c.plant_count,
          variety: c.variety,
          stageData: {
            variety: c.variety || sd.variety,
            datePlanted: c.date_planted,
            harvestSeason: sd.season || latestHarvest?.season || 'N/A',
            predictedYield: sd.predicted_yield || 0,
            currentYield: latestHarvest?.yield_kg || 0,
            previousYield: sd.pre_yield_kg || 0,
            gradeFine: latestHarvest?.grade_fine_kg || 0,
            gradePremium: latestHarvest?.grade_premium_kg || 0,
            gradeCommercial: latestHarvest?.grade_commercial_kg || 0,
            fertilizerType: sd.fertilizer_type,
            fertilizerFrequency: sd.fertilizer_frequency,
            pesticideType: sd.pesticide_type,
            pesticideFrequency: sd.pesticide_frequency,
            soilPh: sd.soil_ph,
            shadeTrees: sd.shade_trees ? 'Yes' : 'No',
            lastHarvestedDate: latestHarvest?.harvest_date,
            estimatedHarvestDate: sd.estimated_harvest_date,
            estimatedFloweringDate: sd.estimated_flowering_date,
            lastPrunedDate: sd.last_pruned_date,
            temperature: sd.temperature,
            rainfall: sd.rainfall,
            humidity: sd.humidity,
          },
          harvests,
        }
      }) || []
      
      setDbClusters(processedClusters)
      
      // Flatten all harvest records for trend analysis
      const allHarvests = processedClusters.flatMap(c => 
        c.harvests.map(h => ({ ...h, clusterName: c.clusterName }))
      )
      setHarvestRecords(allHarvests)
    } catch (err) {
      console.error('Error fetching harvest data:', err)
    }
    setLoading(false)
  }

  // Combine context clusters with DB data
  const contextClusters = getAllClusters()
  const allClusters = dbClusters.length > 0 ? dbClusters : contextClusters

  // Get clusters that are ready-to-harvest, flowering, or fruit-bearing
  const harvestClusters = allClusters.filter((c) =>
    ['ready-to-harvest', 'flowering', 'fruit-bearing', 'Ready to Harvest', 'Flowering'].some(
      stage => c.plantStage?.toLowerCase().includes(stage.toLowerCase().replace(/-/g, ''))
    ) || c.harvests?.length > 0
  )

  // Get unique seasons from both stage data and harvest records
  const seasons = [...new Set([
    ...allClusters.map((c) => c.stageData?.harvestSeason).filter(Boolean),
    ...harvestRecords.map(h => h.season).filter(Boolean),
  ])]

  const filteredClusters = seasonFilter
    ? harvestClusters.filter((c) => 
        c.stageData?.harvestSeason?.includes(seasonFilter) ||
        c.harvests?.some(h => h.season === seasonFilter)
      )
    : harvestClusters.length > 0 ? harvestClusters : allClusters

  // Generate chart data from selected cluster
  const getYieldChartData = (cluster) => {
    if (!cluster?.stageData) return []
    return [
      { name: 'Previous', yield: parseFloat(cluster.stageData.previousYield) || 0 },
      { name: 'Predicted', yield: parseFloat(cluster.stageData.predictedYield) || 0 },
      { name: 'Actual', yield: parseFloat(cluster.stageData.currentYield) || 0 },
    ]
  }

  const getGradeData = (cluster) => {
    if (!cluster?.stageData) return []
    return [
      { name: 'Fine', value: parseFloat(cluster.stageData.gradeFine) || 0 },
      { name: 'Premium', value: parseFloat(cluster.stageData.gradePremium) || 0 },
      { name: 'Commercial', value: parseFloat(cluster.stageData.gradeCommercial) || 0 },
    ].filter((d) => d.value > 0)
  }

  const stageLabels = {
    'ready-to-harvest': 'Ready to Harvest',
    'Ready to Harvest': 'Ready to Harvest',
    'flowering': 'Flowering',
    'Flowering': 'Flowering',
    'fruit-bearing': 'Fruit-bearing',
    'tree': 'Tree',
    'Tree': 'Tree',
    'seed-sapling': 'Seed/Sapling',
    'Seed/Sapling': 'Seed/Sapling',
  }

  const getPlantAge = (datePlanted) => {
    if (!datePlanted) return 'N/A'
    const planted = new Date(datePlanted)
    const now = new Date()
    const years = Math.floor((now - planted) / (365.25 * 24 * 60 * 60 * 1000))
    const months = Math.floor(((now - planted) % (365.25 * 24 * 60 * 60 * 1000)) / (30.44 * 24 * 60 * 60 * 1000))
    if (years > 0) return `${years}y ${months}m`
    return `${months}m`
  }

  // Build yield trend data across all harvest clusters for the line chart
  const getYieldTrendData = () => {
    return filteredClusters
      .filter((c) => c.stageData?.currentYield || c.stageData?.previousYield || c.stageData?.predictedYield)
      .map((c) => ({
        name: c.clusterName,
        previous: parseFloat(c.stageData?.previousYield) || 0,
        predicted: parseFloat(c.stageData?.predictedYield) || 0,
        actual: parseFloat(c.stageData?.currentYield) || 0,
      }))
  }

  // Build harvest history for trend chart
  const getHarvestHistoryData = () => {
    const seasonMap = {}
    harvestRecords.forEach(h => {
      const season = h.season || 'Unknown'
      if (!seasonMap[season]) {
        seasonMap[season] = { season, yield: 0, fine: 0, premium: 0, commercial: 0 }
      }
      seasonMap[season].yield += parseFloat(h.yield_kg || 0)
      seasonMap[season].fine += parseFloat(h.grade_fine_kg || 0)
      seasonMap[season].premium += parseFloat(h.grade_premium_kg || 0)
      seasonMap[season].commercial += parseFloat(h.grade_commercial_kg || 0)
    })
    return Object.values(seasonMap).map(s => ({
      ...s,
      yield: Math.round(s.yield),
      fine: Math.round(s.fine),
      premium: Math.round(s.premium),
      commercial: Math.round(s.commercial),
    }))
  }

  const handleExport = () => {
    const exportData = filteredClusters.map(c => ({
      'Cluster': c.clusterName,
      'Stage': c.plantStage,
      'Trees': c.plantCount,
      'Season': c.stageData?.harvestSeason || 'N/A',
      'Previous Yield (kg)': c.stageData?.previousYield || 0,
      'Predicted Yield (kg)': c.stageData?.predictedYield || 0,
      'Actual Yield (kg)': c.stageData?.currentYield || 0,
      'Fine (kg)': c.stageData?.gradeFine || 0,
      'Premium (kg)': c.stageData?.gradePremium || 0,
      'Commercial (kg)': c.stageData?.gradeCommercial || 0,
    }))
    exportToCSV(exportData, `harvest_records_${new Date().toISOString().split('T')[0]}.csv`)
  }

  if (loading) {
    return (
      <div className="harvest-loading">
        <div className="harvest-loading-spinner"></div>
        <p>Loading harvest records...</p>
      </div>
    )
  }

  return (
    <div className="harvest-page">
      <div className="harvest-header">
        <div>
          <h1>Harvest Records & Forecast</h1>
          <p>Monitor historical performance and future yield predictions</p>
        </div>
        <div className="harvest-filters">
          <button className="harvest-refresh-btn" onClick={fetchData}>
            <RefreshCw size={16} /> Refresh
          </button>
          <button className="harvest-export-btn" onClick={handleExport}>
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

      {/* Summary Charts */}
      {harvestRecords.length > 0 && (
        <div className="harvest-summary-charts">
          <div className="harvest-summary-chart">
            <h4><TrendingUp size={16} /> Yield by Season</h4>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={getHarvestHistoryData()}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="season" fontSize={11} tick={{ fill: '#64748b' }} />
                <YAxis fontSize={11} tick={{ fill: '#64748b' }} tickFormatter={v => `${v} kg`} />
                <Tooltip formatter={v => [`${v.toLocaleString()} kg`]} />
                <Bar dataKey="yield" fill="#3b82f6" radius={[4, 4, 0, 0]} name="Total Yield" />
              </BarChart>
            </ResponsiveContainer>
          </div>
          <div className="harvest-summary-chart">
            <h4><BarChart3 size={16} /> Grade Distribution by Season</h4>
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={getHarvestHistoryData()}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                <XAxis dataKey="season" fontSize={11} tick={{ fill: '#64748b' }} />
                <YAxis fontSize={11} tick={{ fill: '#64748b' }} />
                <Tooltip formatter={v => [`${v.toLocaleString()} kg`]} />
                <Legend />
                <Bar dataKey="fine" stackId="a" fill={GRADE_COLORS[0]} name="Fine" />
                <Bar dataKey="premium" stackId="a" fill={GRADE_COLORS[1]} name="Premium" />
                <Bar dataKey="commercial" stackId="a" fill={GRADE_COLORS[2]} name="Commercial" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}

      {/* Cluster List */}
      <div className="harvest-content">
        <div className="cluster-list-panel">
          <h3>Active Clusters ({filteredClusters.length})</h3>
          {filteredClusters.length === 0 ? (
            <div className="cluster-list-empty">
              <p>No harvest-ready or flowering clusters found.</p>
            </div>
          ) : (
            <div className="cluster-list">
              {filteredClusters.map((cluster) => (
                <div
                  key={cluster.id}
                  className={`cluster-list-item ${selectedCluster?.id === cluster.id ? 'active' : ''}`}
                  onClick={() => setSelectedCluster(cluster)}
                >
                  <div className="cli-top">
                    <span className="cli-name">{cluster.clusterName}</span>
                    <span className={`cli-stage cli-stage--${cluster.plantStage}`}>
                      {stageLabels[cluster.plantStage] || cluster.plantStage}
                    </span>
                  </div>
                  <div className="cli-details">
                    <span><Coffee size={12} /> {cluster.stageData?.variety || 'N/A'}</span>
                    <span><Layers size={12} /> {cluster.plantCount} trees</span>
                    <span><Calendar size={12} /> {cluster.stageData?.harvestSeason || 'N/A'}</span>
                  </div>
                  <div className="cli-yield">
                    <span>Predicted: {cluster.stageData?.predictedYield || '—'} kg</span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Cluster Detail / Overlay Panel */}
        <div className="cluster-detail-panel">
          {!selectedCluster ? (
            <div className="detail-empty">
              <BarChart3 size={48} />
              <h3>Select a Cluster</h3>
              <p>Click a cluster from the list to view detailed records and forecasts</p>
            </div>
          ) : (
            <div className="detail-content">
              <div className="detail-header">
                <h3>{selectedCluster.clusterName}</h3>
                <button className="modal-close" onClick={() => setSelectedCluster(null)}>
                  <X size={18} />
                </button>
              </div>

              {/* Cluster Info */}
              <div className="detail-section">
                <h4>Cluster Information</h4>
                <div className="detail-info-grid">
                  <div className="info-item">
                    <span className="info-label">Cluster ID</span>
                    <span className="info-value">{selectedCluster.id.slice(-6)}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Tree Count</span>
                    <span className="info-value">{selectedCluster.plantCount}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Variety</span>
                    <span className="info-value">{selectedCluster.stageData?.variety || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Date Planted</span>
                    <span className="info-value">{selectedCluster.stageData?.datePlanted || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Plant Age</span>
                    <span className="info-value">{getPlantAge(selectedCluster.stageData?.datePlanted)}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Elevation (MASL)</span>
                    <span className="info-value">{farm?.elevation || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Soil pH</span>
                    <span className="info-value">{selectedCluster.stageData?.soilPh || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Shade Trees</span>
                    <span className="info-value">{selectedCluster.stageData?.shadeTrees || 'N/A'}</span>
                  </div>
                </div>
              </div>

              {/* Dates & Seasons */}
              <div className="detail-section">
                <h4><Calendar size={16} /> Dates & Seasons</h4>
                <div className="detail-info-grid">
                  <div className="info-item">
                    <span className="info-label">Season</span>
                    <span className="info-value">{selectedCluster.stageData?.harvestSeason || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Est. Flowering Date</span>
                    <span className="info-value">{selectedCluster.stageData?.estimatedFloweringDate || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Est. Harvest Date</span>
                    <span className="info-value">{selectedCluster.stageData?.estimatedHarvestDate || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Last Harvested</span>
                    <span className="info-value">{selectedCluster.stageData?.lastHarvestedDate || 'N/A'}</span>
                  </div>
                </div>
              </div>

              {/* Management Status */}
              <div className="detail-section">
                <h4><Coffee size={16} /> Management Status</h4>
                <div className="detail-info-grid">
                  <div className="info-item">
                    <span className="info-label">Fertilizer Type</span>
                    <span className="info-value">{selectedCluster.stageData?.fertilizerType || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Fertilizer Frequency</span>
                    <span className="info-value">{selectedCluster.stageData?.fertilizerFrequency || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Pesticide Type</span>
                    <span className="info-value">{selectedCluster.stageData?.pesticideType || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Pesticide Frequency</span>
                    <span className="info-value">{selectedCluster.stageData?.pesticideFrequency || 'N/A'}</span>
                  </div>
                  <div className="info-item">
                    <span className="info-label">Last Pruned</span>
                    <span className="info-value">{selectedCluster.stageData?.lastPrunedDate || 'N/A'}</span>
                  </div>
                </div>
              </div>

              {/* Yield & Forecast Data */}
              <div className="detail-section">
                <h4>
                  <TrendingUp size={16} /> Yield & Forecast
                </h4>
                <div className="yield-summary">
                  <div className="yield-card">
                    <span className="yield-label">Previous Yield</span>
                    <span className="yield-value">{selectedCluster.stageData?.previousYield || '0'} kg</span>
                  </div>
                  <div className="yield-card yield-card--predicted">
                    <span className="yield-label">Predicted Yield</span>
                    <span className="yield-value">{selectedCluster.stageData?.predictedYield || '0'} kg</span>
                  </div>
                  <div className="yield-card yield-card--actual">
                    <span className="yield-label">Actual Yield</span>
                    <span className="yield-value">{selectedCluster.stageData?.currentYield || '0'} kg</span>
                  </div>
                </div>
              </div>

              {/* Charts */}
              <div className="detail-section">
                <h4>Analytics & Forecast Charts</h4>
                <div className="charts-grid">
                  <div className="chart-card">
                    <h5>Yield Comparison (Predicted vs Actual)</h5>
                    <ResponsiveContainer width="100%" height={220}>
                      <BarChart data={getYieldChartData(selectedCluster)}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="name" fontSize={12} />
                        <YAxis fontSize={12} />
                        <Tooltip />
                        <Bar dataKey="yield" fill="var(--primary)" radius={[4, 4, 0, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>

                  <div className="chart-card">
                    <h5>Grade Distribution</h5>
                    {getGradeData(selectedCluster).length > 0 ? (
                      <ResponsiveContainer width="100%" height={220}>
                        <PieChart>
                          <Pie
                            data={getGradeData(selectedCluster)}
                            cx="50%"
                            cy="50%"
                            innerRadius={50}
                            outerRadius={80}
                            dataKey="value"
                            label={({ name, value }) => `${name}: ${value}%`}
                          >
                            {getGradeData(selectedCluster).map((entry, index) => (
                              <Cell key={entry.name} fill={GRADE_COLORS[index % GRADE_COLORS.length]} />
                            ))}
                          </Pie>
                          <Tooltip />
                        </PieChart>
                      </ResponsiveContainer>
                    ) : (
                      <div className="chart-empty">No grade data available</div>
                    )}
                  </div>
                </div>
              </div>

              {/* Yield Trend Line Chart */}
              {getYieldTrendData().length > 1 && (
                <div className="detail-section">
                  <h4><TrendingUp size={16} /> Yield Trends Across Clusters</h4>
                  <div className="chart-card">
                    <ResponsiveContainer width="100%" height={250}>
                      <LineChart data={getYieldTrendData()}>
                        <CartesianGrid strokeDasharray="3 3" />
                        <XAxis dataKey="name" fontSize={11} />
                        <YAxis fontSize={12} />
                        <Tooltip />
                        <Legend />
                        <Line type="monotone" dataKey="previous" stroke="#94a3b8" name="Previous" strokeWidth={2} />
                        <Line type="monotone" dataKey="predicted" stroke="#fbbf24" name="Predicted" strokeWidth={2} />
                        <Line type="monotone" dataKey="actual" stroke="#2d5a2d" name="Actual" strokeWidth={2} />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
