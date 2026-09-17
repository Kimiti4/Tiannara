'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function OpportunityObservatoryRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.strategy.opportunities().then((d) => { setData(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading opportunity observatory...</div>

  const opportunities = (data.opportunities || []) as Record<string, unknown>[]
  const pipeline = (data.pipeline || {}) as Record<string, unknown>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-emerald-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Opportunity Observatory</span><span className="text-[var(--color-slate-muted)]">new strategic directions</span></div>
      <div className="grid grid-cols-3 gap-2">
        {Object.entries(pipeline).map(([k, v]) => (<div key={k} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2 space-y-1">
          <h4 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] uppercase">{k}</h4><p className="font-mono text-[var(--color-cyan-bright)]">{String(v)}</p>
        </div>))}
      </div>
      {opportunities.map((o) => {
        const crossDomain = o.cross_domain as string[] | undefined
        return (<div key={String(o.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(o.name)}</span><span className="text-[10px] text-[var(--color-slate-muted)]">{String(o.type)}</span></div>
        <div className="grid grid-cols-3 gap-2 text-[10px]">
          <div><span className="text-[var(--color-slate-muted)]">Impact</span><p className="font-mono text-green-400">{(Number(o.impact || 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Confidence</span><p className="font-mono text-amber-400">{(Number(o.confidence || 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Timeline</span><p className="font-mono text-[var(--color-cyan-bright)]">{String(o.timeline_months)}mo</p></div>
        </div>
        {crossDomain && Array.isArray(crossDomain) && <div className="flex gap-1 flex-wrap"><span className="text-[var(--color-slate-muted)] text-[9px]">cross-domain:</span> {crossDomain.map((d) => <span key={d} className="text-[9px] bg-[var(--color-slate-surface)] px-1 rounded text-[var(--color-slate-secondary)]">{d}</span>)}</div>}
      </div>)
      })}
    </div>
  )
}
