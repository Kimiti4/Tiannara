'use client'

import { useEffect, useRef, useState, useCallback } from 'react'

type MessageHandler = (data: unknown) => void

export function useWebSocket(channel: string, onEvent?: MessageHandler) {
  const [connected, setConnected] = useState(false)
  const [lastMessage, setLastMessage] = useState<unknown>(null)
  const wsRef = useRef<WebSocket | null>(null)
  const handlerRef = useRef(onEvent)

  useEffect(() => {
    handlerRef.current = onEvent
  }, [onEvent])

  useEffect(() => {
    const url = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:4000/ws'
    const ws = new WebSocket(url)
    wsRef.current = ws

    ws.onopen = () => {
      setConnected(true)
      ws.send(JSON.stringify({ topic: `obs:${channel}`, event: 'phx_join', payload: {} }))
    }

    ws.onclose = () => setConnected(false)
    ws.onerror = () => setConnected(false)

    ws.onmessage = (msg) => {
      try {
        const data = JSON.parse(msg.data)
        setLastMessage(data)
        handlerRef.current?.(data)
      } catch { /* ignore parse errors */ }
    }

    return () => ws.close()
  }, [channel])

  const send = useCallback((payload: unknown) => {
    wsRef.current?.send(JSON.stringify(payload))
  }, [])

  return { connected, lastMessage, send }
}
