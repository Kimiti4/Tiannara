'use client'

import { useEffect, useState } from 'react'
import { Activity, CheckCircle, ArrowUpRight, Loader2 } from 'lucide-react'
import { apiClient } from '@/lib/api'

interface UsageMetrics {
  total_calls: number
  success_rate: number
  top_endpoint: string
  endpoint_count: number
}

export default function APIUsageSummaryWidget() {
  const [metrics, setMetrics] = useState<UsageMetrics | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchUsageMetrics()
  }, [])

  const fetchUsageMetrics = async () => {
    try {
      setIsLoading(true)
      setError(null)
      
      const response = await apiClient.getUsageMetrics('7d')
      
      if (response.success && response.data) {
        // Calculate today's metrics from available data
        const todayData = response.data.daily_usage?.[0] || { requests: 0, success: 0 }
        const topDomain = response.data.domain_breakdown?.[0] || { domain: '/api/v1/algorithm/classify', count: 0 }
        
        setMetrics({
          total_calls: todayData.requests || 0,
          success_rate: todayData.requests > 0 ? (todayData.success / todayData.requests) * 100 : 0,
          top_endpoint: topDomain.domain || '/api/v1/algorithm/classify',
          endpoint_count: topDomain.count || 0
        })
      } else {
        setError(response.error || 'Failed to load metrics')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Network error')
    } finally {
      setIsLoading(false)
    }
  }

  if (isLoading) {
    return (
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <div className="flex items-center justify-center h-32">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="bg-slate-900/50 border border-red-800/50 rounded-xl p-6">
        <div className="text-center">
          <p className="text-red-400 mb-2">Failed to load usage metrics</p>
          <p className="text-sm text-slate-500 mb-4">{error}</p>
          <button
            onClick={fetchUsageMetrics}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-sm transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    )
  }

  if (!metrics) {
    return null
  }

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-gradient-to-br from-purple-500 to-purple-600 rounded-lg flex items-center justify-center">
            <Activity className="w-5 h-5 text-white" />
          </div>
          <div>
            <h3 className="text-lg font-semibold text-white">API Usage Summary</h3>
            <p className="text-sm text-slate-400">Today's activity</p>
          </div>
        </div>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {/* Total Calls */}
        <div className="bg-slate-950/50 rounded-lg p-4">
          <p className="text-sm text-slate-400 mb-2">Total Calls</p>
          <p className="text-2xl font-bold text-white">{metrics.total_calls.toLocaleString()}</p>
          <p className="text-xs text-slate-500 mt-1">API requests today</p>
        </div>

        {/* Success Rate */}
        <div className="bg-slate-950/50 rounded-lg p-4">
          <p className="text-sm text-slate-400 mb-2">Success Rate</p>
          <div className="flex items-baseline gap-2">
            <p className="text-2xl font-bold text-green-400">{metrics.success_rate.toFixed(1)}%</p>
            <CheckCircle className="w-4 h-4 text-green-400" />
          </div>
          <p className="text-xs text-slate-500 mt-1">Successful responses</p>
        </div>

        {/* Top Endpoint */}
        <div className="bg-slate-950/50 rounded-lg p-4">
          <p className="text-sm text-slate-400 mb-2">Top Endpoint</p>
          <div className="flex items-start gap-2">
            <ArrowUpRight className="w-4 h-4 text-cyan-400 mt-1 flex-shrink-0" />
            <div className="min-w-0">
              <p className="text-sm font-medium text-white truncate">{metrics.top_endpoint}</p>
              <p className="text-xs text-slate-500 mt-1">{metrics.endpoint_count} calls</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
