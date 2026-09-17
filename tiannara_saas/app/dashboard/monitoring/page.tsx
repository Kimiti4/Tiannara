'use client'

import { useState, useEffect } from 'react'
import { Activity, AlertTriangle, CheckCircle, XCircle, TrendingUp, Shield, Archive, Zap, RefreshCw, Clock, Download, Search, Brain, Target, Eye, GitBranch } from 'lucide-react'
import { LineChart, Line, AreaChart, Area, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell, RadarChart, PolarGrid, PolarAngleAxis, PolarRadiusAxis, Radar } from 'recharts'
import { exportToCSV, getTimestampedFilename } from '@/lib/export-utils'

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8004/api/v1'

interface MonitoringOverview {
  bandwidth: {
    status: string
    total_events: number
    active_alerts: number
  }
  immune_system: {
    status: string
    total_anomalies: number
    critical_count: number
  }
  failure_museum: {
    total_failures: number
    total_replays: number
    by_type: Record<string, number>
  }
  deliberate_friction: {
    current_mode: string
    total_decisions: number
    mode_usage: Record<string, number>
  }
  overall_health: string
  timestamp: number
}

interface EpistemicHealthData {
  vital_signs: {
    calibration_accuracy: number
    drift_risk_score: number
    hallucination_probability: number
    evidence_quality_avg: number
    synthesis_stability: number
    dissent_diversity_index: number
  }
  health_dimensions: Record<string, any>
  reality_grounding: {
    overall_grounding_score: number
    drift_risk_level: string
    external_verification: any
    temporal_consistency: any
    physical_constraints: any
    recent_drift_reports: any[]
  }
  trend_analysis: {
    health_history: any[]
    overall_trend: string
    weakest_dimension: string | null
    strongest_dimension: string | null
  }
  alerts: any[]
  recommendations: string[]
}

export default function MonitoringPage() {
  const [overview, setOverview] = useState<MonitoringOverview | null>(null)
  const [epistemicHealth, setEpistemicHealth] = useState<EpistemicHealthData | null>(null)
  const [loading, setLoading] = useState(true)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [bandwidthHistory, setBandwidthHistory] = useState<any[]>([])
  const [anomalyHistory, setAnomalyHistory] = useState<any[]>([])
  const [activeTab, setActiveTab] = useState<'overview' | 'epistemic' | 'reality'>('overview')

  useEffect(() => {
    fetchMonitoringOverview()
    fetchEpistemicHealth()
    
    let interval: NodeJS.Timeout
    if (autoRefresh) {
      interval = setInterval(() => {
        fetchMonitoringOverview()
        fetchEpistemicHealth()
      }, 30000) // Auto-refresh every 30 seconds
    }
    
    return () => {
      if (interval) clearInterval(interval)
    }
  }, [autoRefresh])

  const fetchMonitoringOverview = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/monitoring/dashboard/overview`)
      
      if (response.ok) {
        const data = await response.json()
        setOverview(data)
        setLastUpdated(new Date())
        
        // Update bandwidth history chart
        setBandwidthHistory(prev => {
          const newPoint = {
            time: new Date().toLocaleTimeString(),
            events: data.bandwidth.total_events,
            alerts: data.bandwidth.active_alerts,
          }
          const updated = [...prev, newPoint].slice(-20) // Keep last 20 points
          return updated
        })
        
        // Update anomaly history
        setAnomalyHistory(prev => {
          const newPoint = {
            time: new Date().toLocaleTimeString(),
            anomalies: data.immune_system.total_anomalies,
            critical: data.immune_system.critical_count,
          }
          const updated = [...prev, newPoint].slice(-20)
          return updated
        })
      }
    } catch (error) {
      console.error('Error fetching monitoring overview:', error)
    } finally {
      setLoading(false)
    }
  }

  const fetchEpistemicHealth = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/monitoring/epistemic-health/dashboard`)
      
      if (response.ok) {
        const data = await response.json()
        setEpistemicHealth(data)
      }
    } catch (error) {
      console.error('Error fetching epistemic health:', error)
    }
  }

  const handleExportCSV = () => {
    if (!overview) return
    
    const headers = ['System', 'Status', 'Metric', 'Value']
    const rows = [
      ['Bandwidth Monitor', overview.bandwidth.status, 'Total Events', overview.bandwidth.total_events],
      ['Bandwidth Monitor', overview.bandwidth.status, 'Active Alerts', overview.bandwidth.active_alerts],
      ['Immune System', overview.immune_system.status, 'Total Anomalies', overview.immune_system.total_anomalies],
      ['Immune System', overview.immune_system.status, 'Critical Count', overview.immune_system.critical_count],
      ['Failure Museum', 'N/A', 'Total Failures', overview.failure_museum.total_failures],
      ['Failure Museum', 'N/A', 'Total Replays', overview.failure_museum.total_replays],
      ['Deliberate Friction', 'N/A', 'Current Mode', overview.deliberate_friction.current_mode],
      ['Deliberate Friction', 'N/A', 'Total Decisions', overview.deliberate_friction.total_decisions],
    ]
    
    exportToCSV({
      headers,
      rows,
      filename: getTimestampedFilename('monitoring_overview')
    })
  }

  // Prepare pie chart data for failure types
  const failureTypeData = overview ? Object.entries(overview.failure_museum.by_type).map(([name, value]) => ({
    name,
    value
  })) : []

  const COLORS = ['#8b5cf6', '#3b82f6', '#f59e0b', '#ec4899', '#10b981', '#06b6d4']

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500"></div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-white">Monitoring & Stabilization</h1>
          <p className="text-slate-400 mt-1">Real-time system health and stabilization metrics</p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => setAutoRefresh(!autoRefresh)}
            className={`px-4 py-2 rounded-lg transition-colors flex items-center gap-2 ${
              autoRefresh ? 'bg-green-600 hover:bg-green-700' : 'bg-slate-800 hover:bg-slate-700'
            } text-white`}
          >
            <RefreshCw className={`w-4 h-4 ${autoRefresh ? 'animate-spin' : ''}`} />
            Auto-Refresh {autoRefresh ? 'ON' : 'OFF'}
          </button>
          <button
            onClick={handleExportCSV}
            className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors"
          >
            <Download className="w-4 h-4" />
            Export CSV
          </button>
        </div>
      </div>

      {/* Tab Navigation */}
      <div className="flex gap-2 border-b border-slate-800">
        <button
          onClick={() => setActiveTab('overview')}
          className={`px-6 py-3 transition-colors ${
            activeTab === 'overview'
              ? 'border-b-2 border-purple-500 text-purple-400 font-semibold'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          Overview
        </button>
        <button
          onClick={() => setActiveTab('epistemic')}
          className={`px-6 py-3 transition-colors flex items-center gap-2 ${
            activeTab === 'epistemic'
              ? 'border-b-2 border-purple-500 text-purple-400 font-semibold'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          <Brain className="w-4 h-4" />
          Epistemic Health
        </button>
        <button
          onClick={() => setActiveTab('reality')}
          className={`px-6 py-3 transition-colors flex items-center gap-2 ${
            activeTab === 'reality'
              ? 'border-b-2 border-purple-500 text-purple-400 font-semibold'
              : 'text-slate-400 hover:text-white'
          }`}
        >
          <Eye className="w-4 h-4" />
          Reality Grounding
        </button>
      </div>

      {/* Overview Tab Content */}
      {activeTab === 'overview' && (
        <>
      {/* Overall Health Status */}
      <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-slate-400">Overall System Health</p>
            <p className={`text-3xl font-bold mt-2 ${
              overview?.overall_health === 'HEALTHY' ? 'text-green-400' : 'text-yellow-400'
            }`}>
              {overview?.overall_health || 'UNKNOWN'}
            </p>
          </div>
          {overview?.overall_health === 'HEALTHY' ? (
            <CheckCircle className="w-16 h-16 text-green-500" />
          ) : (
            <AlertTriangle className="w-16 h-16 text-yellow-500" />
          )}
        </div>
        {lastUpdated && (
          <p className="text-xs text-slate-500 mt-2">
            Last updated: {lastUpdated.toLocaleTimeString()}
          </p>
        )}
      </div>

      {/* System Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Bandwidth Monitor */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <Activity className="w-8 h-8 text-blue-500" />
            {overview?.bandwidth.status === 'HEALTHY' ? (
              <CheckCircle className="w-5 h-5 text-green-500" />
            ) : (
              <AlertTriangle className="w-5 h-5 text-yellow-500" />
            )}
          </div>
          <h3 className="text-sm text-slate-400 mb-2">Bandwidth Monitor</h3>
          <p className="text-2xl font-bold text-white">{overview?.bandwidth.total_events || 0}</p>
          <p className="text-xs text-slate-500 mt-1">Total Events</p>
          {overview && overview.bandwidth.active_alerts > 0 && (
            <div className="mt-3 px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded">
              {overview.bandwidth.active_alerts} Active Alerts
            </div>
          )}
        </div>

        {/* Cognitive Immune System */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <Shield className="w-8 h-8 text-purple-500" />
            {overview?.immune_system.status === 'HEALTHY' ? (
              <CheckCircle className="w-5 h-5 text-green-500" />
            ) : (
              <AlertTriangle className="w-5 h-5 text-yellow-500" />
            )}
          </div>
          <h3 className="text-sm text-slate-400 mb-2">Immune System</h3>
          <p className="text-2xl font-bold text-white">{overview?.immune_system.total_anomalies || 0}</p>
          <p className="text-xs text-slate-500 mt-1">Total Anomalies</p>
          {overview && overview.immune_system.critical_count > 0 && (
            <div className="mt-3 px-2 py-1 bg-red-500/20 text-red-400 text-xs rounded">
              {overview.immune_system.critical_count} Critical
            </div>
          )}
        </div>

        {/* Failure Museum */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <Archive className="w-8 h-8 text-orange-500" />
          </div>
          <h3 className="text-sm text-slate-400 mb-2">Failure Museum</h3>
          <p className="text-2xl font-bold text-white">{overview?.failure_museum.total_failures || 0}</p>
          <p className="text-xs text-slate-500 mt-1">Total Failures</p>
          <p className="text-xs text-slate-400 mt-1">
            {overview?.failure_museum.total_replays || 0} replays
          </p>
        </div>

        {/* Deliberate Friction */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <Zap className="w-8 h-8 text-cyan-500" />
          </div>
          <h3 className="text-sm text-slate-400 mb-2">Deliberate Friction</h3>
          <p className="text-2xl font-bold text-white capitalize">{overview?.deliberate_friction.current_mode || 'N/A'}</p>
          <p className="text-xs text-slate-500 mt-1">Current Mode</p>
          <p className="text-xs text-slate-400 mt-1">
            {overview?.deliberate_friction.total_decisions || 0} decisions
          </p>
        </div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Bandwidth History */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Bandwidth Events Over Time</h2>
          <ResponsiveContainer width="100%" height={300}>
            <AreaChart data={bandwidthHistory}>
              <defs>
                <linearGradient id="colorEvents" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.8}/>
                  <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="time" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#fff' }}
              />
              <Legend />
              <Area type="monotone" dataKey="events" stroke="#3b82f6" fillOpacity={1} fill="url(#colorEvents)" name="Events" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Anomaly Detection */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Anomaly Detection Trends</h2>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={anomalyHistory}>
              <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
              <XAxis dataKey="time" stroke="#94a3b8" />
              <YAxis stroke="#94a3b8" />
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#fff' }}
              />
              <Legend />
              <Line type="monotone" dataKey="anomalies" stroke="#8b5cf6" strokeWidth={2} name="Total Anomalies" />
              <Line type="monotone" dataKey="critical" stroke="#ef4444" strokeWidth={2} name="Critical" />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Failure Types Distribution */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Failure Types Distribution</h2>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={failureTypeData}
                cx="50%"
                cy="50%"
                labelLine={false}
                outerRadius={100}
                fill="#8884d8"
                dataKey="value"
              >
                {failureTypeData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip 
                contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                labelStyle={{ color: '#fff' }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Reasoning Mode Usage */}
        <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Reasoning Mode Usage</h2>
          {overview && (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart data={Object.entries(overview.deliberate_friction.mode_usage).map(([name, value]) => ({
                name,
                value
              }))}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="name" stroke="#94a3b8" />
                <YAxis stroke="#94a3b8" />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                  labelStyle={{ color: '#fff' }}
                />
                <Bar dataKey="value" fill="#06b6d4" name="Usage Count" />
              </BarChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>
      </>
      )}

      {/* Epistemic Health Tab Content */}
      {activeTab === 'epistemic' && epistemicHealth && (
        <div className="space-y-6">
          {/* AI Vital Signs Header */}
          <div className="bg-gradient-to-br from-purple-500/10 to-blue-500/10 border border-purple-500/20 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                  <Brain className="w-6 h-6 text-purple-400" />
                  Epistemic Health Dashboard
                </h2>
                <p className="text-slate-400 mt-1">AI vital signs monitor - detect invisible cognitive drift</p>
              </div>
              <div className="text-right">
                <p className="text-sm text-slate-400">Overall Trend</p>
                <p className={`text-xl font-bold ${
                  epistemicHealth.trend_analysis.overall_trend === 'improving' ? 'text-green-400' :
                  epistemicHealth.trend_analysis.overall_trend === 'declining' ? 'text-red-400' : 'text-yellow-400'
                }`}>
                  {epistemicHealth.trend_analysis.overall_trend.toUpperCase()}
                </p>
              </div>
            </div>
          </div>

          {/* Vital Signs Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <VitalSignCard
              title="Calibration Accuracy"
              value={`${(epistemicHealth.vital_signs.calibration_accuracy * 100).toFixed(1)}%`}
              subtitle="Confidence matches evidence"
              icon={Target}
              color="green"
              good={epistemicHealth.vital_signs.calibration_accuracy > 0.8}
            />
            <VitalSignCard
              title="Drift Risk Score"
              value={(epistemicHealth.vital_signs.drift_risk_score * 100).toFixed(1) + '%'}
              subtitle="Cognitive drift probability"
              icon={GitBranch}
              color={epistemicHealth.vital_signs.drift_risk_score < 0.3 ? 'green' : epistemicHealth.vital_signs.drift_risk_score < 0.6 ? 'yellow' : 'red'}
              good={epistemicHealth.vital_signs.drift_risk_score < 0.3}
            />
            <VitalSignCard
              title="Hallucination Probability"
              value={`${(epistemicHealth.vital_signs.hallucination_probability * 100).toFixed(1)}%`}
              subtitle="Risk of synthetic narratives"
              icon={AlertTriangle}
              color={epistemicHealth.vital_signs.hallucination_probability < 0.2 ? 'green' : epistemicHealth.vital_signs.hallucination_probability < 0.5 ? 'yellow' : 'red'}
              good={epistemicHealth.vital_signs.hallucination_probability < 0.2}
            />
            <VitalSignCard
              title="Evidence Quality"
              value={(epistemicHealth.vital_signs.evidence_quality_avg * 100).toFixed(1) + '%'}
              subtitle="Average evidence strength"
              icon={CheckCircle}
              color="blue"
              good={epistemicHealth.vital_signs.evidence_quality_avg > 0.7}
            />
            <VitalSignCard
              title="Synthesis Stability"
              value={`${(epistemicHealth.vital_signs.synthesis_stability * 100).toFixed(1)}%`}
              subtitle="Contradiction resolution quality"
              icon={Activity}
              color="cyan"
              good={epistemicHealth.vital_signs.synthesis_stability > 0.75}
            />
            <VitalSignCard
              title="Dissent Diversity"
              value={`${(epistemicHealth.vital_signs.dissent_diversity_index * 100).toFixed(1)}%`}
              subtitle="Minority voice preservation"
              icon={Shield}
              color="purple"
              good={epistemicHealth.vital_signs.dissent_diversity_index > 0.6}
            />
          </div>

          {/* Health Dimensions Radar Chart */}
          <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
            <h3 className="text-lg font-semibold text-white mb-4">Health Dimensions Profile</h3>
            <ResponsiveContainer width="100%" height={400}>
              <RadarChart data={Object.entries(epistemicHealth.health_dimensions).map(([key, dim]: [string, any]) => ({
                dimension: key.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
                score: dim.score || 0
              }))}>
                <PolarGrid stroke="#334155" />
                <PolarAngleAxis dataKey="dimension" stroke="#94a3b8" />
                <PolarRadiusAxis angle={90} domain={[0, 1]} stroke="#94a3b8" />
                <Radar name="Score" dataKey="score" stroke="#8b5cf6" fill="#8b5cf6" fillOpacity={0.6} />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #334155', borderRadius: '8px' }}
                  labelStyle={{ color: '#fff' }}
                />
              </RadarChart>
            </ResponsiveContainer>
          </div>

          {/* Alerts and Recommendations */}
          {epistemicHealth.alerts.length > 0 && (
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                <AlertTriangle className="w-5 h-5 text-yellow-400" />
                Active Alerts ({epistemicHealth.alerts.length})
              </h3>
              <div className="space-y-2">
                {epistemicHealth.alerts.map((alert, idx) => (
                  <div key={idx} className="px-4 py-3 bg-yellow-500/10 border border-yellow-500/20 rounded-lg">
                    <p className="text-yellow-200 text-sm">{alert.message || JSON.stringify(alert)}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {epistemicHealth.recommendations.length > 0 && (
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                <TrendingUp className="w-5 h-5 text-blue-400" />
                Recommendations
              </h3>
              <ul className="space-y-2">
                {epistemicHealth.recommendations.map((rec, idx) => (
                  <li key={idx} className="flex items-start gap-2 text-slate-300 text-sm">
                    <span className="text-blue-400 mt-1">•</span>
                    <span>{rec}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}

      {/* Reality Grounding Tab Content */}
      {activeTab === 'reality' && epistemicHealth && (
        <div className="space-y-6">
          {/* Reality Grounding Header */}
          <div className="bg-gradient-to-br from-cyan-500/10 to-blue-500/10 border border-cyan-500/20 rounded-xl p-6">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                  <Eye className="w-6 h-6 text-cyan-400" />
                  Reality Grounding
                </h2>
                <p className="text-slate-400 mt-1">External validation and drift detection - prevent "beautiful delusion"</p>
              </div>
              <div className="text-right">
                <p className="text-sm text-slate-400">Grounding Score</p>
                <p className={`text-3xl font-bold ${
                  epistemicHealth.reality_grounding.overall_grounding_score > 0.8 ? 'text-green-400' :
                  epistemicHealth.reality_grounding.overall_grounding_score > 0.6 ? 'text-yellow-400' : 'text-red-400'
                }`}>
                  {(epistemicHealth.reality_grounding.overall_grounding_score * 100).toFixed(1)}%
                </p>
              </div>
            </div>
          </div>

          {/* Grounding Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <CheckCircle className="w-8 h-8 text-green-500" />
              </div>
              <h3 className="text-sm text-slate-400 mb-2">External Verification</h3>
              <p className="text-2xl font-bold text-white">
                {epistemicHealth.reality_grounding.external_verification.total_anchors}
              </p>
              <p className="text-xs text-slate-500 mt-1">Active Anchors</p>
              <p className="text-xs text-green-400 mt-2">
                Avg Validation: {(epistemicHealth.reality_grounding.external_verification.average_validation * 100).toFixed(1)}%
              </p>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <Clock className="w-8 h-8 text-blue-500" />
              </div>
              <h3 className="text-sm text-slate-400 mb-2">Temporal Consistency</h3>
              <p className="text-2xl font-bold text-white">
                {epistemicHealth.reality_grounding.temporal_consistency.total_records}
              </p>
              <p className="text-xs text-slate-500 mt-1">Records Tracked</p>
              <p className="text-xs text-blue-400 mt-2">
                Consistency: {(epistemicHealth.reality_grounding.temporal_consistency.consistency_score * 100).toFixed(1)}%
              </p>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <div className="flex items-center justify-between mb-4">
                <Shield className="w-8 h-8 text-purple-500" />
              </div>
              <h3 className="text-sm text-slate-400 mb-2">Physical Constraints</h3>
              <p className="text-2xl font-bold text-white">
                {epistemicHealth.reality_grounding.physical_constraints.loaded_constraints}
              </p>
              <p className="text-xs text-slate-500 mt-1">Loaded Rules</p>
              <p className="text-xs text-purple-400 mt-2">
                Violations: {epistemicHealth.reality_grounding.physical_constraints.violations_detected}
              </p>
            </div>
          </div>

          {/* Drift Risk Level */}
          <div className={`rounded-xl p-6 border-2 ${
            epistemicHealth.reality_grounding.drift_risk_level === 'CRITICAL' ? 'bg-red-500/10 border-red-500' :
            epistemicHealth.reality_grounding.drift_risk_level === 'MODERATE' ? 'bg-yellow-500/10 border-yellow-500' :
            'bg-green-500/10 border-green-500'
          }`}>
            <div className="flex items-center gap-3">
              {epistemicHealth.reality_grounding.drift_risk_level === 'CRITICAL' ? (
                <XCircle className="w-8 h-8 text-red-500" />
              ) : epistemicHealth.reality_grounding.drift_risk_level === 'MODERATE' ? (
                <AlertTriangle className="w-8 h-8 text-yellow-500" />
              ) : (
                <CheckCircle className="w-8 h-8 text-green-500" />
              )}
              <div>
                <p className="text-sm text-slate-400">Drift Risk Level</p>
                <p className={`text-2xl font-bold ${
                  epistemicHealth.reality_grounding.drift_risk_level === 'CRITICAL' ? 'text-red-400' :
                  epistemicHealth.reality_grounding.drift_risk_level === 'MODERATE' ? 'text-yellow-400' : 'text-green-400'
                }`}>
                  {epistemicHealth.reality_grounding.drift_risk_level}
                </p>
              </div>
            </div>
          </div>

          {/* Recent Drift Reports */}
          {epistemicHealth.reality_grounding.recent_drift_reports.length > 0 && (
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
              <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                <GitBranch className="w-5 h-5 text-orange-400" />
                Recent Drift Reports ({epistemicHealth.reality_grounding.recent_drift_reports.length})
              </h3>
              <div className="space-y-3">
                {epistemicHealth.reality_grounding.recent_drift_reports.map((report) => (
                  <div key={report.report_id} className={`px-4 py-3 rounded-lg border ${
                    report.severity === 'critical' || report.severity === 'severe' ? 'bg-red-500/10 border-red-500/30' :
                    report.severity === 'moderate' ? 'bg-yellow-500/10 border-yellow-500/30' :
                    'bg-slate-800 border-slate-700'
                  }`}>
                    <div className="flex items-center justify-between mb-2">
                      <span className={`text-sm font-semibold ${
                        report.severity === 'critical' ? 'text-red-400' :
                        report.severity === 'severe' ? 'text-red-300' :
                        report.severity === 'moderate' ? 'text-yellow-400' : 'text-slate-400'
                      }`}>
                        {report.severity.toUpperCase()}
                      </span>
                      <span className="text-xs text-slate-500">
                        Drift Score: {(report.drift_score * 100).toFixed(1)}%
                      </span>
                    </div>
                    <p className="text-xs text-slate-400">
                      Affected Claims: {report.affected_claims_count}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  )
}

// Helper component for vital sign cards
function VitalSignCard({ title, value, subtitle, icon: Icon, color, good }: {
  title: string
  value: string
  subtitle: string
  icon: any
  color: string
  good: boolean
}) {
  const colorClasses = {
    green: 'text-green-500',
    red: 'text-red-500',
    yellow: 'text-yellow-500',
    blue: 'text-blue-500',
    cyan: 'text-cyan-500',
    purple: 'text-purple-500'
  }

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-xl p-6">
      <div className="flex items-center justify-between mb-4">
        <Icon className={`w-8 h-8 ${colorClasses[color as keyof typeof colorClasses]}`} />
        {good ? (
          <CheckCircle className="w-5 h-5 text-green-500" />
        ) : (
          <AlertTriangle className="w-5 h-5 text-yellow-500" />
        )}
      </div>
      <h3 className="text-sm text-slate-400 mb-2">{title}</h3>
      <p className="text-2xl font-bold text-white">{value}</p>
      <p className="text-xs text-slate-500 mt-1">{subtitle}</p>
    </div>
  )
}
