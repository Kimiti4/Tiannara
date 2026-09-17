/**
 * WebSocket Reconnection Manager
 * 
 * Provides robust auto-reconnection logic with exponential backoff,
 * jitter, and maximum retry limits for handling network failures gracefully.
 */

export interface ReconnectionConfig {
  maxAttempts: number
  initialDelay: number
  maxDelay: number
  backoffMultiplier: number
  jitter: boolean
}

export interface ReconnectionState {
  attempts: number
  isConnected: boolean
  isReconnecting: boolean
  lastError: Error | null
  nextRetryAt: Date | null
}

export type ReconnectionCallback = (state: ReconnectionState) => void

export class WebSocketReconnector {
  private config: ReconnectionConfig
  private state: ReconnectionState
  private timeoutId: NodeJS.Timeout | null = null
  private callbacks: ReconnectionCallback[] = []
  private connectFn: () => Promise<WebSocket>
  private ws: WebSocket | null = null

  constructor(
    connectFn: () => Promise<WebSocket>,
    config: Partial<ReconnectionConfig> = {}
  ) {
    this.connectFn = connectFn
    this.config = {
      maxAttempts: config.maxAttempts ?? 10,
      initialDelay: config.initialDelay ?? 1000,
      maxDelay: config.maxDelay ?? 30000,
      backoffMultiplier: config.backoffMultiplier ?? 2,
      jitter: config.jitter ?? true,
    }

    this.state = {
      attempts: 0,
      isConnected: false,
      isReconnecting: false,
      lastError: null,
      nextRetryAt: null,
    }
  }

  /**
   * Calculate delay with exponential backoff and optional jitter
   */
  private calculateDelay(attempt: number): number {
    const exponentialDelay = Math.min(
      this.config.initialDelay * Math.pow(this.config.backoffMultiplier, attempt - 1),
      this.config.maxDelay
    )

    if (this.config.jitter) {
      // Add random jitter (±25%) to prevent thundering herd
      const jitterRange = exponentialDelay * 0.25
      const jitter = Math.random() * jitterRange * 2 - jitterRange
      return exponentialDelay + jitter
    }

    return exponentialDelay
  }

  /**
   * Start connection with automatic reconnection on failure
   */
  async connect(): Promise<WebSocket> {
    try {
      this.ws = await this.connectFn()
      
      this.updateState({
        isConnected: true,
        isReconnecting: false,
        attempts: 0,
        lastError: null,
        nextRetryAt: null,
      })

      // Setup close handler for reconnection
      this.ws.onclose = (event) => {
        console.log(`🔌 WebSocket closed (code: ${event.code}, reason: ${event.reason || 'none'})`)
        
        if (!event.wasClean) {
          // Abnormal closure - attempt reconnection
          this.handleDisconnect(new Error(`Connection lost (code: ${event.code})`))
        } else {
          // Clean closure - don't reconnect
          this.updateState({
            isConnected: false,
            isReconnecting: false,
          })
        }
      }

      this.ws.onerror = (error) => {
        console.error('❌ WebSocket error:', error)
        this.updateState({
          lastError: new Error('WebSocket connection error'),
        })
      }

      return this.ws
    } catch (error) {
      this.handleDisconnect(error as Error)
      throw error
    }
  }

  /**
   * Handle disconnection and schedule reconnection
   */
  private handleDisconnect(error: Error) {
    this.updateState({
      isConnected: false,
      lastError: error,
    })

    if (this.state.attempts >= this.config.maxAttempts) {
      console.error(`⛔ Max reconnection attempts reached (${this.config.maxAttempts})`)
      this.updateState({
        isReconnecting: false,
        nextRetryAt: null,
      })
      return
    }

    const delay = this.calculateDelay(this.state.attempts + 1)
    const nextRetryAt = new Date(Date.now() + delay)

    this.updateState({
      isReconnecting: true,
      nextRetryAt,
    })

    console.log(
      `🔄 Reconnecting in ${(delay / 1000).toFixed(1)}s ` +
      `(attempt ${this.state.attempts + 1}/${this.config.maxAttempts})`
    )

    this.timeoutId = setTimeout(async () => {
      this.updateState({
        attempts: this.state.attempts + 1,
      })

      try {
        await this.connect()
        console.log('✅ Reconnection successful')
      } catch (error) {
        console.error('❌ Reconnection failed:', error)
        // Recursive reconnection will be triggered by handleDisconnect
      }
    }, delay)
  }

  /**
   * Manually disconnect and stop reconnection attempts
   */
  disconnect() {
    if (this.timeoutId) {
      clearTimeout(this.timeoutId)
      this.timeoutId = null
    }

    if (this.ws) {
      this.ws.close(1000, 'Client disconnected')
      this.ws = null
    }

    this.updateState({
      isConnected: false,
      isReconnecting: false,
      attempts: 0,
      nextRetryAt: null,
    })
  }

  /**
   * Subscribe to reconnection state changes
   */
  subscribe(callback: ReconnectionCallback): () => void {
    this.callbacks.push(callback)
    
    // Immediately notify with current state
    callback(this.state)

    // Return unsubscribe function
    return () => {
      this.callbacks = this.callbacks.filter(cb => cb !== callback)
    }
  }

  /**
   * Update state and notify subscribers
   */
  private updateState(updates: Partial<ReconnectionState>) {
    this.state = { ...this.state, ...updates }
    
    // Notify all subscribers
    this.callbacks.forEach(callback => {
      try {
        callback(this.state)
      } catch (error) {
        console.error('Error in reconnection callback:', error)
      }
    })
  }

  /**
   * Get current reconnection state
   */
  getState(): ReconnectionState {
    return { ...this.state }
  }

  /**
   * Check if currently connected
   */
  isConnected(): boolean {
    return this.state.isConnected
  }

  /**
   * Check if currently attempting to reconnect
   */
  isReconnecting(): boolean {
    return this.state.isReconnecting
  }

  /**
   * Get the underlying WebSocket instance
   */
  getWebSocket(): WebSocket | null {
    return this.ws
  }
}

/**
 * Create a WebSocket with authentication token
 */
/**
 * Open WebSocket with session cookie (no token in URL).
 * Browser sends HttpOnly cookie automatically for same-origin ws:// host.
 */
export function createCookieWebSocket(url: string): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    try {
      const ws = new WebSocket(url)

      const timeout = setTimeout(() => {
        ws.close()
        reject(new Error('WebSocket connection timeout'))
      }, 10000)

      ws.onopen = () => {
        clearTimeout(timeout)
        resolve(ws)
      }
      ws.onerror = (error) => {
        clearTimeout(timeout)
        reject(error)
      }
    } catch (error) {
      reject(error)
    }
  })
}

/** @deprecated Use createCookieWebSocket — tokens in query strings are not supported. */
export function createAuthenticatedWebSocket(url: string, _token?: string): Promise<WebSocket> {
  return createCookieWebSocket(url)
}

/**
 * Create a simple WebSocket without authentication
 */
export function createSimpleWebSocket(url: string): Promise<WebSocket> {
  return new Promise((resolve, reject) => {
    try {
      const ws = new WebSocket(url)

      ws.onopen = () => resolve(ws)
      ws.onerror = (error) => reject(error)
      
      // Set a connection timeout
      const timeout = setTimeout(() => {
        ws.close()
        reject(new Error('WebSocket connection timeout'))
      }, 10000)

      ws.onopen = () => {
        clearTimeout(timeout)
        resolve(ws)
      }
    } catch (error) {
      reject(error)
    }
  })
}
