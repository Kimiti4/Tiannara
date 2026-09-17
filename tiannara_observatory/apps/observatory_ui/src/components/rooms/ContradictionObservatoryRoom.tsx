'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ContradictionObservatoryRoom() {
  const [contradictions, setContradictions] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.epistemic.contradictions().then((data) => {
      setContradictions((data as { contradictions: Record<string, unknown>[] }).contradictions || [])
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading contradictions...</div>

  const unresolved = contradictions.filter((c) => !c.resolved)
  const resolved = contradictions.filter((c) => c.resolved)

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-red-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Contradiction Observatory</span>
        <span className="text-[var(--color-slate-muted)]">live contradiction map</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Unresolved</h4>
          <p className="text-red-400 text-sm font-mono">{unresolved.length}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Resolved</h4>
          <p className="text-green-400 text-sm font-mono">{resolved.length}</p>
        </div>
      </div>

      {unresolved.length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Active Contradictions</h4>
          {unresolved.sort((a, b) => Number(b.importance || 0) - Number(a.importance || 0)).map((c) => (
            <div key={String(c.id)} className="border-b border-[var(--color-slate-border)] last:border-0 pb-1.5 mb-1.5 last:pb-0 last:mb-0">
              <div className="flex items-center gap-2">
                <span className={`text-[10px] px-1.5 py-0.5 rounded font-mono ${Number(c.importance || 0) >= 7 ? 'bg-red-900/40 text-red-300' : 'bg-amber-900/40 text-amber-300'}`}>
                  I{String(c.importance)}
                </span>
                <span className="text-[var(--color-slate-muted)] text-[10px]">{String(c.type)}</span>
              </div>
              <p className="text-[var(--color-slate-secondary)] text-xs mt-0.5">{String(c.description)}</p>
              <p className="text-[var(--color-slate-muted)] text-[9px]">{String(c.entity_a)} vs {String(c.entity_b)}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
