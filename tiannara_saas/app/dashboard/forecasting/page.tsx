'use client'

import { useState, useEffect } from 'react'
import { Activity, TrendingUp, Calendar, AlertCircle, Loader2 } from 'lucide-react'
import { apiClient } from '@/lib/api'

export default function ForecastingPage() {
  const [predictions, setPredictions] = useState<any[]>([])
  const [metrics, setMetrics] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    fetchForecastingData()
  }, [])

  const fetchForecastingData = async () => {
    try {
      setLoading(true)
      setError(null)
      
      const [predictionsRes, metricsRes] = await Promise.all([
        apiClient.getPredictions(),
        apiClient.getDashboardMetrics()
      ])
      
      if (predictionsRes.success && predictionsRes.data) {
        setPredictions(predictionsRes.data)
      }
      
      if (metricsRes.success && metricsRes.data) {
        setMetrics(metricsRes.data)
      }
    } catch (err) {
      console.error('Failed to fetch forecasting data:', err)
      setError('Failed to load forecasting data')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-white mb-2">Forecasting</h1>
        <p className="text-slate-400">Predict trends and future outcomes with confidence scores</p>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-20">
          <Loader2 className="w-8 h-8 text-purple-500 animate-spin" />
        </div>
      ) : error ? (
        <div className="bg-red-500/10 border border-red-500/20 rounded-xl p-6 text-center">
          <p className="text-red-400">{error}</p>
          <button 
            onClick={fetchForecastingData}
            className="mt-4 px-4 py-2 bg-purple-500 hover:bg-purple-600 text-white rounded-lg transition-colors"
          >
            Retry
          </button>
        </div>
      ) : (
        <>
      {/* Active Forecasts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        {predictions.length > 0 ? (
          predictions.map((prediction) => (
            <ForecastCard
              key={prediction.id}
              title={prediction.metric.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
              prediction={typeof prediction.predicted_value === 'number' 
                ? prediction.predicted_value.toLocaleString() 
                : prediction.predicted_value}
              timeframe="Next period"
              confidence={`${Math.round(prediction.confidence * 100)}%`}
              trend="neutral"
              details={`Model: ${prediction.model} | Confidence interval: ${prediction.confidence_interval?.lower?.toLocaleString() || 'N/A'} - ${prediction.confidence_interval?.upper?.toLocaleString() || 'N/A'}`}
            />
          ))
        ) : (
          <div className="col-span-2 text-center py-12">
            <p className="text-slate-400">No predictions available yet. Run workflows to generate forecasts.</p>
          </div>
        )}
      </div>

      {/* Forecast Trends */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 mb-8">
        <h2 className="text-lg font-semibold text-white mb-4">Prediction Accuracy Trends</h2>
        <div className="h-64 flex items-center justify-center text-slate-500">
          Chart visualization coming soon - integrate with charting library
        </div>
      </div>

      {/* System Metrics */}
      {metrics && (
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h2 className="text-lg font-semibold text-white mb-4">Current System Status</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="p-4 bg-slate-800/50 rounded-lg">
              <p className="text-sm text-slate-400 mb-1">API Usage</p>
              <p className="text-2xl font-bold text-white">{metrics.api_usage.current.toLocaleString()} / {metrics.api_usage.limit.toLocaleString()}</p>
              <p className="text-xs text-green-400 mt-2">{Math.round((metrics.api_usage.current / metrics.api_usage.limit) * 100)}% of monthly quota</p>
            </div>
            <div className="p-4 bg-slate-800/50 rounded-lg">
              <p className="text-sm text-slate-400 mb-1">Error Rate</p>
              <p className="text-2xl font-bold text-white">{metrics.error_rate}%</p>
              <p className="text-xs text-green-400 mt-2">Within acceptable range</p>
            </div>
            <div className="p-4 bg-slate-800/50 rounded-lg">
              <p className="text-sm text-slate-400 mb-1">Avg Response Time</p>
              <p className="text-2xl font-bold text-white">{metrics.avg_response_time_ms}ms</p>
              <p className="text-xs text-green-400 mt-2">Optimal performance</p>
            </div>
          </div>
        </div>
      )}
        </>
      )}
    </div>
  )
}

function ForecastCard({ title, prediction, timeframe, confidence, trend, details }: any) {
  const trendColors = {
    up: 'text-green-400',
    down: 'text-red-400',
    neutral: 'text-blue-400',
  }

  const trendIcons = {
    up: TrendingUp,
    down: AlertCircle,
    neutral: Activity,
  }

  const TrendIcon = trendIcons[trend as keyof typeof trendIcons] || Activity

  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6 hover:border-purple-500/40 transition-colors">
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="text-base font-semibold text-white mb-1">{title}</h3>
          <p className="text-sm text-slate-400">{timeframe}</p>
        </div>
        <TrendIcon className={`w-5 h-5 ${trendColors[trend as keyof typeof trendColors]}`} />
      </div>
      
      <div className="mb-4">
        <p className="text-2xl font-bold text-white mb-1">{prediction}</p>
        <p className="text-sm text-slate-400">{details}</p>
      </div>
      
      <div className="flex items-center justify-between pt-4 border-t border-slate-800">
        <div className="flex items-center gap-2">
          <Calendar className="w-4 h-4 text-slate-500" />
          <span className="text-xs text-slate-400">{timeframe}</span>
        </div>
        <div className="px-3 py-1 bg-purple-500/20 rounded-full">
          <span className="text-xs font-medium text-purple-400">Confidence: {confidence}</span>
        </div>
      </div>
    </div>
  )
}
