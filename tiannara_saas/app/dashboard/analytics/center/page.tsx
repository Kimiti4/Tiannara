'use client'

import { useState, useEffect } from 'react'
import { 
  BarChart3, TrendingUp, Activity, Zap, AlertTriangle, 
  CheckCircle, Clock, Search, Filter, Download, RefreshCw
} from 'lucide-react'
import { apiClient } from '@/lib/api'

interface AnalyticsData {
  total_requests: number
  success_rate: number
  avg_latency_ms: number
  error_count: number
  daily_usage: Array<{
    date: string
    requests: number
    success: number
    errors: number
  }>
  domain_breakdown: Array<{
    domain: string
    count: number
    percentage: number
  }>
  workflow_performance: Array<{
    workflow_id: string
    name: string
    executions: number
    avg_accuracy: number
    avg_duration_ms: number
    success_rate: number
  }>
  ai_outputs: Array<{
    id: string
    type: string
    timestamp: string
    confidence: number
    result: any
  }>
}

export default function AnalyticsCenter() {
  const [data, setData] = useState<AnalyticsData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [timeRange, setTimeRange] = useState<'7d' | '30d' | '90d'>('7d')
  const [selectedDomain, setSelectedDomain] = useState<string>('all')

  useEffect(() => {
    fetchAnalytics()
  }, [timeRange])

  const fetchAnalytics = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const response = await apiClient.getAnalytics(timeRange)
      
      if (response.success && response.data) {
        setData(response.data)
      } else {
        setError('Failed to load analytics data')
      }
    } catch (err) {
      console.error('Failed to fetch analytics:', err)
      setError('Failed to load analytics. Please refresh.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-2xl font-bold text-white mb-2">Analytics Center</h1>
            <p className="text-slate-400">Inspect AI outputs, trends, and workflow performance</p>
          </div>
          
          <div className="flex items-center gap-3">
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value as any)}
              className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-2 text-sm text-white focus:outline-none focus:border-purple-500"
            >
              <option value="7d">Last 7 days</option>
              <option value="30d">Last 30 days</option>
              <option value="90d">Last 90 days</option>
            </select>
            
            <button
              onClick={fetchAnalytics}
              disabled={loading}
              className="px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </button>
            
            <button className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors flex items-center gap-2">
              <Download className="w-4 h-4" />
              Export
            </button>
          </div>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <div className="text-center">
            <RefreshCw className="w-8 h-8 text-purple-500 animate-spin mx-auto mb-4" />
            <p className="text-slate-400">Loading analytics...</p>
          </div>
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <AlertTriangle className="w-8 h-8 text-red-400 mx-auto mb-3" />
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchAnalytics}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : data ? (
        <>
          {/* Key Metrics */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
            <MetricCard
              title="Total Requests"
              value={data.total_requests.toLocaleString()}
              icon={Zap}
              color="purple"
              trend="+12%"
            />
            <MetricCard
              title="Success Rate"
              value={`${data.success_rate.toFixed(1)}%`}
              icon={CheckCircle}
              color="green"
              trend="+2.3%"
            />
            <MetricCard
              title="Avg Latency"
              value={`${data.avg_latency_ms.toFixed(0)}ms`}
              icon={Clock}
              color="cyan"
              trend="-15ms"
            />
            <MetricCard
              title="Errors"
              value={data.error_count.toString()}
              icon={AlertTriangle}
              color="red"
              trend="-8%"
            />
          </div>

          {/* Usage Chart */}
          <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-8">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-white">Daily Usage Trends</h2>
              <div className="flex items-center gap-4 text-sm">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-purple-500"></div>
                  <span className="text-slate-400">Requests</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-green-500"></div>
                  <span className="text-slate-400">Success</span>
                </div>
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full bg-red-500"></div>
                  <span className="text-slate-400">Errors</span>
                </div>
              </div>
            </div>
            
            <div className="h-64 flex items-end justify-between gap-2">
              {data.daily_usage.map((day, index) => {
                const maxRequests = Math.max(...data.daily_usage.map(d => d.requests))
                const height = (day.requests / maxRequests) * 100
                
                return (
                  <div key={day.date} className="flex-1 flex flex-col items-center gap-2">
                    <div 
                      className="w-full bg-gradient-to-t from-purple-500 to-purple-400 rounded-t transition-all hover:opacity-80"
                      style={{ height: `${height}%` }}
                      title={`${day.requests} requests on ${new Date(day.date).toLocaleDateString()}`}
                    />
                    <span className="text-xs text-slate-500">
                      {new Date(day.date).toLocaleDateString('en-US', { weekday: 'short' })}
                    </span>
                  </div>
                )
              })}
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            {/* Domain Breakdown */}
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
              <h2 className="text-lg font-semibold text-white mb-4">Domain Usage</h2>
              
              <div className="space-y-4">
                {data.domain_breakdown.map((domain) => (
                  <div key={domain.domain} className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center">
                        <Activity className="w-5 h-5 text-purple-400" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-white capitalize">{domain.domain.replace('_', ' ')}</p>
                        <p className="text-xs text-slate-500">{domain.count.toLocaleString()} requests</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <p className="text-sm font-semibold text-white">{domain.percentage.toFixed(1)}%</p>
                      <div className="w-24 h-2 bg-slate-800 rounded-full mt-1">
                        <div 
                          className="h-full bg-purple-500 rounded-full"
                          style={{ width: `${domain.percentage}%` }}
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Workflow Performance */}
            <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
              <h2 className="text-lg font-semibold text-white mb-4">Workflow Performance</h2>
              
              <div className="space-y-4">
                {data.workflow_performance.slice(0, 5).map((workflow) => (
                  <div key={workflow.workflow_id} className="p-4 bg-slate-800/50 rounded-lg">
                    <div className="flex items-center justify-between mb-3">
                      <h3 className="text-sm font-semibold text-white">{workflow.name}</h3>
                      <span className="text-xs px-2 py-1 bg-green-500/10 text-green-400 rounded">
                        {workflow.success_rate.toFixed(1)}% success
                      </span>
                    </div>
                    
                    <div className="grid grid-cols-3 gap-4 text-xs">
                      <div>
                        <p className="text-slate-500 mb-1">Executions</p>
                        <p className="text-white font-medium">{workflow.executions}</p>
                      </div>
                      <div>
                        <p className="text-slate-500 mb-1">Accuracy</p>
                        <p className="text-white font-medium">{workflow.avg_accuracy.toFixed(1)}%</p>
                      </div>
                      <div>
                        <p className="text-slate-500 mb-1">Duration</p>
                        <p className="text-white font-medium">{(workflow.avg_duration_ms / 1000).toFixed(1)}s</p>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Recent AI Outputs */}
          <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-lg font-semibold text-white">Recent AI Outputs</h2>
              
              <div className="flex items-center gap-3">
                <select
                  value={selectedDomain}
                  onChange={(e) => setSelectedDomain(e.target.value)}
                  className="bg-slate-800 border border-slate-700 rounded-lg px-3 py-1.5 text-sm text-white focus:outline-none focus:border-purple-500"
                >
                  <option value="all">All Domains</option>
                  <option value="nlp">NLP Analysis</option>
                  <option value="prediction">Prediction</option>
                  <option value="causal">Root Cause</option>
                </select>
                
                <button className="p-2 hover:bg-slate-800 rounded-lg transition-colors">
                  <Filter className="w-4 h-4 text-slate-400" />
                </button>
              </div>
            </div>
            
            <div className="space-y-4">
              {data.ai_outputs.slice(0, 10).map((output) => (
                <div key={output.id} className="p-4 bg-slate-800/30 border border-slate-700 rounded-lg hover:border-purple-500/40 transition-colors">
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-purple-500/10 rounded-lg flex items-center justify-center">
                        <Search className="w-4 h-4 text-purple-400" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-white capitalize">{output.type.replace('_', ' ')}</p>
                        <p className="text-xs text-slate-500">
                          {new Date(output.timestamp).toLocaleString()}
                        </p>
                      </div>
                    </div>
                    
                    <div className="flex items-center gap-2">
                      <div className={`w-2 h-2 rounded-full ${
                        output.confidence >= 0.8 ? 'bg-green-500' :
                        output.confidence >= 0.6 ? 'bg-yellow-500' : 'bg-red-500'
                      }`}></div>
                      <span className="text-xs text-slate-400">
                        {(output.confidence * 100).toFixed(0)}% confidence
                      </span>
                    </div>
                  </div>
                  
                  <div className="bg-slate-900/50 rounded-lg p-3">
                    <pre className="text-xs text-slate-300 overflow-x-auto">
                      {JSON.stringify(output.result, null, 2).slice(0, 200)}...
                    </pre>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </>
      ) : null}
    </div>
  )
}

function MetricCard({ title, value, icon: Icon, color, trend }: any) {
  const colors = {
    purple: 'from-purple-500/10 to-purple-600/10 border-purple-500/20',
    green: 'from-green-500/10 to-green-600/10 border-green-500/20',
    cyan: 'from-cyan-500/10 to-cyan-600/10 border-cyan-500/20',
    red: 'from-red-500/10 to-red-600/10 border-red-500/20',
  }

  const trendColor = trend.startsWith('+') ? 'text-green-400' : 'text-red-400'

  return (
    <div className={`bg-gradient-to-br ${colors[color as keyof typeof colors]} border rounded-xl p-6`}>
      <div className="flex items-start justify-between mb-4">
        <Icon className="w-6 h-6 text-white opacity-80" />
        <span className={`text-xs font-medium ${trendColor}`}>{trend}</span>
      </div>
      <h3 className="text-2xl font-bold text-white mb-1">{value}</h3>
      <p className="text-sm text-slate-400">{title}</p>
    </div>
  )
}
