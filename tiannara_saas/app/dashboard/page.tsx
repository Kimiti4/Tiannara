'use client'

import { useState, useEffect } from 'react'
import { Plus, Zap, AlertTriangle, TrendingUp, Search, BarChart3, Brain, Activity, Shield, FileText, Loader2 } from 'lucide-react'
import { apiClient } from '@/lib/api'
import { getMetricsClient, RealtimeMetrics } from '@/lib/websocket-client'

export default function Dashboard() {
  const [onboardingData, setOnboardingData] = useState<any>(null)
  const [metrics, setMetrics] = useState<RealtimeMetrics | null>(null)
  const [workflows, setWorkflows] = useState<any[]>([])
  const [insights, setInsights] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [wsConnected, setWsConnected] = useState(false)

  useEffect(() => {
    const data = localStorage.getItem('tiannara_onboarding')
    if (data) {
      setOnboardingData(JSON.parse(data))
    }
    fetchDashboardData()
    connectWebSocket()
    
    return () => {
      // Cleanup WebSocket on unmount
      const client = getMetricsClient()
      client.disconnect()
    }
  }, [])

  const connectWebSocket = async () => {
    try {
      const client = getMetricsClient()
      await client.connect()
      setWsConnected(true)
      
      // Subscribe to real-time updates
      client.subscribe((data: RealtimeMetrics) => {
        setMetrics(data)
        
        // Update workflows from real-time data
        if (data.active_workflows && data.active_workflows.length > 0) {
          setWorkflows(data.active_workflows.map(wf => ({
            id: wf.id,
            name: wf.name,
            status: wf.status,
            last_run: wf.last_run,
            accuracy: wf.accuracy,
            nodes: wf.nodes || []
          })))
        }
        
        // Update insights from real-time data
        if (data.system_insights && data.system_insights.length > 0) {
          setInsights(data.system_insights.map(insight => ({
            id: insight.timestamp,
            type: insight.type,
            description: insight.message,
            confidence: insight.confidence
          })))
        }
      })
      
      console.log('✅ WebSocket connected for real-time metrics')
    } catch (err) {
      console.error('Failed to connect WebSocket:', err)
      // Fallback to polling
      startPolling()
    }
  }

  const startPolling = () => {
    // Fallback: poll every 10 seconds if WebSocket fails
    const interval = setInterval(fetchDashboardData, 10000)
    return () => clearInterval(interval)
  }

  const fetchDashboardData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      // Fetch metrics, workflows, and insights in parallel
      const [metricsRes, workflowsRes, insightsRes] = await Promise.all([
        apiClient.getDashboardMetrics(),
        apiClient.getWorkflows(),
        apiClient.getInsights()
      ])
      
      if (metricsRes.success && metricsRes.data) {
        setMetrics(metricsRes.data)
      }
      
      if (workflowsRes.success && workflowsRes.data) {
        // Get only active workflows
        const activeWorkflows = workflowsRes.data.filter((w: any) => w.status === 'active')
        setWorkflows(activeWorkflows.slice(0, 5)) // Show top 5
      }
      
      if (insightsRes.success && insightsRes.data) {
        setInsights(insightsRes.data.slice(0, 3)) // Show top 3 insights
      }
    } catch (err) {
      console.error('Failed to fetch dashboard data:', err)
      setError('Failed to load dashboard data. Please refresh.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Connection Status */}
      <div className="mb-4 flex items-center justify-end">
        <div className={`flex items-center gap-2 px-3 py-1 rounded-full text-xs ${
          wsConnected 
            ? 'bg-green-500/10 text-green-400 border border-green-500/20' 
            : 'bg-yellow-500/10 text-yellow-400 border border-yellow-500/20'
        }`}>
          <div className={`w-2 h-2 rounded-full ${wsConnected ? 'bg-green-400' : 'bg-yellow-400'}`}></div>
          {wsConnected ? 'Real-time Connected' : 'Polling Mode'}
        </div>
      </div>

      {/* Welcome Section */}
      <div className="mb-8 bg-gradient-to-br from-purple-500/10 to-blue-500/10 border border-purple-500/20 rounded-xl p-6">
        <h1 className="text-2xl font-bold text-white mb-2">Welcome back{onboardingData ? ', User' : ''} 👋</h1>
        <p className="text-slate-400">Your AI systems are running normally.</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchDashboardData}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : (
        <>
      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <StatCard
          title="API Usage"
          value={metrics?.api_usage ? `${metrics.api_usage.current?.toLocaleString() ?? 0}/${metrics.api_usage.limit?.toLocaleString() ?? 0}` : 'N/A'}
          subtitle={`${metrics?.api_usage?.percentage?.toFixed(1) ?? 0}% of limit`}
          icon={Zap}
          color="purple"
        />
        <StatCard
          title="Workflows"
          value={`${workflows.length} Active`}
          subtitle="running now"
          icon={Activity}
          color="cyan"
        />
        <StatCard
          title="Accuracy"
          value={metrics ? `${metrics.prediction_accuracy.toFixed(1)}%` : 'N/A'}
          subtitle="avg across workflows"
          icon={TrendingUp}
          color="green"
        />
      </div>

      {/* Active Workflows */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold text-white mb-4">Active Workflows</h2>
        <div className="space-y-4">
          {workflows.length > 0 ? (
            workflows.map((workflow) => (
              <WorkflowCard
                key={workflow.id}
                name={workflow.name}
                steps={`${workflow.nodes?.length || 0} nodes configured`}
                status={workflow.status === 'running' ? 'Running' : workflow.status}
                lastRun={workflow.last_run ? new Date(workflow.last_run).toLocaleString() : 'Never'}
                accuracy={workflow.accuracy ? `${workflow.accuracy.toFixed(1)}%` : 'N/A'}
                statusColor={workflow.status === 'running' ? 'green' : 'blue'}
              />
            ))
          ) : (
            <p className="text-slate-400 text-center py-8">No active workflows. Create one to get started!</p>
          )}
        </div>
      </div>

      {/* Quick Actions */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold text-white mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <QuickActionCard
            title="New Workflow"
            icon={Plus}
            href="/dashboard/workflows/new"
          />
          <QuickActionCard
            title="Generate API Key"
            icon={Zap}
            href="/dashboard/keys"
          />
          <QuickActionCard
            title="Create Alert"
            icon={AlertTriangle}
            href="/dashboard/automations"
          />
        </div>
      </div>

      {/* System Insights */}
      <div className="mb-8">
        <h2 className="text-lg font-semibold text-white mb-4">System Insights</h2>
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 space-y-4">
          {insights.length > 0 ? (
            insights.map((insight) => (
              <InsightCard
                key={insight.id}
                type={insight.type === 'root_cause' ? 'Root Cause Analysis' : insight.type === 'forecast' ? 'Forecast' : 'Anomaly Detection'}
                icon={insight.type === 'root_cause' ? Search : insight.type === 'forecast' ? BarChart3 : AlertTriangle}
                message={insight.description}
              />
            ))
          ) : (
            <p className="text-slate-400 text-center py-4">No insights available yet.</p>
          )}
        </div>
      </div>
        </>
      )}
    </div>
  )
}

function StatCard({ title, value, subtitle, icon: Icon, color }: any) {
  const colors = {
    purple: 'from-purple-500/10 to-purple-600/10 border-purple-500/20',
    cyan: 'from-cyan-500/10 to-cyan-600/10 border-cyan-500/20',
    green: 'from-green-500/10 to-green-600/10 border-green-500/20',
  }

  return (
    <div className={`bg-gradient-to-br ${colors[color as keyof typeof colors]} border rounded-xl p-6`}>
      <div className="flex items-start justify-between mb-4">
        <Icon className="w-6 h-6 text-white opacity-80" />
      </div>
      <h3 className="text-3xl font-bold text-white mb-1">{value}</h3>
      <p className="text-sm text-slate-400">{title}</p>
      <p className="text-xs text-slate-500 mt-1">{subtitle}</p>
    </div>
  )
}

function WorkflowCard({ name, steps, status, lastRun, accuracy, statusColor }: any) {
  const statusColors = {
    green: 'bg-green-500',
    blue: 'bg-blue-500',
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/40 transition-colors">
      <div className="flex items-start justify-between mb-3">
        <div>
          <h3 className="text-base font-semibold text-white mb-1">{name}</h3>
          <p className="text-sm text-slate-400">{steps}</p>
        </div>
        <div className="flex items-center gap-2">
          <span className={`w-2 h-2 rounded-full ${statusColors[statusColor as keyof typeof statusColors]}`}></span>
          <span className="text-sm text-slate-400">{status}</span>
        </div>
      </div>
      <div className="flex items-center justify-between text-sm">
        <span className="text-slate-500">Last run: {lastRun}</span>
        <span className="text-green-400 font-medium">Accuracy: {accuracy}</span>
      </div>
    </div>
  )
}

function QuickActionCard({ title, icon: Icon, href }: any) {
  return (
    <a
      href={href}
      className="block bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/40 transition-colors group"
    >
      <div className="w-10 h-10 bg-purple-500/10 rounded-lg flex items-center justify-center mb-3 group-hover:bg-purple-500/20 transition-colors">
        <Icon className="w-5 h-5 text-purple-400" />
      </div>
      <h3 className="text-sm font-semibold text-white">{title}</h3>
    </a>
  )
}

function InsightCard({ type, icon: Icon, message }: any) {
  return (
    <div className="flex items-start gap-3">
      <div className="w-8 h-8 bg-purple-500/10 rounded-lg flex items-center justify-center flex-shrink-0">
        <Icon className="w-4 h-4 text-purple-400" />
      </div>
      <div>
        <h4 className="text-sm font-semibold text-white mb-1">{type}</h4>
        <p className="text-sm text-slate-400">{message}</p>
      </div>
    </div>
  )
}
