'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CivilizationTimelineFederationRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.federation.memory().catch(() => ({})),
      api.federation.trust().catch(() => ({ trust_graph: [] })),
    ]).then(([mem, tr]) => { setData({ memory: mem, trust: tr }); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading civilization timeline (federation)...</div>

  const memory = data.memory as Record<string, unknown>
  const events = (memory.timeline || []) as Record<string, unknown>[]
  const trustGraph = ((data.trust as Record<string, unknown>).trust_graph || []) as Record<string, unknown>[]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-violet-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Civilization Timeline</span><span className="text-[var(--color-slate-muted)]">federated civilization memory</span></div>
      <div className="grid grid-cols-2 gap-2">
        {events.slice(0, 6).map((ev) => (<div key={String(ev.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(ev.event)}</span><span className="text-[9px] text-[var(--color-slate-muted)]">{String(ev.node)}</span></div>
          <p className="text-[var(--color-slate-secondary)] text-[10px]">{String(ev.description)}</p>
        </div>))}
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Trust Network</h4>
        {trustGraph.map((t) => (<div key={String(t.id) || String(t.from_node)} className="flex justify-between text-[10px]">
          <span className="font-mono">{String(t.from_node)} → {String(t.to_node)}</span>
          <span className={`${Number(t.trust_score || 0) > 0.7 ? 'text-green-400' : Number(t.trust_score || 0) > 0.4 ? 'text-amber-400' : 'text-red-400'}`}>{(Number(t.trust_score || 0) * 100).toFixed(0)}%</span>
        </div>))}
      </div>
    </div>
  )
}
