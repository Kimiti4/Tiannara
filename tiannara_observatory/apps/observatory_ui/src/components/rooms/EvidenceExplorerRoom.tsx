'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function EvidenceExplorerRoom() {
  const [stats, setStats] = useState<Record<string, unknown>>({})
  const [assumptions, setAssumptions] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.epistemic.evidence().catch(() => ({})),
      api.epistemic.assumptions().catch(() => ({ assumptions: [] })),
    ]).then(([s, a]) => {
      setStats(s as Record<string, unknown>)
      setAssumptions((a as { assumptions: Record<string, unknown>[] }).assumptions || [])
      setLoading(false)
    })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading evidence explorer...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-cyan-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Evidence Explorer</span>
        <span className="text-[var(--color-slate-muted)]">evidence → hypothesis → theory → principle</span>
      </div>

      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Graph Stats</h4>
        <div className="grid grid-cols-2 gap-2 text-[11px]">
          <div><span className="text-[var(--color-slate-muted)]">Edges </span><span className="font-mono text-[var(--color-cyan-bright)]">{String(stats.total_edges ?? '—')}</span></div>
          <div><span className="text-[var(--color-slate-muted)]">Table Size </span><span className="font-mono text-[var(--color-cyan-bright)]">{String(stats.table_size ?? '—')}</span></div>
        </div>
      </div>

      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Assumption Registry</h4>
        {assumptions.length === 0 ? (
          <p className="text-[var(--color-slate-muted)] italic text-[10px]">No assumptions registered.</p>
        ) : (
          assumptions.slice(0, 10).map((a) => (
            <div key={String(a.id)} className="flex justify-between text-[11px] border-b border-[var(--color-slate-border)] last:border-0 pb-1 mb-1 last:pb-0 last:mb-0">
              <div className="flex-1">
                <span className="text-[var(--color-slate-secondary)]">{String(a.description)}</span>
                <span className="text-[var(--color-slate-muted)] ml-2">({String(a.subsystem)})</span>
              </div>
              <span className={`ml-2 text-[10px] ${a.verified ? 'text-green-400' : 'text-amber-400'}`}>
                {a.verified ? 'verified' : 'unverified'}
              </span>
            </div>
          ))
        )}
      </div>
    </div>
  )
}
