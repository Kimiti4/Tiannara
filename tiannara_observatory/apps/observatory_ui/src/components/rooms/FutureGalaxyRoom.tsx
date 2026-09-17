'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function FutureGalaxyRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.futures.list().catch(() => ({ futures: [] })),
      api.futures.rankings().catch(() => ({ rankings: [] })),
    ]).then(([l, r]) => { setData({ list: l, rankings: r }); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading future galaxy...</div>

  const futures = ((data.list as Record<string, unknown>).futures || []) as Record<string, unknown>[]
  const rankings = ((data.rankings as Record<string, unknown>).rankings || []) as [string, Record<string, unknown>][]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-indigo-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Future Galaxy</span><span className="text-[var(--color-slate-muted)]">{futures.length} futures · each a node</span></div>
      <div className="grid grid-cols-4 gap-2">
        {['deterministic', 'stochastic', 'adversarial', 'optimistic', 'catastrophic'].map((t) => {
          const count = futures.filter((f) => String(f.type) === t).length
          return (<div key={t} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2 space-y-1">
            <h4 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] uppercase">{t}</h4><p className="font-mono text-[var(--color-cyan-bright)]">{count}</p>
          </div>)
        })}
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2 space-y-1">
          <h4 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] uppercase">total</h4><p className="font-mono text-white">{futures.length}</p>
        </div>
      </div>
      {rankings.length > 0 && <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Constitutional Fitness Rankings</h4>
        {rankings.map(([id, s]) => (<div key={id} className="flex justify-between text-[11px]"><span className="text-[var(--color-slate-secondary)] font-mono">{id}</span><span className="font-mono text-green-400">{(Number(s.overall || 0) * 100).toFixed(0)}%</span></div>))}
      </div>}
      <div className="grid grid-cols-2 gap-3">
        {futures.slice(0, 8).map((f) => (<div key={String(f.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(f.name)}</span><span className={`text-[9px] px-1.5 rounded font-mono ${Number(f.fitness || 0) >= 0.7 ? 'bg-green-900/40 text-green-300' : 'bg-amber-900/40 text-amber-300'}`}>{(Number(f.fitness || 0) * 100).toFixed(0)}%</span></div>
          <div className="grid grid-cols-3 gap-1 text-[10px]"><span className="text-[var(--color-slate-muted)]">prob: {(Number(f.probability || 0) * 100).toFixed(0)}%</span><span className="text-amber-400">risk: {(Number(f.risk || 0) * 100).toFixed(0)}%</span><span className="text-green-400">benefit: {(Number(f.benefit || 0) * 100).toFixed(0)}%</span></div>
        </div>))}
      </div>
    </div>
  )
}
