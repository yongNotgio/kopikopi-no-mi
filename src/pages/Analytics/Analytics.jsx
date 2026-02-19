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
    Layers,
    Coffee,
    AlertTriangle,
    CheckCircle,
    Minus,
} from 'lucide-react'
import {
    BarChart, Bar, LineChart, Line, PieChart as RechartPie, Pie, Cell,
    XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer,
} from 'recharts'
import { fetchFarmerAnalytics, exportToCSV, GRADE_COLORS, STATUS_COLORS, getYieldStatus, arrLastFloat } from '../../lib/analyticsService'
import './Analytics.css'

export default function Analytics() {
    const { user } = useAuth()
    const { farm } = useFarm()
    const [loading, setLoading] = useState(true)
    const [analyticsData, setAnalyticsData] = useState({
        farm: null,
        clusters: [],
        totalYield: 0,
        totalClusters: 0,
        avgFinePct: 0,
        yieldDropRate: 0,
        yieldTrends: [],
        gradeDistribution: [],
        gradeBySeasonData: [],
        yieldStatusCounts: {},
        clusterYieldHistory: [],
        clusterNames: [],
    })
    const [refreshKey, setRefreshKey] = useState(0)

    useEffect(() => {
        if (!user?.id) return

        let isMounted = true

        const loadData = async () => {
            setLoading(true)
            try {
                const data = await fetchFarmerAnalytics(user.id)

                if (!isMounted) return

                // Calculate total yield from harvests
                let totalYield = 0
                let gradeFine = 0
                let gradePremium = 0
                let gradeCommercial = 0
                let yieldDropCount = 0
                let totalWithPrevious = 0

                // Yield status counts
                const yieldStatusCounts = {
                    'Critical Drop (>20%)': 0,
                    'Moderate Drop (5-20%)': 0,
                    'Stable (±5%)': 0,
                    'Improvement (>5%)': 0,
                }

                data.clusters?.forEach((c) => {
                    const harvests = c.allHarvests || []
                    harvests.forEach(h => {
                        totalYield += arrLastFloat(h.yield_kg)
                        gradeFine += arrLastFloat(h.grade_fine)
                        gradePremium += arrLastFloat(h.grade_premium)
                        gradeCommercial += arrLastFloat(h.grade_commercial)
                    })

                    // Use previous harvest record's total for yield drop detection
                    const currentYield = arrLastFloat(c.latestHarvest?.yield_kg)
                    const previousYield = c.previousHarvestYield || 0
                    if (previousYield > 0) {
                        totalWithPrevious++
                        const status = getYieldStatus(currentYield, previousYield)
                        if (yieldStatusCounts[status] !== undefined) {
                            yieldStatusCounts[status]++
                        }
                        if (currentYield < previousYield * 0.95) {
                            yieldDropCount++
                        }
                    }
                })

                // Calculate avg fine percentage
                const totalGrade = gradeFine + gradePremium + gradeCommercial
                const avgFinePct = totalGrade > 0 ? ((gradeFine / totalGrade) * 100).toFixed(1) : 0
                const yieldDropRate = totalWithPrevious > 0 ? ((yieldDropCount / totalWithPrevious) * 100).toFixed(1) : 0

                // Build grade distribution (total kg)
                const gradeDistribution = [
                    { name: 'Fine', value: Math.round(gradeFine) },
                    { name: 'Premium', value: Math.round(gradePremium) },
                    { name: 'Commercial', value: Math.round(gradeCommercial) },
                ].filter(g => g.value > 0)

                // Build grade by season data for stacked bar chart
                const gradeBySeasonData = (data.yieldTrends || []).map(t => ({
                    season: t.season,
                    fine: t.fine || 0,
                    premium: t.premium || 0,
                    commercial: t.commercial || 0,
                }))

                // Build per-cluster yield history: each cluster contributes all past season totals
                // sorted oldest-first, keyed by cluster name. Used for multi-line history chart.
                const allSeasons = [...new Set(
                    (data.clusters || []).flatMap(c =>
                        (c.allHarvests || []).map(h => h.season || h.actual_harvest_date?.slice(0, 7) || 'Unknown')
                    )
                )].sort()

                const clusterYieldHistory = allSeasons.map(season => {
                    const entry = { season }
                    ;(data.clusters || []).forEach(c => {
                        const match = (c.allHarvests || []).find(h =>
                            (h.season || h.actual_harvest_date?.slice(0, 7) || 'Unknown') === season
                        )
                        entry[c.cluster_name || c.id] = match ? arrLastFloat(match.yield_kg) : null
                    })
                    return entry
                })

                const clusterNames = (data.clusters || []).map(c => c.cluster_name || c.id)

                if (!isMounted) return

                setAnalyticsData({
                    farm: data.farm,
                    clusters: data.clusters || [],
                    totalYield: Math.round(totalYield),
                    totalClusters: data.clusters?.length || 0,
                    avgFinePct,
                    yieldDropRate,
                    yieldTrends: data.yieldTrends || [],
                    gradeDistribution,
                    gradeBySeasonData,
                    yieldStatusCounts,
                    clusterYieldHistory,
                    clusterNames,
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
            analyticsData.yieldTrends.map(t => ({
                'Season': t.season,
                'Total Yield (kg)': t.actual,
                'Fine (kg)': t.fine,
                'Premium (kg)': t.premium,
                'Commercial (kg)': t.commercial,
            })),
            `${farm?.farm_name || 'farm'}_analytics_${new Date().toISOString().split('T')[0]}.csv`
        )
    }

    // Build yield status chart data
    const yieldStatusData = Object.entries(analyticsData.yieldStatusCounts).map(([status, count]) => ({
        status,
        count,
        fill: STATUS_COLORS[status] || '#94a3b8',
    }))

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

            {/* KPI Cards - Matching Streamlit Overview */}
            <div className="analytics-kpi-grid">
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#ecfdf5' }}>
                        <Coffee size={24} color="#059669" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Total Yield</span>
                        <strong>{analyticsData.totalYield.toLocaleString()} kg</strong>
                    </div>
                </div>
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#fef3c7' }}>
                        <Layers size={24} color="#d97706" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Clusters</span>
                        <strong>{analyticsData.totalClusters}</strong>
                    </div>
                </div>
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#dcfce7' }}>
                        <BarChart3 size={24} color="#16a34a" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Avg Fine %</span>
                        <strong>{analyticsData.avgFinePct}%</strong>
                    </div>
                </div>
                <div className="analytics-kpi-card">
                    <div className="analytics-kpi-icon" style={{ background: '#fef2f2' }}>
                        <TrendingDown size={24} color="#dc2626" />
                    </div>
                    <div className="analytics-kpi-content">
                        <span>Yield Drop Rate</span>
                        <strong>{analyticsData.yieldDropRate}%</strong>
                    </div>
                </div>
            </div>

            {/* Charts Section - Row 1: Yield by Season + Grade Pie */}
            <div className="analytics-charts-grid">
                {/* Total Yield per Season - Bar Chart (Streamlit Overview) */}
                <div className="analytics-chart-card analytics-chart-wide">
                    <h3><BarChart3 size={18} /> Total Yield per Season</h3>
                    <p>Harvest yield totals across seasons</p>
                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={analyticsData.yieldTrends.length > 0 ? analyticsData.yieldTrends : [{ season: 'No Data', actual: 0 }]}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                            <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                            <Tooltip
                                contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0' }}
                                formatter={(val) => [`${val.toLocaleString()} kg`]}
                            />
                            <Bar dataKey="actual" fill="#4A7C59" name="Total Yield (kg)" radius={[4, 4, 0, 0]}>
                                {analyticsData.yieldTrends.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill="#4A7C59" />
                                ))}
                            </Bar>
                        </BarChart>
                    </ResponsiveContainer>
                </div>

                {/* Grade Distribution Pie (Streamlit Overview) */}
                <div className="analytics-chart-card">
                    <h3><PieChart size={18} /> Overall Grade Composition</h3>
                    <p>Bean quality breakdown (kg)</p>
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

            {/* Charts Section - Row 2: Grade by Season + Yield Status */}
            <div className="analytics-charts-grid">
                {/* Grade % by Season - Stacked Bar (Streamlit Grade Distribution) */}
                <div className="analytics-chart-card analytics-chart-wide">
                    <h3><BarChart3 size={18} /> Grade Distribution by Season</h3>
                    <p>Fine, Premium, and Commercial yields per season</p>
                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={analyticsData.gradeBySeasonData.length > 0 ? analyticsData.gradeBySeasonData : [{ season: 'No Data', fine: 0, premium: 0, commercial: 0 }]}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                            <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                            <Tooltip
                                contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0' }}
                                formatter={(val) => [`${val.toLocaleString()} kg`]}
                            />
                            <Legend />
                            <Bar dataKey="fine" stackId="a" fill="#1B5E20" name="Fine" />
                            <Bar dataKey="premium" stackId="a" fill="#66BB6A" name="Premium" />
                            <Bar dataKey="commercial" stackId="a" fill="#C8E6C9" name="Commercial" />
                        </BarChart>
                    </ResponsiveContainer>
                </div>

                {/* Yield Status Distribution (Streamlit Yield Drop Detection) */}
                <div className="analytics-chart-card">
                    <h3><AlertTriangle size={18} /> Yield Status</h3>
                    <p>Season-over-season yield comparison</p>
                    <ResponsiveContainer width="100%" height={250}>
                        <BarChart data={yieldStatusData} layout="vertical">
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis type="number" fontSize={12} tick={{ fill: '#64748b' }} />
                            <YAxis dataKey="status" type="category" fontSize={10} tick={{ fill: '#64748b' }} width={120} />
                            <Tooltip />
                            <Bar dataKey="count" name="Clusters">
                                {yieldStatusData.map((entry, index) => (
                                    <Cell key={`cell-${index}`} fill={entry.fill} />
                                ))}
                            </Bar>
                        </BarChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Per-Cluster Yield History — shows each cluster's season totals over time */}
            {analyticsData.clusterYieldHistory.length > 1 && (
                <div className="analytics-charts-grid">
                    <div className="analytics-chart-card" style={{ gridColumn: '1 / -1' }}>
                        <h3><TrendingUp size={18} /> Per-Cluster Yield History</h3>
                        <p>Season totals per cluster derived from harvest records — this is historical yield, not a prediction</p>
                        <ResponsiveContainer width="100%" height={300}>
                            <LineChart data={analyticsData.clusterYieldHistory}>
                                <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                                <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                                <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={v => `${v} kg`} />
                                <Tooltip
                                    contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0' }}
                                    formatter={(val, name) => val != null ? [`${Number(val).toLocaleString()} kg`, name] : ['—', name]}
                                />
                                <Legend />
                                {analyticsData.clusterNames.map((name, i) => (
                                    <Line
                                        key={name}
                                        type="monotone"
                                        dataKey={name}
                                        stroke={['#4A7C59', '#3b82f6', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'][i % 6]}
                                        strokeWidth={2}
                                        dot={{ r: 4 }}
                                        connectNulls={false}
                                    />
                                ))}
                            </LineChart>
                        </ResponsiveContainer>
                    </div>
                </div>
            )}

            {/* Yield Status Metrics (Streamlit Yield Drop Detection) */}
            <div className="analytics-status-section">
                <h3>Yield Status Summary</h3>
                <div className="analytics-status-grid">
                    <div className="analytics-status-card critical">
                        <TrendingDown size={20} />
                        <div>
                            <span>Critical Drop (&gt;20%)</span>
                            <strong>{analyticsData.yieldStatusCounts['Critical Drop (>20%)'] || 0}</strong>
                        </div>
                    </div>
                    <div className="analytics-status-card moderate">
                        <TrendingDown size={20} />
                        <div>
                            <span>Moderate Drop (5-20%)</span>
                            <strong>{analyticsData.yieldStatusCounts['Moderate Drop (5-20%)'] || 0}</strong>
                        </div>
                    </div>
                    <div className="analytics-status-card stable">
                        <Minus size={20} />
                        <div>
                            <span>Stable (±5%)</span>
                            <strong>{analyticsData.yieldStatusCounts['Stable (±5%)'] || 0}</strong>
                        </div>
                    </div>
                    <div className="analytics-status-card improvement">
                        <TrendingUp size={20} />
                        <div>
                            <span>Improvement (&gt;5%)</span>
                            <strong>{analyticsData.yieldStatusCounts['Improvement (>5%)'] || 0}</strong>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}
