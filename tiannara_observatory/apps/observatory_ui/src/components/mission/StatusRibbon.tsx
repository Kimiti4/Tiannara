'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'
import { useWebSocket } from '@/lib/websocket'

export function StatusRibbon() {
  const [clock, setClock] = useState(new Date().toISOString().slice(11, 19))
  const [uptime, setUptime] = useState<number>(0)
  const { connected } = useWebSocket('status')

  useEffect(() => {
    const t = setInterval(() => setClock(new Date().toISOString().slice(11, 19)), 1000)
    return () => clearInterval(t)
  }, [])

  useEffect(() => {
    const fetch = () => api.status().then((s) => setUptime(s.uptime ?? 0)).catch(() => {})
    fetch()
    const i = setInterval(fetch, 30000)
    return () => clearInterval(i)
  }, [])

  const fmtUptime = (s: number) => {
    const d = Math.floor(s / 86400)
    const h = Math.floor((s % 86400) / 3600)
    return `${d}d ${h}h`
  }

  return (
    <footer className="flex h-7 items-center justify-between border-t border-slate-800 bg-slate-950 px-3 text-[10px] text-slate-600">
      <div className="flex items-center gap-3">
        <span className={`flex items-center gap-1 ${connected ? 'text-green-500' : 'text-red-500'}`}>
          <span className={`inline-block h-1.5 w-1.5 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'}`} />
          {connected ? 'LIVE' : 'OFFLINE'}
        </span>
        <span>Up {fmtUptime(uptime)}</span>
      </div>
      <div className="flex items-center gap-3">
        <span>v0.1.0</span>
        <span>{clock} UTC</span>
      </div>
    </footer>
  )
}
