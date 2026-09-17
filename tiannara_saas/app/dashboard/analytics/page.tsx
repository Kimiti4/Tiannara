'use client'

import { useState, useEffect } from 'react'
import { BarChart3, TrendingUp, Activity, PieChart, Loader2 } from 'lucide-react'
import { apiClient } from '@/lib/api'

export default function AnalyticsPage() {
  const [insights, setInsights] = useState<any[]>([])
  const [metrics, setMetrics] = useState<any>(null)
  const [workflows, setWorkflows] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchAnalyticsData()
  }, [])

  const fetchAnalyticsData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const [insightsRes, metricsRes, workflowsRes] = await Promise.all([
        apiClient.getInsights(),
        apiClient.getDashboardMetrics(),
        apiClient.getWorkflows()
      ])
      
      if (insightsRes.success && insightsRes.data) {
        setInsights(insightsRes.data)
      }
      
      if (metricsRes.success && metricsRes.data) {
        setMetrics(metricsRes.data)
      }
      
      if (workflowsRes.success && workflowsRes.data) {
        setWorkflows(workflowsRes.data)
      }
    } catch (err) {
      console.error('Failed to fetch analytics:', err)
      setError('Failed to load analytics data')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white mb-2">Analytics</h1>
        <p className="text-slate-400">Inspect AI outputs, trends, and workflow performance</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchAnalyticsData}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : (
        <>
      {/* Overview Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        <StatCard
          title="Total Workflows"
          value={workflows.length.toString()}
          change={`${workflows.filter(w => w.status === 'active').length} active`}
          icon={BarChart3}
        />
        <StatCard
          title="Avg Accuracy"
          value={metrics ? `${metrics.avg_accuracy}%` : 'N/A'}
          change="Across all workflows"
          icon={TrendingUp}
        />
        <StatCard
          title="API Calls Today"
          value={metrics ? metrics.total_requests_today.toLocaleString() : '0'}
          change={metrics ? `${Math.round((metrics.api_usage.current / metrics.api_usage.limit) * 100)}% of quota` : 'N/A'}
          icon={Activity}
        />
        <StatCard
          title="Active Insights"
          value={insights.length.toString()}
          change="AI-generated"
          icon={PieChart}
        />
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <ChartCard
          title="Workflow Performance"
          subtitle="Accuracy over time"
        >
          <div className="h-64 flex items-center justify-center text-slate-500">
            Chart visualization coming soon - integrate with charting library
          </div>
        </ChartCard>
        <ChartCard
          title="API Usage"
          subtitle="Requests per day"
        >
          <div className="h-64 flex items-center justify-center text-slate-500">
            Chart visualization coming soon - integrate with charting library
          </div>
        </ChartCard>
      </div>

      {/* Recent Insights */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <h2 className="text-lg font-semibold text-white mb-4">Recent Insights</h2>
        {insights.length > 0 ? (
          <div className="space-y-4">
            {insights.map((insight) => (
              <InsightItem
                key={insight.id}
                type={insight.type === 'root_cause' ? 'Root Cause Analysis' : insight.type === 'forecast' ? 'Forecast' : 'Anomaly Detection'}
                message={insight.description}
                confidence={`${Math.round(insight.confidence * 100)}%`}
                time={new Date(insight.created_at).toLocaleString()}
              />
            ))}
          </div>
        ) : (
          <p className="text-slate-400 text-center py-8">No insights available yet.</p>
        )}
      </div>
        </>
      )}
    </div>
  )
}

function StatCard({ title, value, change, icon: Icon }: any) {
  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      <div className="flex items-start justify-between mb-4">
        <Icon className="w-6 h-6 text-purple-400" />
      </div>
      <h3 className="text-2xl font-bold text-white mb-1">{value}</h3>
      <p className="text-sm text-slate-400 mb-2">{title}</p>
      <p className="text-xs text-green-400">{change}</p>
    </div>
  )
}

function ChartCard({ title, subtitle, children }: any) {
  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      <div className="mb-4">
        <h3 className="text-base font-semibold text-white">{title}</h3>
        <p className="text-sm text-slate-400">{subtitle}</p>
      </div>
      {children}
    </div>
  )
}

function InsightItem({ type, message, confidence, time }: any) {
  return (
    <div className="p-4 bg-slate-800/50 rounded-lg border border-slate-700">
      <div className="flex items-start justify-between mb-2">
        <span className="text-sm font-medium text-purple-400">{type}</span>
        <span className="text-xs text-slate-500">{time}</span>
      </div>
      <p className="text-sm text-slate-300 mb-2">{message}</p>
      <div className="flex items-center gap-2">
        <span className="text-xs text-slate-500">Confidence:</span>
        <span className="text-xs font-medium text-green-400">{confidence}</span>
      </div>
    </div>
  )
}
