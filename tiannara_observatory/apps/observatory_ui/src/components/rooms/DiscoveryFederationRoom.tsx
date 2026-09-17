'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function DiscoveryFederationRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.federation.exchanges().catch(() => ({ exchanges: [], stats: {} })),
      api.federation.members().catch(() => ({ members: [], stats: {} })),
    ]).then(([e, m]) => { setData({ exchanges: e, members: m }); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading discovery federation...</div>

  const exchanges = ((data.exchanges as Record<string, unknown>).exchanges || []) as Record<string, unknown>[]
  const members = ((data.members as Record<string, unknown>).members || []) as Record<string, unknown>[]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-cyan-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Discovery Federation</span><span className="text-[var(--color-slate-muted)]">discoveries propagating between nodes</span></div>
      <div className="grid grid-cols-2 gap-2">
        {exchanges.map((ex) => (<div key={String(ex.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between text-[10px]"><span className="text-[var(--color-cyan-bright)] font-mono">{String(ex.from)} → {String(ex.to)}</span><span className={`text-[9px] px-1 font-mono ${ex.verified ? 'bg-green-900/40 text-green-300' : 'bg-amber-900/40 text-amber-300'}`}>{ex.verified ? 'verified' : 'pending'}</span></div>
          <p className="text-[var(--color-slate-secondary)] text-[11px]">{String(ex.content)}</p>
          <span className="text-[9px] text-[var(--color-slate-muted)]">type: {String(ex.type)}</span>
        </div>))}
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Federation Members</h4>
        <div className="grid grid-cols-3 gap-2">
          {members.map((m) => (<div key={String(m.id)} className="text-[10px] space-y-0.5"><span className="text-[var(--color-cyan-bright)] font-mono">{String(m.name)}</span><p className="text-[var(--color-slate-muted)]">{String(m.type)} · {String(m.active_projects)} projects</p></div>))}
        </div>
      </div>
    </div>
  )
}
