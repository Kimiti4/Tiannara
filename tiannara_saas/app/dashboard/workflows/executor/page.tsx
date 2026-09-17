'use client'

import { useState, useEffect, useRef } from 'react'
import { useRouter, useSearchParams } from 'next/navigation'
import { 
  CheckCircle, XCircle, Clock, ArrowLeft, Play, 
  BarChart3, Activity, Zap, AlertCircle, Loader2,
  Wifi, WifiOff
} from 'lucide-react'
import { apiClient } from '@/lib/api'
import { WebSocketReconnector, createSimpleWebSocket } from '@/lib/websocket-reconnector'

interface ExecutionNode {
  id: string
  type: string
  config: any
  status: string
  result?: any
  error?: string
  execution_time_ms?: number
  started_at?: string
  completed_at?: string
}

interface ExecutionResult {
  success: boolean
  execution_id: string
  status: string
  started_at: string
  completed_at: string
  total_execution_time_ms: number
  nodes: Record<string, ExecutionNode>
  error: string | null
  message: string
}

export default function WorkflowExecutorPage() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const executionId = searchParams.get('execution_id')
  
  const [execution, setExecution] = useState<ExecutionResult | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  
  // WebSocket state for real-time updates
  const [wsConnected, setWsConnected] = useState(false)
  const [wsReconnecting, setWsReconnecting] = useState(false)
  const [reconnectAttempts, setReconnectAttempts] = useState(0)
  const [liveProgress, setLiveProgress] = useState<number | null>(null)
  const [liveNodeStatuses, setLiveNodeStatuses] = useState<Record<string, string>>({})
  const reconnectorRef = useRef<WebSocketReconnector | null>(null)

  useEffect(() => {
    if (executionId) {
      fetchExecutionResult(executionId)
      connectWebSocket(executionId)
    }
    
    // Cleanup WebSocket on unmount
    return () => {
      if (reconnectorRef.current) {
        reconnectorRef.current.disconnect()
      }
    }
  }, [executionId])

  const fetchExecutionResult = async (execId: string) => {
    try {
      setLoading(true)
      setError(null)
      
      // Fetch real execution data from backend
      const response = await apiClient.getExecutionDetails(execId)
      
      if (response.success && response.data) {
        // Transform backend response to match frontend interface
        const executionData: ExecutionResult = {
          success: true,
          execution_id: response.data.execution_id,
          status: response.data.status,
          started_at: response.data.started_at,
          completed_at: response.data.completed_at,
          total_execution_time_ms: response.data.total_execution_time_ms,
          nodes: response.data.nodes,
          error: response.data.error,
          message: `Workflow execution ${response.data.status}`
        }
        
        setExecution(executionData)
      } else {
        setError(response.message || 'Failed to load execution details')
      }
    } catch (err: any) {
      console.error('Failed to fetch execution:', err)
      setError(err.message || 'Failed to load execution results')
    } finally {
      setLoading(false)
    }
  }

  const connectWebSocket = (execId: string) => {
    // Determine WebSocket URL based on current location
    const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:'
    const host = window.location.host
    const wsUrl = `${protocol}//${host}/ws/workflow/${execId}`
    
    console.log('🔌 Connecting to WebSocket:', wsUrl)
    
    // Create reconnection manager
    reconnectorRef.current = new WebSocketReconnector(
      () => createSimpleWebSocket(wsUrl),
      {
        maxAttempts: 15, // More attempts for long-running workflows
        initialDelay: 2000,
        maxDelay: 60000, // Max 1 minute between retries
        backoffMultiplier: 2,
        jitter: true,
      }
    )

    // Subscribe to connection status changes
    reconnectorRef.current.subscribe((state) => {
      setWsConnected(state.isConnected)
      setWsReconnecting(state.isReconnecting)
      setReconnectAttempts(state.attempts)
      
      if (state.lastError) {
        console.error('❌ WebSocket error:', state.lastError.message)
      }
    })

    // Connect and setup message handler
    reconnectorRef.current.connect()
      .then((ws) => {
        console.log('✅ WebSocket connected for workflow execution')
        
        ws.onmessage = (event) => {
          try {
            const data = JSON.parse(event.data)
            console.log('📨 WebSocket message:', data)
            
            // Handle different message types
            if (data.update_type === 'progress') {
              setLiveProgress(data.progress)
            } else if (data.update_type === 'node_status') {
              setLiveNodeStatuses(prev => ({
                ...prev,
                [data.node_id]: data.status
              }))
            } else if (data.update_type === 'execution_complete') {
              console.log('✅ Execution complete:', data)
              // Refresh execution data from API
              fetchExecutionResult(execId)
            } else if (data.update_type === 'error') {
              console.error('❌ Execution error:', data.error)
              setError(data.error)
            }
          } catch (e) {
            console.error('Failed to parse WebSocket message:', e)
          }
        }
      })
      .catch((error) => {
        console.error('Failed to connect WebSocket:', error)
        setError('Failed to establish real-time connection. Results will be fetched when available.')
      })
  }

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="w-5 h-5 text-green-400" />
      case 'failed':
        return <XCircle className="w-5 h-5 text-red-400" />
      case 'running':
        return <Loader2 className="w-5 h-5 text-blue-400 animate-spin" />
      default:
        return <Clock className="w-5 h-5 text-slate-400" />
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'text-green-400'
      case 'failed':
        return 'text-red-400'
      case 'running':
        return 'text-blue-400'
      default:
        return 'text-slate-400'
    }
  }

  if (loading) {
    return (
      <div className="p-8 max-w-7xl mx-auto">
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center">
            <Loader2 className="w-12 h-12 animate-spin text-purple-500 mx-auto mb-4" />
            <p className="text-slate-400">Loading execution results...</p>
          </div>
        </div>
      </div>
    )
  }

  if (error) {
    return (
      <div className="p-8 max-w-7xl mx-auto">
        <div className="bg-red-500/10 border border-red-500/30 rounded-xl p-6">
          <div className="flex items-center gap-3">
            <AlertCircle className="w-6 h-6 text-red-400" />
            <div>
              <h3 className="text-lg font-semibold text-red-400">Error</h3>
              <p className="text-red-300 text-sm mt-1">{error}</p>
            </div>
          </div>
          <button
            onClick={() => router.back()}
            className="mt-4 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors flex items-center gap-2"
          >
            <ArrowLeft className="w-4 h-4" />
            Go Back
          </button>
        </div>
      </div>
    )
  }

  if (!execution) {
    return (
      <div className="p-8 max-w-7xl mx-auto">
        <div className="text-center text-slate-400">
          <p>No execution found</p>
          <button
            onClick={() => router.back()}
            className="mt-4 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors"
          >
            Go Back
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <button
          onClick={() => router.back()}
          className="mb-4 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-white rounded-lg transition-colors flex items-center gap-2"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Templates
        </button>
        
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold text-white mb-2">Workflow Execution Results</h1>
            <p className="text-slate-400">
              Execution ID: <span className="font-mono text-cyan-400">{execution.execution_id}</span>
            </p>
          </div>
          
          <div className={`px-4 py-2 rounded-lg ${
            execution.status === 'completed' ? 'bg-green-500/20 text-green-400' :
            execution.status === 'failed' ? 'bg-red-500/20 text-red-400' :
            'bg-blue-500/20 text-blue-400'
          }`}>
            <div className="flex items-center gap-2">
              {getStatusIcon(execution.status)}
              <span className="font-medium capitalize">{execution.status}</span>
            </div>
          </div>
          
          {/* WebSocket Connection Status */}
          <div className={`px-3 py-1 rounded-full text-xs font-medium flex items-center gap-1.5 ${
            wsConnected ? 'bg-green-500/20 text-green-400' :
            wsReconnecting ? 'bg-yellow-500/20 text-yellow-400' :
            'bg-red-500/20 text-red-400'
          }`}>
            {wsConnected ? (
              <Wifi className="w-3 h-3" />
            ) : wsReconnecting ? (
              <Loader2 className="w-3 h-3 animate-spin" />
            ) : (
              <WifiOff className="w-3 h-3" />
            )}
            {wsConnected ? 'Live' : 
             wsReconnecting ? `Reconnecting (${reconnectAttempts})` : 
             'Disconnected'}
          </div>
        </div>
      </div>

      {/* Real-Time Progress Indicator */}
      {wsConnected && liveProgress !== null && (
        <div className="mb-8 bg-gradient-to-r from-purple-500/10 to-cyan-500/10 border border-purple-500/30 rounded-xl p-6">
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-2">
              <Zap className="w-5 h-5 text-purple-400 animate-pulse" />
              <h3 className="text-sm font-medium text-white">Live Execution Progress</h3>
            </div>
            <span className="text-xs text-slate-400">Real-time via WebSocket</span>
          </div>
          
          {/* Progress Bar */}
          <div className="relative h-3 bg-slate-800 rounded-full overflow-hidden">
            <div 
              className="absolute left-0 top-0 h-full bg-gradient-to-r from-purple-500 to-cyan-500 transition-all duration-300 ease-out"
              style={{ width: `${liveProgress}%` }}
            />
          </div>
          
          {/* Progress Percentage */}
          <div className="mt-2 flex items-center justify-between">
            <span className="text-sm text-slate-400">
              {Object.keys(liveNodeStatuses).length} nodes updated
            </span>
            <span className="text-lg font-bold text-white">
              {liveProgress.toFixed(0)}%
            </span>
          </div>
        </div>
      )}

      {/* Execution Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center gap-3 mb-2">
            <Clock className="w-5 h-5 text-purple-400" />
            <h3 className="text-sm font-medium text-slate-400">Total Time</h3>
          </div>
          <p className="text-2xl font-bold text-white">
            {(execution.total_execution_time_ms / 1000).toFixed(2)}s
          </p>
        </div>

        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center gap-3 mb-2">
            <Activity className="w-5 h-5 text-cyan-400" />
            <h3 className="text-sm font-medium text-slate-400">Nodes Executed</h3>
          </div>
          <p className="text-2xl font-bold text-white">
            {Object.keys(execution.nodes).length}
          </p>
        </div>

        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <div className="flex items-center gap-3 mb-2">
            <BarChart3 className="w-5 h-5 text-green-400" />
            <h3 className="text-sm font-medium text-slate-400">Success Rate</h3>
          </div>
          <p className="text-2xl font-bold text-white">
            {Math.round((Object.values(execution.nodes).filter(n => n.status === 'completed').length / Object.keys(execution.nodes).length) * 100)}%
          </p>
        </div>
      </div>

      {/* Node Execution Details */}
      <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
        <h2 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
          <Zap className="w-5 h-5 text-purple-400" />
          Execution Trace
        </h2>

        <div className="space-y-4">
          {Object.values(execution.nodes).map((node, index) => {
            // Use live WebSocket status if available, otherwise use stored status
            const displayStatus = liveNodeStatuses[node.id] || node.status
            
            return (
            <div
              key={node.id}
              className="bg-slate-800/50 border border-slate-700 rounded-lg p-4"
            >
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                    displayStatus === 'completed' ? 'bg-green-500/20' :
                    displayStatus === 'failed' ? 'bg-red-500/20' :
                    displayStatus === 'running' ? 'bg-blue-500/20' :
                    'bg-slate-700'
                  }`}>
                    <span className="text-sm font-bold text-white">{index + 1}</span>
                  </div>
                  <div>
                    <h3 className="text-white font-medium">{node.config.label || node.type}</h3>
                    <p className="text-xs text-slate-400">{node.type}</p>
                  </div>
                </div>
                
                <div className="flex items-center gap-3">
                  <span className={`text-sm ${getStatusColor(displayStatus)} capitalize`}>
                    {displayStatus}
                  </span>
                  {getStatusIcon(displayStatus)}
                </div>
              </div>

              {/* Execution Time */}
              {node.execution_time_ms && (
                <div className="mb-3 text-xs text-slate-400">
                  Execution time: {(node.execution_time_ms / 1000).toFixed(2)}s
                </div>
              )}

              {/* Results */}
              {node.result && (
                <div className="mt-3 p-3 bg-slate-900/50 rounded-lg">
                  <p className="text-xs text-slate-400 mb-2">Output:</p>
                  <pre className="text-xs text-green-400 overflow-x-auto">
                    {JSON.stringify(node.result, null, 2)}
                  </pre>
                </div>
              )}

              {/* Error */}
              {node.error && (
                <div className="mt-3 p-3 bg-red-500/10 border border-red-500/30 rounded-lg">
                  <p className="text-xs text-red-400">{node.error}</p>
                </div>
              )}
            </div>
          )})
          }
        </div>
      </div>

      {/* Actions */}
      <div className="mt-8 flex gap-4">
        <button
          onClick={() => router.push('/dashboard/workflows/templates')}
          className="px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white font-medium rounded-lg transition-colors flex items-center gap-2"
        >
          <Play className="w-4 h-4" />
          Run Another Template
        </button>
        
        <button
          onClick={() => router.push('/dashboard/workflows')}
          className="px-6 py-3 bg-slate-800 hover:bg-slate-700 text-white font-medium rounded-lg transition-colors"
        >
          View All Workflows
        </button>
      </div>
    </div>
  )
}
