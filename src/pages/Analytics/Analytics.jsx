import { useState, useEffect } from 'react'
import { useAuth } from '../../context/AuthContext'
import { useFarm } from '../../context/FarmContext'
import {
    TrendingUp,
    TrendingDown,
    BarChart3,
    PieChart,
    RefreshCw,
    Download,
    Leaf,
    Droplet,
    Thermometer,
    AlertTriangle,
    CheckCircle,
} from 'lucide-react'
import {
    LineChart, Line, BarChart, Bar, PieChart as RechartPie, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
} from 'recharts'
import { fetchFarmerAnalytics, exportToCSV, GRADE_COLORS, generateRecommendations } from '../../lib/analyticsService'
import './Analytics.css'

export default function Analytics() {
    const { user } = useAuth()
    const { farm } = useFarm()
    const [loading, setLoading] = useState(true)
    const [analyticsData, setAnalyticsData] = useState({
        farm: null,
        clusters: [],
        totalPredicted: 0,
        totalActual: 0,
        totalTrees: 0,
        avgYieldPerTree: 0,
        yieldTrends: [],
        gradeDistribution: [],
        clusterPerformance: [],
        recommendations: [],
    })
    const [selectedCluster, setSelectedCluster] = useState('all')
    const [refreshKey, setRefreshKey] = useState(0)

    useEffect(() => {
        if (!user?.id) return
        
        let isMounted = true
        
        const loadData = async () => {
            setLoading(true)
            try {
                const data = await fetchFarmerAnalytics(user.id)
                
                if (!isMounted) return
                
                // Process clusters for performance stats
                let totalPredicted = 0
                let totalActual = 0
            let totalTrees = 0
            const clusterPerformance = []
            let allRecommendations = []
            
            data.clusters?.forEach((c) => {
                const sd = c.stageData || {}
                const predicted = parseFloat(sd.predicted_yield || 0)
                const actual = c.latestHarvest ? parseFloat(c.latestHarvest.yield_kg || 0) : 0
                const trees = c.plant_count || 0
                
                totalPredicted += predicted
                totalActual += actual
                totalTrees += trees
                
                clusterPerformance.push({
                    id: c.id,
                    name: c.cluster_name,
                    stage: c.plant_stage,
                    predicted: Math.round(predicted),
                    actual: Math.round(actual),
                    trees,
                    yieldPerTree: trees > 0 ? (actual / trees).toFixed(2) : 0,
                    status: actual >= predicted * 0.9 ? 'good' : actual >= predicted * 0.7 ? 'moderate' : 'poor',
                })
                
                // Generate recommendations for each cluster
                const clusterRecs = generateRecommendations(c)
                allRecommendations = [...allRecommendations, ...clusterRecs.map(r => ({
                    ...r,
                    clusterName: c.cluster_name,
                }))]
            })
            
            if (!isMounted) return
            
            setAnalyticsData({
                farm: data.farm,
                clusters: data.clusters || [],
                totalPredicted: Math.round(totalPredicted),
                totalActual: Math.round(totalActual),
                totalTrees,
                avgYieldPerTree: totalTrees > 0 ? (totalActual / totalTrees).toFixed(2) : 0,
                yieldTrends: data.yieldTrends || [],
                gradeDistribution: data.gradeDistribution || [],
                clusterPerformance,
                recommendations: allRecommendations.slice(0, 10), // Top 10 recommendations
            })
        } catch (err) {
            console.error('Error fetching analytics:', err)
        }
        if (isMounted) setLoading(false)
        }
        
        loadData()
        
        return () => { isMounted = false }
    }, [user?.id, refreshKey])

    const handleRefresh = () => setRefreshKey(k => k + 1)

    const handleExport = () => {
        exportToCSV(
            analyticsData.clusterPerformance.map(c => ({
                'Cluster': c.name,
                'Stage': c.stage,
                'Trees': c.trees,
                'Predicted Yield (kg)': c.predicted,
                'Actual Yield (kg)': c.actual,
                'Yield/Tree (kg)': c.yieldPerTree,
                'Status': c.status,
            })),
            `${farm?.farm_name || 'farm'}_analytics_${new Date().toISOString().split('T')[0]}.csv`
        )
    }

    const filteredClusters = selectedCluster === 'all'
        ? analyticsData.clusterPerformance
        : analyticsData.clusterPerformance.filter(c => c.id === selectedCluster)

    const yieldDiff = analyticsData.totalActual - analyticsData.totalPredicted
    const yieldDiffPct = analyticsData.totalPredicted > 0
        ? ((yieldDiff / analyticsData.totalPredicted) * 100).toFixed(1)
        : 0

    if (loading) {
        return (
            <div className="analytics-loading">
                <div className="analytics-loading-spinner"></div>
                <p>Loading farm analytics...</p>
            </div>
        )
    }

    return (
        <div className="analytics-page">
            <div className="analytics-header">
                <div>
                    <h1>Farm Analytics</h1>
                    <p>{farm?.farm_name || 'Your Farm'} - Performance Overview</p>
                </div>
                <div className="analytics-actions">
                    <button className="analytics-refresh-btn" onClick={handleRefresh}>
                        <RefreshCw size={16} /> Refresh
                    </button>
                    <button className="analytics-export-btn" onClick={handleExport}>
                        <Download size={16} /> Export
                    </button>
                </div>
            </div>

            {/* KPI Cards */}
            <div className="analytics-kpi-grid">
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#ecfdf5' }}>
                        <Leaf size={24} color="#059669" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Total Trees</span>
                        <strong>{analyticsData.totalTrees.toLocaleString()}</strong>
                    </div>
                </div>
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#fef3c7' }}>
                        <TrendingUp size={24} color="#d97706" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Predicted Yield</span>
                        <strong>{analyticsData.totalPredicted.toLocaleString()} kg</strong>
                    </div>
                </div>
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#eff6ff' }}>
                        <BarChart3 size={24} color="#3b82f6" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Actual Yield</span>
                        <strong>{analyticsData.totalActual.toLocaleString()} kg</strong>
                        <span className={`analytics-kpi-change ${yieldDiff >= 0 ? 'positive' : 'negative'}`}>
                            {yieldDiff >= 0 ? '+' : ''}{yieldDiffPct}%
                        </span>
                    </div>
                </div>
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#f5f3ff' }}>
                        <PieChart size={24} color="#8b5cf6" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Avg Yield/Tree</span>
                        <strong>{analyticsData.avgYieldPerTree} kg</strong>
                    </div>
                </div>
            </div>

            {/* Charts Section */}
            <div className="analytics-charts-grid">
                {/* Yield Trends */}
                <div className="analytics-chart-card analytics-chart-wide">
                    <h3><TrendingUp size={18} /> Yield Trends by Season</h3>
                    <p>Predicted vs Actual yield performance</p>
                    <ResponsiveContainer width="100%" height={300}>
                        <LineChart data={analyticsData.yieldTrends.length > 0 ? analyticsData.yieldTrends : [{ season: 'No Data', predicted: 0, actual: 0 }]}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                            <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                            <Tooltip
                                contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0' }}
                                formatter={(val) => [`${val.toLocaleString()} kg`]}
                            />
                            <Legend />
                            <Line
                                type="monotone"
                                dataKey="predicted"
                                stroke="#f59e0b"
                                strokeWidth={2}
                                dot={{ r: 4, fill: '#f59e0b' }}
                                name="Predicted"
                            />
                            <Line
                                type="monotone"
                                dataKey="actual"
                                stroke="#3b82f6"
                                strokeWidth={2}
                                dot={{ r: 4, fill: '#3b82f6' }}
                                name="Actual"
                            />
                        </LineChart>
                    </ResponsiveContainer>
                </div>

                {/* Grade Distribution */}
                <div className="analytics-chart-card">
                    <h3><PieChart size={18} /> Grade Distribution</h3>
                    <p>Bean quality breakdown</p>
                    <ResponsiveContainer width="100%" height={250}>
                        <RechartPie>
                            <Pie
                                data={analyticsData.gradeDistribution.length > 0 ? analyticsData.gradeDistribution : [{ name: 'No Data', value: 1 }]}
                                cx="50%"
                                cy="50%"
                                innerRadius={50}
                                outerRadius={80}
                                paddingAngle={5}
                                dataKey="value"
                                label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                            >
                                {(analyticsData.gradeDistribution.length > 0 ? analyticsData.gradeDistribution : [{ name: 'No Data', value: 1 }]).map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={GRADE_COLORS[index % GRADE_COLORS.length]} />
                                ))}
                            </Pie>
                            <Tooltip formatter={(val) => [`${val.toLocaleString()} kg`]} />
                        </RechartPie>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Cluster Performance */}
            <div className="analytics-cluster-section">
                <div className="analytics-section-header">
                    <h3>Cluster Performance</h3>
                    <select
                        value={selectedCluster}
                        onChange={(e) => setSelectedCluster(e.target.value === 'all' ? 'all' : e.target.value)}
                        className="analytics-filter-select"
                    >
                        <option value="all">All Clusters</option>
                        {analyticsData.clusters.map((c) => (
                            <option key={c.id} value={c.id}>{c.cluster_name}</option>
                        ))}
                    </select>
                </div>

                <div className="analytics-cluster-grid">
                    {filteredClusters.map((cluster) => (
                        <div key={cluster.id} className={`analytics-cluster-card status-${cluster.status}`}>
                            <div className="analytics-cluster-header">
                                <h4>{cluster.name}</h4>
                                <span className={`analytics-cluster-badge ${cluster.status}`}>
                                    {cluster.status === 'good' && <CheckCircle size={14} />}
                                    {cluster.status === 'moderate' && <AlertTriangle size={14} />}
                                    {cluster.status === 'poor' && <TrendingDown size={14} />}
                                    {cluster.status.charAt(0).toUpperCase() + cluster.status.slice(1)}
                                </span>
                            </div>
                            <div className="analytics-cluster-stats">
                                <div className="analytics-cluster-stat">
                                    <span>Stage</span>
                                    <strong>{cluster.stage || 'N/A'}</strong>
                                </div>
                                <div className="analytics-cluster-stat">
                                    <span>Trees</span>
                                    <strong>{cluster.trees.toLocaleString()}</strong>
                                </div>
                                <div className="analytics-cluster-stat">
                                    <span>Predicted</span>
                                    <strong>{cluster.predicted.toLocaleString()} kg</strong>
                                </div>
                                <div className="analytics-cluster-stat">
                                    <span>Actual</span>
                                    <strong>{cluster.actual.toLocaleString()} kg</strong>
                                </div>
                                <div className="analytics-cluster-stat">
                                    <span>Yield/Tree</span>
                                    <strong>{cluster.yieldPerTree} kg</strong>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>

            {/* Recommendations */}
            {analyticsData.recommendations.length > 0 && (
                <div className="analytics-recommendations">
                    <h3><AlertTriangle size={18} /> Recommendations</h3>
                    <p>Action items to improve farm performance</p>
                    <div className="analytics-rec-list">
                        {analyticsData.recommendations.map((rec, idx) => (
                            <div key={idx} className={`analytics-rec-item priority-${rec.priority}`}>
                                <div className="analytics-rec-icon">
                                    {rec.priority === 'high' ? <AlertTriangle size={16} /> : <CheckCircle size={16} />}
                                </div>
                                <div className="analytics-rec-content">
                                    <strong>{rec.clusterName}</strong>
                                    <p>{rec.message}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    )
}
