'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function FederationCommandRoom() {
  const [nodes, setNodes] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.federation.nodes().then((d) => { setNodes((d as { nodes: Record<string, unknown>[] }).nodes || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading federation command...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-purple-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Federation Command</span><span className="text-[var(--color-slate-muted)]">{nodes.length} connected observatories</span></div>
      <div className="grid grid-cols-2 gap-3">
        {nodes.map((n) => (<div key={String(n.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(n.name)}</span>
            <span className={`text-[10px] px-1.5 rounded font-mono ${String(n.status) === 'online' ? 'bg-green-900/40 text-green-300' : String(n.status) === 'degraded' ? 'bg-amber-900/40 text-amber-300' : 'bg-red-900/40 text-red-300'}`}>{String(n.status)}</span>
          </div>
          <div className="grid grid-cols-3 gap-2 text-[10px]">
            <div><span className="text-[var(--color-slate-muted)]">Latency</span><p className="font-mono">{String(n.latency_ms)}ms</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Discoveries</span><p className="font-mono text-[var(--color-cyan-bright)]">{String(n.discoveries_shared)}</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Uptime</span><p className="font-mono">{String(n.uptime_hours)}h</p></div>
          </div>
          <div className="text-[9px] text-[var(--color-slate-muted)]">v{String(n.version)} · {String(n.location)}</div>
        </div>))}
      </div>
    </div>
  )
}
