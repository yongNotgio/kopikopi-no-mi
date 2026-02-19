import { useState, useEffect } from 'react'
import {
    Download,
    ToggleLeft,
    ToggleRight,
    TrendingUp,
    ChevronDown,
    ChevronRight,
    RefreshCw,
} from 'lucide-react'
import {
    BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
    ResponsiveContainer, LineChart, Line,
} from 'recharts'
import { fetchAdminAnalytics, exportToCSV, GRADE_COLORS } from '../../lib/analyticsService'
import './Prediction.css'

export default function Prediction() {
    const [viewMode, setViewMode] = useState('overall') // 'overall' or 'farm'
    const [overallData, setOverallData] = useState([])
    const [farmData, setFarmData] = useState([])
    const [expandedFarm, setExpandedFarm] = useState(null)
    const [loading, setLoading] = useState(true)

    useEffect(() => {
        fetchPredictionData()
    }, [])

    const fetchPredictionData = async () => {
        setLoading(true)
        try {
            const data = await fetchAdminAnalytics()

            // --- Overall aggregated data from yield trends ---
            setOverallData(data.yieldTrends.length > 0 ? data.yieldTrends : [
                { season: 'No Data', actual: 0, predicted: 0 },
            ])

            // --- Per-farm data ---
            const farmMap = {}
            data.clusters?.forEach((c) => {
                const farm = c.farm
                const farmId = farm?.id
                if (!farmId) return

                if (!farmMap[farmId]) {
                    farmMap[farmId] = {
                        id: farmId,
                        farmName: farm.farm_name || 'Unknown Farm',
                        farmerName: c.farmer ? `${c.farmer.first_name || ''} ${c.farmer.last_name || ''}`.trim() : 'N/A',
                        clusters: [],
                        totalPredicted: 0,
                        totalActual: 0,
                        totalPrevious: 0,
                        seasonData: {},
                    }
                }

                // Get data from latest stage data
                const sd = c.stageData || {}
                const predicted = parseFloat(sd.predicted_yield || 0)
                const previous = parseFloat(sd.pre_yield_kg || 0)
                
                // Get actual from latest harvest
                const actual = c.latestHarvest ? parseFloat(c.latestHarvest.yield_kg || 0) : 0

                farmMap[farmId].clusters.push({
                    id: c.id,
                    name: c.cluster_name,
                    predicted: Math.round(predicted),
                    actual: Math.round(actual),
                    previous: Math.round(previous),
                    stage: c.plant_stage,
                    season: sd.season || 'N/A',
                })
                farmMap[farmId].totalPredicted += predicted
                farmMap[farmId].totalActual += actual
                farmMap[farmId].totalPrevious += previous

                // Build per-season data for the farm
                const season = sd.season || 'Unknown'
                if (!farmMap[farmId].seasonData[season]) {
                    farmMap[farmId].seasonData[season] = { season, predicted: 0, actual: 0 }
                }
                farmMap[farmId].seasonData[season].predicted += predicted
                farmMap[farmId].seasonData[season].actual += actual
            })

            setFarmData(Object.values(farmMap).map((f) => ({
                ...f,
                totalPredicted: Math.round(f.totalPredicted),
                totalActual: Math.round(f.totalActual),
                totalPrevious: Math.round(f.totalPrevious),
                seasonTrends: Object.values(f.seasonData).map(s => ({
                    ...s,
                    predicted: Math.round(s.predicted),
                    actual: Math.round(s.actual),
                })),
            })))
        } catch (err) {
            console.error('Error fetching prediction data:', err)
        }
        setLoading(false)
    }

    const handleExportCSV = () => {
        if (viewMode === 'overall') {
            exportToCSV(
                overallData.map(row => ({
                    'Season': row.season,
                    'Predicted Yield (kg)': row.predicted,
                    'Actual Yield (kg)': row.actual,
                    'Fine (kg)': row.fine || 0,
                    'Premium (kg)': row.premium || 0,
                    'Commercial (kg)': row.commercial || 0,
                })),
                `prediction_overall_${new Date().toISOString().split('T')[0]}.csv`
            )
        } else {
            exportToCSV(
                farmData.map(farm => ({
                    'Farm': farm.farmName,
                    'Farmer': farm.farmerName,
                    'Predicted (kg)': farm.totalPredicted,
                    'Actual (kg)': farm.totalActual,
                    'Previous (kg)': farm.totalPrevious,
                    'Clusters': farm.clusters.length,
                })),
                `prediction_farms_${new Date().toISOString().split('T')[0]}.csv`
            )
        }
    }

    if (loading) {
        return (
            <div className="admin-loading">
                <div className="admin-loading-spinner"></div>
                <p>Loading prediction data...</p>
            </div>
        )
    }

    return (
        <div className="prediction-page">
            <div className="prediction-header">
                <div>
                    <h1>Yield Prediction</h1>
                    <p>Overall yield analysis and per-farm comparison</p>
                </div>
                <div className="prediction-controls">
                    <button className="prediction-refresh-btn" onClick={fetchPredictionData}>
                        <RefreshCw size={16} /> Refresh
                    </button>
                    <button
                        className={`prediction-toggle ${viewMode === 'overall' ? 'active' : ''}`}
                        onClick={() => setViewMode(viewMode === 'overall' ? 'farm' : 'overall')}
                    >
                        {viewMode === 'overall' ? <ToggleLeft size={20} /> : <ToggleRight size={20} />}
                        {viewMode === 'overall' ? 'Overall View' : 'Per-Farm View'}
                    </button>
                    <button className="prediction-export-btn" onClick={handleExportCSV}>
                        <Download size={16} /> Export CSV
                    </button>
                </div>
            </div>

            {viewMode === 'overall' ? (
                /* ===== OVERALL VIEW ===== */
                <div className="prediction-overall">
                    <div className="prediction-chart-card">
                        <h3><TrendingUp size={18} /> Multi-Year Yield Comparison</h3>
                        <p>Predicted vs Actual yield across seasons</p>
                        <ResponsiveContainer width="100%" height={400}>
                            <BarChart data={overallData} barGap={8}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                                <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                                <Tooltip
                                    contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0' }}
                                    formatter={(val) => [`${val.toLocaleString()} kg`]}
                                />
                                <Legend />
                                <Bar dataKey="predicted" fill="#f59e0b" name="Predicted Yield" radius={[6, 6, 0, 0]} />
                                <Bar dataKey="actual" fill="#3b82f6" name="Actual Yield" radius={[6, 6, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>

                    {/* Grade Distribution by Season */}
                    <div className="prediction-chart-card">
                        <h3>Grade Distribution by Season</h3>
                        <p>Fine, Premium, and Commercial grade yields</p>
                        <ResponsiveContainer width="100%" height={300}>
                            <BarChart data={overallData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                                <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                                <Tooltip
                                    contentStyle={{ borderRadius: 8 }}
                                    formatter={(val) => [`${val.toLocaleString()} kg`]}
                                />
                                <Legend />
                                <Bar dataKey="fine" stackId="a" fill={GRADE_COLORS[0]} name="Fine" />
                                <Bar dataKey="premium" stackId="a" fill={GRADE_COLORS[1]} name="Premium" />
                                <Bar dataKey="commercial" stackId="a" fill={GRADE_COLORS[2]} name="Commercial" />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>

                    {/* Summary Cards */}
                    <div className="prediction-summary-grid">
                        {overallData.map((season) => {
                            const diff = season.actual - season.predicted
                            const pct = season.predicted > 0 ? ((diff / season.predicted) * 100).toFixed(1) : 0
                            return (
                                <div key={season.season} className="prediction-summary-card">
                                    <h4>{season.season}</h4>
                                    <div className="prediction-summary-row">
                                        <span>Predicted:</span>
                                        <strong>{season.predicted.toLocaleString()} kg</strong>
                                    </div>
                                    <div className="prediction-summary-row">
                                        <span>Actual:</span>
                                        <strong>{season.actual.toLocaleString()} kg</strong>
                                    </div>
                                    <div className={`prediction-diff ${diff >= 0 ? 'positive' : 'negative'}`}>
                                        {diff >= 0 ? '+' : ''}{pct}% {diff >= 0 ? 'Over' : 'Under'}
                                    </div>
                                </div>
                            )
                        })}
                    </div>
                </div>
            ) : (
                /* ===== PER-FARM VIEW ===== */
                <div className="prediction-farm-view">
                    {farmData.length > 0 ? farmData.map((farm) => (
                        <div key={farm.id} className="prediction-farm-card">
                            <div
                                className="prediction-farm-header"
                                onClick={() => setExpandedFarm(expandedFarm === farm.id ? null : farm.id)}
                            >
                                <div className="prediction-farm-info">
                                    {expandedFarm === farm.id ? <ChevronDown size={18} /> : <ChevronRight size={18} />}
                                    <div>
                                        <h4>{farm.farmName}</h4>
                                        <span className="prediction-farmer-name">{farm.farmerName}</span>
                                    </div>
                                </div>
                                <div className="prediction-farm-stats">
                                    <div className="prediction-stat">
                                        <span>Predicted</span>
                                        <strong>{farm.totalPredicted.toLocaleString()} kg</strong>
                                    </div>
                                    <div className="prediction-stat">
                                        <span>Actual</span>
                                        <strong>{farm.totalActual.toLocaleString()} kg</strong>
                                    </div>
                                    <div className="prediction-stat">
                                        <span>Previous</span>
                                        <strong>{farm.totalPrevious.toLocaleString()} kg</strong>
                                    </div>
                                    <div className="prediction-stat">
                                        <span>Clusters</span>
                                        <strong>{farm.clusters.length}</strong>
                                    </div>
                                </div>
                            </div>

                            {expandedFarm === farm.id && (
                                <div className="prediction-farm-expanded">
                                    {/* Mini chart for farm season trends */}
                                    {farm.seasonTrends?.length > 0 && (
                                        <div className="prediction-farm-mini-chart">
                                            <h5>Season Trends</h5>
                                            <ResponsiveContainer width="100%" height={150}>
                                                <LineChart data={farm.seasonTrends}>
                                                    <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                                    <XAxis dataKey="season" fontSize={10} />
                                                    <YAxis fontSize={10} tickFormatter={(v) => `${v}`} />
                                                    <Tooltip formatter={(val) => [`${val.toLocaleString()} kg`]} />
                                                    <Line type="monotone" dataKey="predicted" stroke="#f59e0b" strokeWidth={2} dot={{ r: 3 }} name="Predicted" />
                                                    <Line type="monotone" dataKey="actual" stroke="#3b82f6" strokeWidth={2} dot={{ r: 3 }} name="Actual" />
                                                </LineChart>
                                            </ResponsiveContainer>
                                        </div>
                                    )}
                                    
                                    <table className="prediction-cluster-table">
                                        <thead>
                                            <tr>
                                                <th>Cluster</th>
                                                <th>Stage</th>
                                                <th>Season</th>
                                                <th>Predicted (kg)</th>
                                                <th>Actual (kg)</th>
                                                <th>Previous (kg)</th>
                                                <th>Difference</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {farm.clusters.map((cluster) => {
                                                const diff = cluster.actual - cluster.predicted
                                                return (
                                                    <tr key={cluster.id}>
                                                        <td className="cluster-name-bold">{cluster.name}</td>
                                                        <td>
                                                            <span className={`stage-tag stage-${cluster.stage?.toLowerCase()}`}>{cluster.stage || 'N/A'}</span>
                                                        </td>
                                                        <td>{cluster.season}</td>
                                                        <td>{cluster.predicted.toLocaleString()}</td>
                                                        <td>{cluster.actual.toLocaleString()}</td>
                                                        <td>{cluster.previous.toLocaleString()}</td>
                                                        <td className={diff >= 0 ? 'text-green' : 'text-red'}>
                                                            {diff >= 0 ? '+' : ''}{diff.toLocaleString()} kg
                                                        </td>
                                                    </tr>
                                                )
                                            })}
                                        </tbody>
                                    </table>
                                </div>
                            )}
                        </div>
                    )) : (
                        <div className="admin-empty-state">
                            <TrendingUp size={40} />
                            <p>No farm data available for prediction analysis.</p>
                        </div>
                    )}
                </div>
            )}
        </div>
    )
}
