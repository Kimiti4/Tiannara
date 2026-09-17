'use client'

import { useEffect, useState, useRef } from 'react'
import type { MissionEvent } from '@/types'

function asMissionEvent(raw: Record<string, unknown>): MissionEvent {
  return {
    id: (raw.id as string) || crypto.randomUUID(),
    domain: (raw.domain as string) || 'unknown',
    type: (raw.type as string) || 'unknown',
    payload: (raw.payload as Record<string, unknown>) || {},
    timestamp: (raw.timestamp as string) || new Date().toISOString(),
    priority: (raw.priority as MissionEvent['priority']) || 'normal',
  }
}

export function useRoomStream(room: string, limit = 50) {
  const [events, setEvents] = useState<MissionEvent[]>([])
  const [connected, setConnected] = useState(false)
  const wsRef = useRef<WebSocket | null>(null)

  useEffect(() => {
    const url = process.env.NEXT_PUBLIC_WS_URL || 'ws://localhost:4000/ws'
    const ws = new WebSocket(url)
    wsRef.current = ws

    ws.onopen = () => {
      setConnected(true)
      ws.send(JSON.stringify({ topic: `obs:${room}`, event: 'phx_join', payload: {} }))
    }

    ws.onclose = () => setConnected(false)
    ws.onerror = () => setConnected(false)

    ws.onmessage = (msg) => {
      try {
        const data = JSON.parse(msg.data)
        const payload = (data as Record<string, unknown>).payload
        if (payload) {
          const batch = Array.isArray(payload) ? payload : [payload]
          setEvents((prev) => [
            ...batch.map((e: Record<string, unknown>) => asMissionEvent(e)),
            ...prev,
          ].slice(0, limit))
        }
      } catch { /* ignore */ }
    }

    return () => ws.close()
  }, [room, limit])

  return { events, connected }
}

export function useStreamMetrics(room: string) {
  const { events, connected } = useRoomStream(room)
  return {
    connected,
    totalEvents: events.length,
    domains: [...new Set(events.map((e) => e.domain))],
    priorityBreakdown: {
      constitutional: events.filter((e) => e.priority === 'constitutional').length,
      scientific: events.filter((e) => e.priority === 'scientific').length,
      alert: events.filter((e) => e.priority === 'alert').length,
      metric: events.filter((e) => e.priority === 'metric').length,
      normal: events.filter((e) => e.priority === 'normal' || !e.priority).length,
    },
    lastEvent: events[0] || null,
  }
}
