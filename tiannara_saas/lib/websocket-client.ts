/**
 * WebSocket Client for Real-time Metrics
 * 
 * Connects to Tiannara API Gateway WebSocket endpoint
 * to receive real-time updates on:
 * - Workflow execution status
 * - API usage metrics
 * - System insights
 * - Prediction accuracy
 * - Active automations
 * 
 * Features robust auto-reconnection with exponential backoff.
 */

import { WebSocketReconnector, createCookieWebSocket } from './websocket-reconnector'

export interface RealtimeMetrics {
  api_usage: {
    current: number
    limit: number
    percentage: number
  }
  active_workflows: Array<{
    id: string
    name: string
    status: 'running' | 'paused' | 'completed' | 'failed'
    last_run: string
    accuracy?: number
    nodes: string[]
  }>
  system_insights: Array<{
    type: 'root_cause' | 'forecast' | 'anomaly' | 'recommendation'
    title: string
    message: string
    confidence?: number
    timestamp: string
  }>
  prediction_accuracy: number
  alerts_count: number
  automation_status: Array<{
    id: string
    name: string
    status: 'active' | 'paused' | 'triggered'
    last_triggered?: string
  }>
}

export interface ConnectionStatus {
  isConnected: boolean
  isReconnecting: boolean
  attempts: number
  lastError: string | null
}

export class RealtimeMetricsClient {
  private reconnector: WebSocketReconnector | null = null
  private listeners: Array<(data: RealtimeMetrics) => void> = []
  private url: string
  private connectionStatusListeners: Array<(status: ConnectionStatus) => void> = []

  constructor(baseUrl?: string) {
    const wsBase =
      baseUrl ||
      process.env.NEXT_PUBLIC_WS_URL ||
      (typeof window !== 'undefined'
        ? `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}`
        : 'ws://127.0.0.1:8004')
    this.url = `${wsBase}/ws/metrics`
  }

  /** Connect using HttpOnly session cookie (login required first). */
  async connect(): Promise<void> {
    this.reconnector = new WebSocketReconnector(
      () => createCookieWebSocket(this.url),
      {
        maxAttempts: 10,
        initialDelay: 1000,
        maxDelay: 30000,
        backoffMultiplier: 2,
        jitter: true,
      }
    )

    // Subscribe to connection status changes
    this.reconnector.subscribe((state) => {
      const status: ConnectionStatus = {
        isConnected: state.isConnected,
        isReconnecting: state.isReconnecting,
        attempts: state.attempts,
        lastError: state.lastError?.message || null,
      }
      this.notifyConnectionStatus(status)
    })

    try {
      const ws = await this.reconnector.connect()
      console.log('✅ WebSocket connected for realtime metrics')

      // Setup message handler
      ws.onmessage = (event) => {
        try {
          const data: RealtimeMetrics = JSON.parse(event.data)
          this.notifyListeners(data)
        } catch (error) {
          console.error('Failed to parse WebSocket message:', error)
        }
      }
    } catch (error) {
      console.error('Failed to connect WebSocket:', error)
      throw error
    }
  }

  /**
   * Subscribe to connection status changes
   */
  onConnectionStatus(callback: (status: ConnectionStatus) => void): () => void {
    this.connectionStatusListeners.push(callback)
    return () => {
      this.connectionStatusListeners = this.connectionStatusListeners.filter(cb => cb !== callback)
    }
  }

  private notifyConnectionStatus(status: ConnectionStatus) {
    this.connectionStatusListeners.forEach(callback => {
      try {
        callback(status)
      } catch (error) {
        console.error('Error in connection status listener:', error)
      }
    })
  }

  subscribe(callback: (data: RealtimeMetrics) => void): () => void {
    this.listeners.push(callback)
    
    // Return unsubscribe function
    return () => {
      this.listeners = this.listeners.filter(cb => cb !== callback)
    }
  }

  private notifyListeners(data: RealtimeMetrics) {
    this.listeners.forEach(callback => {
      try {
        callback(data)
      } catch (error) {
        console.error('Error in metrics listener:', error)
      }
    })
  }

  disconnect() {
    if (this.reconnector) {
      this.reconnector.disconnect()
      this.reconnector = null
    }
    this.token = null
  }

  /**
   * Get current connection status
   */
  getConnectionStatus(): ConnectionStatus | null {
    if (!this.reconnector) return null
    
    const state = this.reconnector.getState()
    return {
      isConnected: state.isConnected,
      isReconnecting: state.isReconnecting,
      attempts: state.attempts,
      lastError: state.lastError?.message || null,
    }
  }
}

// Singleton instance
let metricsClient: RealtimeMetricsClient | null = null

export function getMetricsClient(): RealtimeMetricsClient {
  if (!metricsClient) {
    metricsClient = new RealtimeMetricsClient()
  }
  return metricsClient
}
