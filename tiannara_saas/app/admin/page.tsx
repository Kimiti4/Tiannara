'use client'

import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { authFetch } from '@/lib/fetch-auth'
import { 
  Activity, Users, Zap, AlertCircle, Server, Cpu, HardDrive, 
  Network, Play, RotateCcw, Terminal, CheckCircle, XCircle,
  TrendingUp, Clock, BarChart3, Shield, Eye
} from 'lucide-react'

interface MetricsData {
  totalRequests: number
  requestsChange: number
  activeUsers: number
  usersChange: number
  avgLatency: number
  latencyChange: number
  successRate: number
  errorRate: number
  uptime: string
}

interface EngineStatus {
  name: string
  status: 'running' | 'stopped' | 'error'
  uptime: string
  requests: number
  avgResponseTime: number
}

interface SystemHealth {
  cpu: number
  memory: number
  disk: number
  network: number
}

export default function AdminDashboard() {
  const router = useRouter()
  const [metrics, setMetrics] = useState<MetricsData | null>(null)
  const [engines, setEngines] = useState<EngineStatus[]>([])
  const [systemHealth, setSystemHealth] = useState<SystemHealth | null>(null)
  const [recentLogs, setRecentLogs] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selectedTab, setSelectedTab] = useState<'overview' | 'engines' | 'logs'>('overview')
  const [isAuthenticated, setIsAuthenticated] = useState(false)

  // Check authentication on mount
  useEffect(() => {
    authFetch('/auth/me')
      .then((res) => {
        if (res.ok) setIsAuthenticated(true)
        else router.push('/login')
      })
      .catch(() => router.push('/login'))
  }, [router])

  // Fetch metrics on mount and every 10 seconds
  useEffect(() => {
    if (isAuthenticated) {
      fetchMetrics()
      const interval = setInterval(fetchMetrics, 10000)
      return () => clearInterval(interval)
    }
  }, [isAuthenticated])

  const fetchMetrics = async () => {
    try {
      const response = await authFetch('/admin/metrics')

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      
      setMetrics(data.metrics)
      setEngines(data.engines || [])
      setSystemHealth(data.system_health)
      setRecentLogs(data.recent_logs || [])
      setError(null)
    } catch (err) {
      console.error('Failed to fetch admin metrics:', err)
      setError('Failed to load metrics. Using mock data.')
      // Use mock data as fallback
      setMockData()
    } finally {
      setLoading(false)
    }
  }

  const setMockData = () => {
    setMetrics({
      totalRequests: 45678,
      requestsChange: 12.5,
      activeUsers: 234,
      usersChange: 8.3,
      avgLatency: 142,
      latencyChange: -5.2,
      successRate: 99.7,
      errorRate: 0.3,
      uptime: '99.9%'
    })
    
    setEngines([
      { name: 'predict', status: 'running', uptime: '7d 14h', requests: 12543, avgResponseTime: 89 },
      { name: 'analyze', status: 'running', uptime: '7d 14h', requests: 8921, avgResponseTime: 156 },
      { name: 'reason', status: 'running', uptime: '5d 8h', requests: 6234, avgResponseTime: 234 },
      { name: 'nlp', status: 'running', uptime: '7d 14h', requests: 15678, avgResponseTime: 67 }
    ])
    
    setSystemHealth({
      cpu: 45.2,
      memory: 62.8,
      disk: 58.3,
      network: 55.1
    })
  }

  const handleRestartEngine = async (engineName: string) => {
    try {
      const response = await authFetch(`/admin/engines/${engineName}/restart`, {
        method: 'POST',
      })

      if (!response.ok) {
        throw new Error('Failed to restart engine')
      }

      alert(`Engine '${engineName}' restart initiated`)
      fetchMetrics() // Refresh data
    } catch (err) {
      console.error('Failed to restart engine:', err)
      alert('Failed to restart engine')
    }
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-500 mx-auto mb-4"></div>
          <p className="text-slate-400">Loading admin dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-950 via-slate-900 to-slate-950 p-8">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-4xl font-bold text-white mb-2">Admin Dashboard</h1>
            <p className="text-slate-400">Internal Operations Monitoring & Management</p>
          </div>
          <div className="flex items-center gap-3">
            <span className="px-3 py-1 bg-green-500/20 text-green-400 rounded-full text-sm flex items-center gap-2">
              <Shield className="w-4 h-4" />
              Admin Access
            </span>
            <button
              onClick={fetchMetrics}
              className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors flex items-center gap-2"
            >
              <RotateCcw className="w-4 h-4" />
              Refresh
            </button>
          </div>
        </div>

        {error && (
          <div className="bg-red-500/10 border border-red-500/30 rounded-lg p-4 mb-4 flex items-center gap-3">
            <AlertCircle className="w-5 h-5 text-red-400" />
            <span className="text-red-400">{error}</span>
          </div>
        )}

        {/* Tab Navigation */}
        <div className="flex gap-2 border-b border-slate-800">
          {[
            { id: 'overview', label: 'Overview', icon: BarChart3 },
            { id: 'engines', label: 'Domain Engines', icon: Cpu },
            { id: 'logs', label: 'Live Logs', icon: Terminal }
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setSelectedTab(tab.id as any)}
              className={`px-6 py-3 flex items-center gap-2 font-medium transition-colors ${
                selectedTab === tab.id
                  ? 'text-purple-400 border-b-2 border-purple-400'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              <tab.icon className="w-4 h-4" />
              {tab.label}
            </button>
          ))}
          <button
            onClick={() => router.push('/admin/users')}
            className="px-6 py-3 flex items-center gap-2 font-medium text-slate-400 hover:text-white transition-colors ml-auto"
          >
            <Users className="w-4 h-4" />
            User Management
          </button>
        </div>
      </div>

      {/* Overview Tab */}
      {selectedTab === 'overview' && (
        <>
          {/* Key Metrics Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <MetricCard
              title="Total Requests"
              value={metrics?.totalRequests.toLocaleString() || '0'}
              change={metrics?.requestsChange}
              icon={Activity}
              color="purple"
            />
            <MetricCard
              title="Active Users"
              value={metrics?.activeUsers.toString() || '0'}
              change={metrics?.usersChange}
              icon={Users}
              color="cyan"
            />
            <MetricCard
              title="Avg Latency"
              value={`${metrics?.avgLatency || 0}ms`}
              change={metrics?.latencyChange}
              inverse={true}
              icon={Clock}
              color="green"
            />
            <MetricCard
              title="Success Rate"
              value={`${metrics?.successRate || 0}%`}
              icon={CheckCircle}
              color="blue"
            />
          </div>

          {/* System Health */}
          {systemHealth && (
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-8">
              <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
                <Server className="w-5 h-5 text-purple-400" />
                System Health
              </h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                <HealthBar label="CPU Usage" value={systemHealth.cpu} color="purple" />
                <HealthBar label="Memory" value={systemHealth.memory} color="cyan" />
                <HealthBar label="Disk" value={systemHealth.disk} color="green" />
                <HealthBar label="Network" value={systemHealth.network} color="orange" />
              </div>
            </div>
          )}

          {/* Domain Engines Status */}
          <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-8">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold text-white flex items-center gap-2">
                <Zap className="w-5 h-5 text-cyan-400" />
                Domain Engines
              </h3>
              <span className="text-sm text-slate-400">
                {engines.filter(e => e.status === 'running').length}/{engines.length} Running
              </span>
            </div>
            <div className="space-y-3">
              {engines.map((engine) => {
                const engineDescriptions: Record<string, { desc: string; metrics: string[] }> = {
                  'predict': {
                    desc: 'Machine learning predictions and forecasting. Analyzes patterns to predict future outcomes with confidence scores.',
                    metrics: ['ML model inference', 'Time-series forecasting', 'Classification tasks']
                  },
                  'analyze': {
                    desc: 'Data analysis and pattern recognition. Processes large datasets to extract insights and identify trends.',
                    metrics: ['Statistical analysis', 'Trend detection', 'Anomaly identification']
                  },
                  'reason': {
                    desc: 'Logical reasoning and decision-making. Evaluates complex scenarios using multi-step inference chains.',
                    metrics: ['Causal reasoning', 'Decision trees', 'Inference chains']
                  },
                  'nlp': {
                    desc: 'Natural language processing. Understands, generates, and transforms human language for intelligent text operations.',
                    metrics: ['Text classification', 'Sentiment analysis', 'Language generation']
                  }
                }

                const engineInfo = engineDescriptions[engine.name] || {
                  desc: 'Domain-specific AI engine',
                  metrics: ['Custom operations']
                }

                return (
                  <div
                    key={engine.name}
                    className="flex items-center justify-between p-4 bg-slate-800/50 rounded-lg group relative hover:bg-slate-800/70 transition-colors"
                  >
                    <div className="flex items-center gap-4">
                      <div className={`w-3 h-3 rounded-full ${
                        engine.status === 'running' ? 'bg-green-400' : 
                        engine.status === 'error' ? 'bg-red-400' : 'bg-yellow-400'
                      }`}></div>
                      <div>
                        <p className="text-white font-medium capitalize">{engine.name}</p>
                        <p className="text-sm text-slate-400">Uptime: {engine.uptime}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-6">
                      <div className="text-right">
                        <p className="text-sm text-slate-400">Requests</p>
                        <p className="text-white font-medium">{engine.requests.toLocaleString()}</p>
                      </div>
                      <div className="text-right">
                        <p className="text-sm text-slate-400">Response Time</p>
                        <p className="text-white font-medium">{engine.avgResponseTime}ms</p>
                      </div>
                      <button
                        onClick={() => handleRestartEngine(engine.name)}
                        className="px-3 py-1 bg-slate-700 hover:bg-slate-600 text-white rounded-lg text-sm transition-colors flex items-center gap-2"
                      >
                        <RotateCcw className="w-4 h-4" />
                        Restart
                      </button>
                    </div>
                    {/* Hover Tooltip */}
                    <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-4 py-3 bg-slate-800 border border-slate-700 rounded-lg shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-50 w-80">
                      <div className="text-xs">
                        <p className="font-semibold text-white mb-2 capitalize">{engine.name} Engine</p>
                        <p className="text-slate-300 mb-2 leading-tight">{engineInfo.desc}</p>
                        <div className="space-y-1">
                          <p className="text-slate-400 text-xs font-semibold">Key Capabilities:</p>
                          {engineInfo.metrics.map((metric, idx) => (
                            <div key={idx} className="flex items-center gap-2 text-slate-400">
                              <span className="w-1.5 h-1.5 bg-purple-400 rounded-full"></span>
                              {metric}
                            </div>
                          ))}
                        </div>
                        <div className="mt-2 pt-2 border-t border-slate-700 flex justify-between text-slate-500">
                          <span>Latency: {engine.avgResponseTime}ms</span>
                          <span>Throughput: {engine.requests.toLocaleString()} req</span>
                        </div>
                      </div>
                      <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1">
                        <div className="w-2 h-2 bg-slate-800 border-r border-b border-slate-700 rotate-45"></div>
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          </div>
        </>
      )}

      {/* Engines Tab */}
      {selectedTab === 'engines' && (
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h3 className="text-lg font-semibold text-white mb-6 flex items-center gap-2">
            <Cpu className="w-5 h-5 text-purple-400" />
            Domain Engine Details
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {engines.map((engine) => (
              <div
                key={engine.name}
                className="bg-slate-800/50 border border-slate-700 rounded-xl p-6"
              >
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h4 className="text-xl font-bold text-white capitalize">{engine.name}</h4>
                    <p className="text-sm text-slate-400 mt-1">Engine Status</p>
                  </div>
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    engine.status === 'running' ? 'bg-green-500/20 text-green-400' :
                    engine.status === 'error' ? 'bg-red-500/20 text-red-400' :
                    'bg-yellow-500/20 text-yellow-400'
                  }`}>
                    {engine.status.toUpperCase()}
                  </span>
                </div>
                
                <div className="space-y-3 mb-6">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Uptime</span>
                    <span className="text-white font-medium">{engine.uptime}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Total Requests</span>
                    <span className="text-white font-medium">{engine.requests.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Avg Response Time</span>
                    <span className="text-white font-medium">{engine.avgResponseTime}ms</span>
                  </div>
                </div>

                <button
                  onClick={() => handleRestartEngine(engine.name)}
                  className="w-full px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition-colors flex items-center justify-center gap-2"
                >
                  <RotateCcw className="w-4 h-4" />
                  Restart Engine
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Logs Tab */}
      {selectedTab === 'logs' && (
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center justify-between mb-6">
            <h3 className="text-lg font-semibold text-white flex items-center gap-2">
              <Terminal className="w-5 h-5 text-green-400" />
              Live Logs
            </h3>
            <span className="text-sm text-slate-400">Last {recentLogs.length} entries</span>
          </div>
          
          <div className="bg-black rounded-lg p-4 font-mono text-sm max-h-96 overflow-y-auto">
            {recentLogs.length > 0 ? (
              recentLogs.map((log, index) => (
                <div key={index} className="mb-2">
                  <span className="text-slate-500">[{log.timestamp}]</span>{' '}
                  <span className={`font-bold ${
                    log.level === 'ERROR' ? 'text-red-400' :
                    log.level === 'WARN' ? 'text-yellow-400' :
                    'text-green-400'
                  }`}>{log.level}</span>{' '}
                  <span className="text-slate-300">{log.message}</span>
                </div>
              ))
            ) : (
              <p className="text-slate-500 text-center py-8">No logs available</p>
            )}
          </div>
        </div>
      )}
    </div>
  )
}

// Component helpers
function MetricCard({ title, value, change, inverse, icon: Icon, color }: any) {
  const colors = {
    purple: 'from-purple-500/10 to-purple-600/10 border-purple-500/20',
    cyan: 'from-cyan-500/10 to-cyan-600/10 border-cyan-500/20',
    green: 'from-green-500/10 to-green-600/10 border-green-500/20',
    blue: 'from-blue-500/10 to-blue-600/10 border-blue-500/20',
  }

  const getTooltipText = (title: string) => {
    const tooltips: Record<string, string> = {
      'Total Requests': 'Total API requests processed across all services. Includes discovery, evolution, and autonomous operations.',
      'Active Users': 'Number of unique users who have made API calls in the last 24 hours.',
      'Avg Latency': 'Average response time for all API requests. Lower is better. Target: <200ms',
      'Success Rate': 'Percentage of successful API responses (2xx status codes). Target: >99%'
    }
    return tooltips[title] || 'System metric'
  }

  const isPositive = change > 0
  const showPositive = inverse ? !isPositive : isPositive

  return (
    <div className={`bg-gradient-to-br ${colors[color as keyof typeof colors]} border rounded-xl p-6 group relative`}>
      <div className="flex items-start justify-between mb-4">
        <Icon className="w-6 h-6 text-white opacity-80" />
        {change !== undefined && (
          <span className={`text-xs font-medium ${showPositive ? 'text-green-400' : 'text-red-400'}`}>
            {change > 0 ? '+' : ''}{change}%
          </span>
        )}
      </div>
      <h3 className="text-3xl font-bold text-white mb-1">{value}</h3>
      <p className="text-sm text-slate-400">{title}</p>
      
      {/* Hover Tooltip */}
      <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-50 w-72">
        <p className="text-xs text-slate-300 leading-tight">{getTooltipText(title)}</p>
        <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1">
          <div className="w-2 h-2 bg-slate-800 border-r border-b border-slate-700 rotate-45"></div>
        </div>
      </div>
    </div>
  )
}

function HealthBar({ label, value, color }: any) {
  const colors = {
    purple: 'bg-purple-500',
    cyan: 'bg-cyan-500',
    green: 'bg-green-500',
    orange: 'bg-orange-500',
  }

  const getColor = (val: number) => {
    if (val < 60) return 'bg-green-500'
    if (val < 80) return 'bg-yellow-500'
    return 'bg-red-500'
  }

  const getTooltipText = (label: string) => {
    const tooltips: Record<string, string> = {
      'CPU Usage': 'Total CPU utilization across all cores. High usage may indicate heavy processing or memory leaks. Optimal: <70%',
      'Memory': 'RAM usage including active processes and cache. High memory usage can cause slowdowns. Optimal: <80%',
      'Disk': 'Storage space usage for databases, logs, and files. High disk usage can prevent data writes. Optimal: <85%',
      'Network': 'Network bandwidth utilization for API calls and data transfer. High usage may indicate traffic spikes. Optimal: <75%'
    }
    return tooltips[label] || 'System resource utilization'
  }

  const getStatusText = (val: number) => {
    if (val < 60) return 'Healthy'
    if (val < 80) return 'Warning'
    return 'Critical'
  }

  return (
    <div className="group relative">
      <div className="flex justify-between mb-2">
        <span className="text-sm text-slate-400">{label}</span>
        <span className="text-sm text-white font-medium">{value}%</span>
      </div>
      <div className="w-full bg-slate-800 rounded-full h-2">
        <div
          className={`${getColor(value)} h-2 rounded-full transition-all duration-500`}
          style={{ width: `${value}%` }}
        ></div>
      </div>
      {/* Hover Tooltip */}
      <div className="absolute bottom-full left-1/2 -translate-x-1/2 mb-2 px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-200 pointer-events-none z-50 w-64">
        <div className="text-xs">
          <p className="font-semibold text-white mb-1">{label}: {getStatusText(value)}</p>
          <p className="text-slate-400 leading-tight">{getTooltipText(label)}</p>
          <div className="absolute top-full left-1/2 -translate-x-1/2 -mt-1">
            <div className="w-2 h-2 bg-slate-800 border-r border-b border-slate-700 rotate-45"></div>
          </div>
        </div>
      </div>
    </div>
  )
}
