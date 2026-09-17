'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function BottleneckObservatoryRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.strategy.bottlenecks().then((d) => { setData(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading bottleneck observatory...</div>

  const bottlenecks = (data.bottlenecks || []) as Record<string, unknown>[]
  const rankings = (data.rankings || {}) as Record<string, unknown>

  const rankKeys = ['highest_impact', 'highest_cost', 'most_urgent', 'most_likely', 'highest_leverage']
  const rankLabels: Record<string, string> = { highest_impact: 'Highest Impact', highest_cost: 'Highest Cost', most_urgent: 'Most Urgent', most_likely: 'Most Likely', highest_leverage: 'Highest Leverage' }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-orange-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Bottleneck Observatory</span><span className="text-[var(--color-slate-muted)]">ranked strategic bottlenecks</span></div>
      <div className="grid grid-cols-1 gap-3">
        {rankKeys.map((rk) => {
          const items = (rankings[rk] || []) as Record<string, unknown>[]
          return (<div key={rk} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">{rankLabels[rk]}</h4>
            {items.map((b) => (<div key={String(b.id)} className="flex justify-between text-[11px] py-0.5"><span className="text-[var(--color-slate-secondary)]">{String(b.description)}</span><span className="font-mono text-amber-400">{(Number(b.impact || 0) * 100).toFixed(0)}%</span></div>))}
          </div>)
        })}
      </div>
    </div>
  )
}
