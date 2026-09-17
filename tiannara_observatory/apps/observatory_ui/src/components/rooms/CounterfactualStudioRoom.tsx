'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CounterfactualStudioRoom() {
  const [cfs, setCfs] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.futures.counterfactuals().then((d) => { setCfs((d as { counterfactuals: Record<string, unknown>[] }).counterfactuals || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading counterfactual studio...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-teal-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Counterfactual Studio</span><span className="text-[var(--color-slate-muted)]">interactive what-if sandbox</span></div>
      <div className="space-y-2">
        {cfs.sort((a, b) => Number(b.divergence_score || 0) - Number(a.divergence_score || 0)).map((cf) => {
        const changes = cf.changes as Record<string, number> | undefined
        return (<div key={String(cf.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono text-sm">What if: {String(cf.description)}</span><span className="font-mono text-amber-400 text-[10px]">{(Number(cf.divergence_score || 0) * 100).toFixed(0)}% divergence</span></div>
          <div className="grid grid-cols-3 gap-2 text-[10px]">
            {changes && Object.entries(changes).map(([k, v]) => (
              <div key={k}><span className="text-[var(--color-slate-muted)]">{k}</span><p className={`font-mono ${Number(v) >= 0 ? 'text-green-400' : 'text-red-400'}`}>{Number(v) >= 0 ? '+' : ''}{String(v)}</p></div>
            ))}
          </div>
        </div>)
      })}
      </div>
    </div>
  )
}
