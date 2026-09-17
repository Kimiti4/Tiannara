'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function GlobalKnowledgeMapRoom() {
  const [stats, setStats] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.federation.memory().then((d) => { setStats(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading global knowledge map...</div>

  const domains = (stats.domains || {}) as Record<string, number>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-emerald-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Global Knowledge Map</span><span className="text-[var(--color-slate-muted)]">living civilization-scale graph</span></div>
      <div className="grid grid-cols-4 gap-2">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Nodes</h4><p className="font-mono text-[var(--color-cyan-bright)]">{String(stats.total_nodes ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Edges</h4><p className="font-mono text-[var(--color-cyan-bright)]">{String(stats.total_edges ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Cross-refs</h4><p className="font-mono text-amber-400">{String(stats.cross_references ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Sync</h4><p className="font-mono text-green-400">{String(stats.sync_status ?? '—')}</p>
        </div>
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Knowledge by Domain</h4>
        {Object.entries(domains).sort(([, a], [, b]) => Number(b) - Number(a)).map(([d, c]) => (
          <div key={d} className="flex justify-between text-[11px]"><span className="text-[var(--color-slate-muted)]">{d}</span><span className="font-mono text-[var(--color-cyan-bright)]">{c}</span></div>
        ))}
      </div>
    </div>
  )
}
