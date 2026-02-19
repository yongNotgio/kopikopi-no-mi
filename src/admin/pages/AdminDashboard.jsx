import { useState, useEffect } from 'react'
import {
    Users,
    Sprout,
    Layers,
    TrendingUp,
    TrendingDown,
    AlertTriangle,
    Download,
    Eye,
    Bell,
    CheckSquare,
    ClipboardList,
    ArrowUpRight,
    ArrowDownRight,
    X,
    Filter,
    RefreshCw,
} from 'lucide-react'
import ConfirmDialog from '../../components/ConfirmDialog/ConfirmDialog'
import {
    LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend,
    ResponsiveContainer, PieChart, Pie, Cell, BarChart, Bar,
} from 'recharts'
import {
    fetchAdminAnalytics,
    RISK_COLORS,
    GRADE_COLORS,
    generateRecommendations,
    exportToCSV,
} from '../../lib/analyticsService'
import './AdminDashboard.css'

export default function AdminDashboard() {
    const [stats, setStats] = useState({
        totalFarmers: 0,
        totalFarms: 0,
        totalClusters: 0,
        predictedYield: 0,
        actualYield: 0,
        previousYield: 0,
    })
    const [criticalFarms, setCriticalFarms] = useState([])
    const [yieldTrend, setYieldTrend] = useState([])
    const [gradeDistribution, setGradeDistribution] = useState([])
    const [selectedCluster, setSelectedCluster] = useState(null)
    const [clusterRecommendations, setClusterRecommendations] = useState([])
    const [auditLogs, setAuditLogs] = useState([])
    const [sortField, setSortField] = useState('priorityScore')
    const [sortDir, setSortDir] = useState('desc')
    const [selectedRows, setSelectedRows] = useState([])
    const [loading, setLoading] = useState(true)
    const [seasonFilter, setSeasonFilter] = useState('all')
    const [seasons, setSeasons] = useState([])

    // Dialog states
    const [bulkActionDialog, setBulkActionDialog] = useState({ open: false, action: '', count: 0 })
    const [assignDialog, setAssignDialog] = useState({ open: false, clusterName: '' })
    const [notifyDialog, setNotifyDialog] = useState({ open: false, clusterName: '' })
    const [exportDialog, setExportDialog] = useState(false)
    const [refreshKey, setRefreshKey] = useState(0)

    // Audit log function
    const addAuditLog = (action) => {
        setAuditLogs((prev) => [
            { time: new Date().toLocaleString(), action, user: 'Admin' },
            ...prev,
        ].slice(0, 50))
    }

    useEffect(() => {
        let isMounted = true
        
        const fetchData = async () => {
            setLoading(true)
            try {
                const data = await fetchAdminAnalytics()
                
                if (!isMounted) return

                setStats({
                    totalFarmers: data.stats.totalFarmers,
                    totalFarms: data.stats.totalFarms,
                    totalClusters: data.stats.totalClusters,
                    predictedYield: data.stats.predictedYield,
                    actualYield: data.stats.actualYield,
                    previousYield: data.stats.previousYield,
                })

                // Extract unique seasons
                const uniqueSeasons = [...new Set(
                    data.yieldTrends.map(t => t.season).filter(Boolean)
                )].sort()
                setSeasons(uniqueSeasons)

                // Grade distribution for donut chart
                const totalGrade = data.stats.gradeFine + data.stats.gradePremium + data.stats.gradeCommercial
                setGradeDistribution(totalGrade > 0 ? [
                    { name: 'Fine', value: Math.round((data.stats.gradeFine / totalGrade) * 100), kg: data.stats.gradeFine },
                    { name: 'Premium', value: Math.round((data.stats.gradePremium / totalGrade) * 100), kg: data.stats.gradePremium },
                    { name: 'Commercial', value: Math.round((data.stats.gradeCommercial / totalGrade) * 100), kg: data.stats.gradeCommercial },
                ] : [
                    { name: 'Fine', value: 33, kg: 0 },
                    { name: 'Premium', value: 34, kg: 0 },
                    { name: 'Commercial', value: 33, kg: 0 },
                ])

                // Yield trends
                setYieldTrend(data.yieldTrends.length > 0 ? data.yieldTrends : [
                    { season: 'No Data', predicted: 0, actual: 0 },
                ])

                // Critical farms: clusters with risk level not Low
                const critical = (data.clusters || [])
                    .filter(c => c.riskLevel !== 'Low')
                    .map(c => ({
                        id: c.id,
                        farmId: c.farm?.id,
                        farmName: c.farm?.farm_name || 'Unknown Farm',
                        farmerName: c.farmer ? `${c.farmer.first_name} ${c.farmer.last_name}` : 'N/A',
                        farmerId: c.farmer?.id,
                        clusterName: c.cluster_name,
                        riskLevel: c.riskLevel,
                        yieldDecline: parseFloat(c.yieldDecline) || 0,
                        priorityScore: c.priority,
                        soilPh: c.stageData?.soil_ph || 'N/A',
                        moisture: c.stageData?.bean_moisture || 'N/A',
                        avgTemp: c.stageData?.avg_temp_c || 'N/A',
                        avgRainfall: c.stageData?.avg_rainfall_mm || 'N/A',
                        avgHumidity: c.stageData?.avg_humidity_pct || 'N/A',
                        predictedYield: parseFloat(c.stageData?.predicted_yield) || 0,
                        actualYield: parseFloat(c.latestHarvest?.yield_kg) || 0,
                        previousYield: parseFloat(c.stageData?.pre_yield_kg) || 0,
                        plantStage: c.plant_stage,
                        plantCount: c.plant_count,
                        defectCount: c.stageData?.defect_count || 0,
                        season: c.stageData?.season || 'N/A',
                        harvestRecords: c.allHarvests || [],
                        stageData: c.stageData,
                    }))

                setCriticalFarms(critical)

                // Add initial audit log
                if (isMounted) addAuditLog('Dashboard loaded')
            } catch (err) {
                console.error('Error fetching dashboard data:', err)
            }
            if (isMounted) setLoading(false)
        }
        
        fetchData()
        
        return () => { isMounted = false }
    }, [refreshKey])

    const handleRefresh = () => setRefreshKey(k => k + 1)

    const handleSort = (field) => {
        if (sortField === field) {
            setSortDir(sortDir === 'asc' ? 'desc' : 'asc')
        } else {
            setSortField(field)
            setSortDir('desc')
        }
        addAuditLog(`Sorted critical farms by ${field}`)
    }

    // Filter critical farms by season
    const filteredCriticalFarms = seasonFilter === 'all'
        ? criticalFarms
        : criticalFarms.filter(f => f.season === seasonFilter)

    const sortedCriticalFarms = [...filteredCriticalFarms].sort((a, b) => {
        const riskOrder = { Critical: 4, High: 3, Moderate: 2, Low: 1 }
        let aVal, bVal
        if (sortField === 'riskLevel') {
            aVal = riskOrder[a.riskLevel]; bVal = riskOrder[b.riskLevel]
        } else if (sortField === 'yieldDecline') {
            aVal = a.yieldDecline; bVal = b.yieldDecline
        } else if (sortField === 'priorityScore') {
            aVal = a.priorityScore; bVal = b.priorityScore
        } else {
            aVal = a[sortField]; bVal = b[sortField]
        }
        return sortDir === 'asc' ? (aVal > bVal ? 1 : -1) : (aVal < bVal ? 1 : -1)
    })

    const toggleRowSelect = (id) => {
        setSelectedRows((prev) =>
            prev.includes(id) ? prev.filter((r) => r !== id) : [...prev, id]
        )
    }

    const handleBulkAction = (action) => {
        setBulkActionDialog({ open: true, action, count: selectedRows.length })
    }

    const doBulkAction = () => {
        addAuditLog(`Bulk action: ${bulkActionDialog.action} on ${bulkActionDialog.count} cluster(s)`)
        setSelectedRows([])
        setBulkActionDialog({ open: false, action: '', count: 0 })
    }

    const handleAssign = (farm) => {
        setAssignDialog({ open: true, clusterName: farm.clusterName })
    }

    const doAssign = () => {
        addAuditLog(`Assigned task for: ${assignDialog.clusterName}`)
        setAssignDialog({ open: false, clusterName: '' })
    }

    const handleNotify = (farm) => {
        setNotifyDialog({ open: true, clusterName: farm.clusterName })
    }

    const doNotify = () => {
        addAuditLog(`Notified farmer for: ${notifyDialog.clusterName}`)
        setNotifyDialog({ open: false, clusterName: '' })
    }

    const handleViewCluster = (farm) => {
        // Generate recommendations for this cluster
        const recs = generateRecommendations({
            id: farm.id,
            cluster_name: farm.clusterName,
            stageData: farm.stageData,
        })
        setClusterRecommendations(recs)
        setSelectedCluster(farm)
        addAuditLog(`Viewed cluster: ${farm.clusterName}`)
    }

    const handleExportReport = () => {
        setExportDialog(true)
    }

    const doExport = () => {
        // Export KPI data
        const exportData = sortedCriticalFarms.map(f => ({
            'Farm Name': f.farmName,
            'Farmer': f.farmerName,
            'Cluster': f.clusterName,
            'Risk Level': f.riskLevel,
            'Priority': f.priorityScore,
            'Yield Decline (%)': f.yieldDecline,
            'Predicted Yield (kg)': f.predictedYield,
            'Actual Yield (kg)': f.actualYield,
            'Previous Yield (kg)': f.previousYield,
            'Soil pH': f.soilPh,
            'Bean Moisture (%)': f.moisture,
            'Defect Count': f.defectCount,
            'Season': f.season,
        }))
        exportToCSV(exportData, `kpi_report_${new Date().toISOString().split('T')[0]}.csv`)
        addAuditLog('Exported KPI report')
        setExportDialog(false)
    }

    const yieldDiff = stats.actualYield - stats.predictedYield
    const yieldDiffPct = stats.predictedYield > 0
        ? ((yieldDiff / stats.predictedYield) * 100).toFixed(1)
        : 0
    const isOverProduction = yieldDiff >= 0

    const yoyChange = stats.previousYield > 0
        ? (((stats.actualYield - stats.previousYield) / stats.previousYield) * 100).toFixed(1)
        : 0

    if (loading) {
        return (
            <div className="admin-loading">
                <div className="admin-loading-spinner"></div>
                <p>Loading dashboard...</p>
            </div>
        )
    }

    return (
        <div className="admin-dashboard">
            <div className="admin-dash-header">
                <div>
                    <h1>Dashboard</h1>
                    <p>Overview of all farms, clusters, and yield performance</p>
                </div>
                <div className="admin-header-actions">
                    <button className="admin-refresh-btn" onClick={handleRefresh}>
                        <RefreshCw size={16} /> Refresh
                    </button>
                    <button className="admin-export-btn" onClick={handleExportReport}>
                        <Download size={16} /> Export Report
                    </button>
                </div>
            </div>

            {/* KPI Cards */}
            <div className="admin-kpi-grid">
                <div className="admin-kpi-card">
                    <div className="admin-kpi-icon" style={{ background: 'rgba(59, 130, 246, 0.1)', color: '#3b82f6' }}>
                        <Users size={22} />
                    </div>
                    <div className="admin-kpi-data">
                        <span className="admin-kpi-value">{stats.totalFarmers}</span>
                        <span className="admin-kpi-label">Registered Farmers</span>
                    </div>
                </div>
                <div className="admin-kpi-card">
                    <div className="admin-kpi-icon" style={{ background: 'rgba(34, 197, 94, 0.1)', color: '#22c55e' }}>
                        <Sprout size={22} />
                    </div>
                    <div className="admin-kpi-data">
                        <span className="admin-kpi-value">{stats.totalFarms}</span>
                        <span className="admin-kpi-label">Active Farms</span>
                    </div>
                </div>
                <div className="admin-kpi-card">
                    <div className="admin-kpi-icon" style={{ background: 'rgba(168, 85, 247, 0.1)', color: '#a855f7' }}>
                        <Layers size={22} />
                    </div>
                    <div className="admin-kpi-data">
                        <span className="admin-kpi-value">{stats.totalClusters}</span>
                        <span className="admin-kpi-label">Active Clusters</span>
                    </div>
                </div>
                <div className="admin-kpi-card">
                    <div className="admin-kpi-icon" style={{ background: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b' }}>
                        <TrendingUp size={22} />
                    </div>
                    <div className="admin-kpi-data">
                        <span className="admin-kpi-value">{stats.predictedYield.toLocaleString()} kg</span>
                        <span className="admin-kpi-label">Predicted Yield (Season)</span>
                    </div>
                </div>
                <div className="admin-kpi-card">
                    <div className="admin-kpi-icon" style={{ background: 'rgba(6, 182, 212, 0.1)', color: '#06b6d4' }}>
                        <TrendingDown size={22} />
                    </div>
                    <div className="admin-kpi-data">
                        <span className="admin-kpi-value">{stats.actualYield.toLocaleString()} kg</span>
                        <span className="admin-kpi-label">Actual Yield (Season)</span>
                        {stats.previousYield > 0 && (
                            <span className={`admin-kpi-change ${parseFloat(yoyChange) >= 0 ? 'positive' : 'negative'}`}>
                                {parseFloat(yoyChange) >= 0 ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
                                {yoyChange}% vs prev season
                            </span>
                        )}
                    </div>
                </div>
                <div className="admin-kpi-card">
                    <div className="admin-kpi-icon" style={{ background: isOverProduction ? 'rgba(34, 197, 94, 0.1)' : 'rgba(239, 68, 68, 0.1)', color: isOverProduction ? '#22c55e' : '#ef4444' }}>
                        {isOverProduction ? <ArrowUpRight size={22} /> : <ArrowDownRight size={22} />}
                    </div>
                    <div className="admin-kpi-data">
                        <span className="admin-kpi-value">
                            {isOverProduction ? '+' : ''}{yieldDiffPct}%
                        </span>
                        <span className="admin-kpi-label">
                            {isOverProduction ? 'Over Production' : 'Under Production'}
                        </span>
                    </div>
                </div>
            </div>

            {/* Charts Row */}
            <div className="admin-charts-row">
                {/* Yield Trend Chart */}
                <div className="admin-chart-card">
                    <div className="admin-chart-header">
                        <h3>Yield: Predicted vs Actual (Year-over-Year)</h3>
                    </div>
                    <ResponsiveContainer width="100%" height={280}>
                        <LineChart data={yieldTrend}>
                            <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                            <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                            <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                            <Tooltip
                                contentStyle={{ borderRadius: 8, border: '1px solid #e2e8f0' }}
                                formatter={(value) => [`${value.toLocaleString()} kg`]}
                            />
                            <Legend />
                            <Line type="monotone" dataKey="predicted" stroke="#f59e0b" strokeWidth={2} dot={{ r: 4 }} name="Predicted" />
                            <Line type="monotone" dataKey="actual" stroke="#3b82f6" strokeWidth={2} dot={{ r: 4 }} name="Actual" />
                        </LineChart>
                    </ResponsiveContainer>
                </div>

                {/* Grade Distribution  */}
                <div className="admin-chart-card admin-chart-card--small">
                    <div className="admin-chart-header">
                        <h3>Coffee Grade Distribution</h3>
                    </div>
                    <ResponsiveContainer width="100%" height={280}>
                        <PieChart>
                            <Pie
                                data={gradeDistribution}
                                cx="50%"
                                cy="50%"
                                innerRadius={60}
                                outerRadius={90}
                                dataKey="value"
                                paddingAngle={4}
                                label={({ name, value }) => `${name}: ${value}%`}
                            >
                                {gradeDistribution.map((entry, index) => (
                                    <Cell key={entry.name} fill={GRADE_COLORS[index % GRADE_COLORS.length]} />
                                ))}
                            </Pie>
                            <Tooltip formatter={(v, name, entry) => [`${v}% (${entry.payload.kg} kg)`, name]} />
                            <Legend />
                        </PieChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Grade Distribution Bar Chart */}
            <div className="admin-chart-card admin-chart-full">
                <div className="admin-chart-header">
                    <h3>Grade Distribution by Season</h3>
                </div>
                <ResponsiveContainer width="100%" height={250}>
                    <BarChart data={yieldTrend}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#e2e8f0" />
                        <XAxis dataKey="season" fontSize={12} tick={{ fill: '#64748b' }} />
                        <YAxis fontSize={12} tick={{ fill: '#64748b' }} tickFormatter={(v) => `${v} kg`} />
                        <Tooltip contentStyle={{ borderRadius: 8 }} formatter={(value) => [`${value.toLocaleString()} kg`]} />
                        <Legend />
                        <Bar dataKey="fine" stackId="a" fill={GRADE_COLORS[0]} name="Fine" />
                        <Bar dataKey="premium" stackId="a" fill={GRADE_COLORS[1]} name="Premium" />
                        <Bar dataKey="commercial" stackId="a" fill={GRADE_COLORS[2]} name="Commercial" />
                    </BarChart>
                </ResponsiveContainer>
            </div>

            {/* Critical Farms Table */}
            <div className="admin-critical-section">
                <div className="admin-critical-header">
                    <div>
                        <h3><AlertTriangle size={18} /> Farms Requiring Immediate Attention</h3>
                        <p>{sortedCriticalFarms.length} cluster(s) flagged</p>
                    </div>
                    <div className="admin-critical-controls">
                        <div className="admin-filter-select">
                            <Filter size={14} />
                            <select value={seasonFilter} onChange={(e) => setSeasonFilter(e.target.value)}>
                                <option value="all">All Seasons</option>
                                {seasons.map(s => (
                                    <option key={s} value={s}>{s}</option>
                                ))}
                            </select>
                        </div>
                        {selectedRows.length > 0 && (
                            <div className="admin-bulk-actions">
                                <span>{selectedRows.length} selected</span>
                                <button onClick={() => handleBulkAction('Approve Pest Control')}>
                                    <CheckSquare size={14} /> Approve Pest Control
                                </button>
                                <button onClick={() => handleBulkAction('Assign Task')}>
                                    <ClipboardList size={14} /> Assign Task
                                </button>
                                <button onClick={() => handleBulkAction('Notify Farmer')}>
                                    <Bell size={14} /> Notify Farmer
                                </button>
                            </div>
                        )}
                    </div>
                </div>

                {sortedCriticalFarms.length > 0 ? (
                    <div className="admin-table-wrapper">
                        <table className="admin-table">
                            <thead>
                                <tr>
                                    <th>
                                        <input
                                            type="checkbox"
                                            checked={selectedRows.length === sortedCriticalFarms.length && sortedCriticalFarms.length > 0}
                                            onChange={() => {
                                                if (selectedRows.length === sortedCriticalFarms.length) {
                                                    setSelectedRows([])
                                                } else {
                                                    setSelectedRows(sortedCriticalFarms.map(c => c.id))
                                                }
                                            }}
                                        />
                                    </th>
                                    <th onClick={() => handleSort('farmName')} className="sortable">Farm Name</th>
                                    <th onClick={() => handleSort('farmerName')} className="sortable">Farmer</th>
                                    <th onClick={() => handleSort('clusterName')} className="sortable">Cluster</th>
                                    <th onClick={() => handleSort('riskLevel')} className="sortable">Risk Level</th>
                                    <th onClick={() => handleSort('yieldDecline')} className="sortable">Yield Decline</th>
                                    <th onClick={() => handleSort('priorityScore')} className="sortable">Priority</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                {sortedCriticalFarms.map((farm) => (
                                    <tr key={farm.id}>
                                        <td>
                                            <input
                                                type="checkbox"
                                                checked={selectedRows.includes(farm.id)}
                                                onChange={() => toggleRowSelect(farm.id)}
                                            />
                                        </td>
                                        <td className="farm-name-cell">{farm.farmName}</td>
                                        <td>{farm.farmerName}</td>
                                        <td>{farm.clusterName}</td>
                                        <td>
                                            <span className="risk-badge" style={{ background: RISK_COLORS[farm.riskLevel] + '20', color: RISK_COLORS[farm.riskLevel] }}>
                                                {farm.riskLevel}
                                            </span>
                                        </td>
                                        <td className="decline-cell">
                                            <ArrowDownRight size={14} /> {farm.yieldDecline}%
                                        </td>
                                        <td>
                                            <span className={`priority-badge priority-${farm.priorityScore}`}>
                                                P{farm.priorityScore}
                                            </span>
                                        </td>
                                        <td className="action-cell">
                                            <button className="admin-action-btn" onClick={() => handleViewCluster(farm)}>
                                                <Eye size={14} /> View
                                            </button>
                                            <button className="admin-action-btn admin-action-btn--warn" onClick={() => handleAssign(farm)}>
                                                <ClipboardList size={14} /> Assign
                                            </button>
                                            <button className="admin-action-btn admin-action-btn--info" onClick={() => handleNotify(farm)}>
                                                <Bell size={14} /> Notify
                                            </button>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                ) : (
                    <div className="admin-empty-state">
                        <AlertTriangle size={40} />
                        <p>No critical farms detected. All clusters are healthy.</p>
                    </div>
                )}
            </div>

            {/* Cluster Detail Modal */}
            {selectedCluster && (
                <div className="admin-modal-overlay" onClick={() => setSelectedCluster(null)}>
                    <div className="admin-modal admin-modal--large" onClick={(e) => e.stopPropagation()}>
                        <div className="admin-modal-header">
                            <h2>Cluster Details: {selectedCluster.clusterName}</h2>
                            <button className="admin-modal-close" onClick={() => setSelectedCluster(null)}>
                                <X size={20} />
                            </button>
                        </div>
                        <div className="admin-modal-body">
                            <div className="admin-detail-grid">
                                <div className="admin-detail-item">
                                    <label>Farm</label>
                                    <span>{selectedCluster.farmName}</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Farmer</label>
                                    <span>{selectedCluster.farmerName}</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Risk Level</label>
                                    <span className="risk-badge" style={{ background: RISK_COLORS[selectedCluster.riskLevel] + '20', color: RISK_COLORS[selectedCluster.riskLevel] }}>
                                        {selectedCluster.riskLevel}
                                    </span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Plant Stage</label>
                                    <span>{selectedCluster.plantStage}</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Plant Count</label>
                                    <span>{selectedCluster.plantCount} trees</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Season</label>
                                    <span>{selectedCluster.season}</span>
                                </div>
                            </div>

                            <h3 className="admin-detail-section-title">Yield Performance</h3>
                            <div className="admin-detail-grid">
                                <div className="admin-detail-item">
                                    <label>Predicted Yield</label>
                                    <span>{selectedCluster.predictedYield.toLocaleString()} kg</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Actual Yield</label>
                                    <span>{selectedCluster.actualYield.toLocaleString()} kg</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Previous Yield</label>
                                    <span>{selectedCluster.previousYield.toLocaleString()} kg</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Yield Decline</label>
                                    <span style={{ color: '#ef4444' }}>{selectedCluster.yieldDecline}%</span>
                                </div>
                            </div>

                            <h3 className="admin-detail-section-title">Soil & Environmental Indicators</h3>
                            <div className="admin-detail-grid">
                                <div className="admin-detail-item">
                                    <label>Soil pH</label>
                                    <span>{selectedCluster.soilPh}</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Bean Moisture</label>
                                    <span>{selectedCluster.moisture}%</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Avg Temperature</label>
                                    <span>{selectedCluster.avgTemp}°C</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Avg Rainfall</label>
                                    <span>{selectedCluster.avgRainfall} mm</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Avg Humidity</label>
                                    <span>{selectedCluster.avgHumidity}%</span>
                                </div>
                                <div className="admin-detail-item">
                                    <label>Defect Count</label>
                                    <span>{selectedCluster.defectCount}</span>
                                </div>
                            </div>

                            <h3 className="admin-detail-section-title">Recommended Interventions</h3>
                            {clusterRecommendations.length > 0 ? (
                                <ul className="admin-interventions">
                                    {clusterRecommendations.map((rec, idx) => (
                                        <li key={idx} className={`intervention-${rec.priority.toLowerCase()}`}>
                                            <span className="intervention-priority">
                                                {rec.priority === 'High' ? '🔴' : rec.priority === 'Medium' ? '🟠' : '🟢'}
                                            </span>
                                            <div>
                                                <strong>{rec.factor}</strong>
                                                <p>{rec.recommendation}</p>
                                                <small>Ideal: {rec.ideal}</small>
                                            </div>
                                        </li>
                                    ))}
                                </ul>
                            ) : (
                                <ul className="admin-interventions">
                                    {selectedCluster.riskLevel === 'Critical' && (
                                        <>
                                            <li>🔴 Immediate soil analysis and pH correction</li>
                                            <li>🔴 Urgent pest control inspection required</li>
                                            <li>🔴 Fertilization schedule adjustment — increase NPK</li>
                                        </>
                                    )}
                                    {selectedCluster.riskLevel === 'High' && (
                                        <>
                                            <li>🟠 Schedule pruning within 2 weeks</li>
                                            <li>🟠 Apply organic pesticide treatment</li>
                                            <li>🟠 Monitor shade tree density</li>
                                        </>
                                    )}
                                    {selectedCluster.riskLevel === 'Moderate' && (
                                        <>
                                            <li>🟡 Follow regular fertilization schedule</li>
                                            <li>🟡 Check irrigation levels</li>
                                            <li>🟡 Monitor for early pest signs</li>
                                        </>
                                    )}
                                </ul>
                            )}

                            {/* Harvest History Chart */}
                            {selectedCluster.harvestRecords && selectedCluster.harvestRecords.length > 0 && (
                                <>
                                    <h3 className="admin-detail-section-title">Historical Yield Performance</h3>
                                    <ResponsiveContainer width="100%" height={200}>
                                        <BarChart data={selectedCluster.harvestRecords.map(h => ({
                                            season: h.season,
                                            yield: parseFloat(h.yield_kg) || 0,
                                        }))}>
                                            <CartesianGrid strokeDasharray="3 3" />
                                            <XAxis dataKey="season" fontSize={11} />
                                            <YAxis fontSize={11} tickFormatter={(v) => `${v} kg`} />
                                            <Tooltip formatter={(v) => [`${v} kg`, 'Yield']} />
                                            <Bar dataKey="yield" fill="#4A7C59" />
                                        </BarChart>
                                    </ResponsiveContainer>
                                </>
                            )}
                        </div>
                    </div>
                </div>
            )}

            {/* Audit Logs */}
            <div className="admin-audit-section">
                <h3><ClipboardList size={16} /> Admin Audit Log</h3>
                <div className="admin-audit-list">
                    {auditLogs.map((log, i) => (
                        <div key={i} className="admin-audit-item">
                            <span className="audit-time">{log.time}</span>
                            <span className="audit-action">{log.action}</span>
                            <span className="audit-user">{log.user}</span>
                        </div>
                    ))}
                </div>
            </div>

            {/* Dialogs */}
            <ConfirmDialog
                isOpen={bulkActionDialog.open}
                onClose={() => setBulkActionDialog({ open: false, action: '', count: 0 })}
                onConfirm={doBulkAction}
                title={`${bulkActionDialog.action}?`}
                message={`Apply "${bulkActionDialog.action}" to ${bulkActionDialog.count} selected cluster(s)?`}
                confirmText="Confirm"
                cancelText="Cancel"
                variant="warning"
            />

            <ConfirmDialog
                isOpen={assignDialog.open}
                onClose={() => setAssignDialog({ open: false, clusterName: '' })}
                onConfirm={doAssign}
                title="Assign Task"
                message={`Assign a task for cluster "${assignDialog.clusterName}"?`}
                confirmText="Assign"
                cancelText="Cancel"
                variant="success"
            />

            <ConfirmDialog
                isOpen={notifyDialog.open}
                onClose={() => setNotifyDialog({ open: false, clusterName: '' })}
                onConfirm={doNotify}
                title="Notify Farmer"
                message={`Send a notification to the farmer for cluster "${notifyDialog.clusterName}"?`}
                confirmText="Send Notification"
                cancelText="Cancel"
                variant="success"
            />

            <ConfirmDialog
                isOpen={exportDialog}
                onClose={() => setExportDialog(false)}
                onConfirm={doExport}
                title="Export Report"
                message="Export the KPI dashboard report as CSV? This will include all current stats and critical farm data."
                confirmText="Export CSV"
                cancelText="Cancel"
                variant="success"
            />
        </div>
    )
}
