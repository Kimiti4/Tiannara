'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function UnknownLandscapeRoom() {
  const [unknowns, setUnknowns] = useState<Record<string, unknown>[]>([])
  const [counts, setCounts] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.epistemic.unknowns().then((data) => {
      setUnknowns((data as { unknowns: Record<string, unknown>[]; counts: Record<string, unknown> }).unknowns || [])
      setCounts((data as { unknowns: Record<string, unknown>[]; counts: Record<string, unknown> }).counts || {})
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading unknown landscape...</div>

  const byType = counts as Record<string, number>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-purple-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Unknown Landscape</span>
        <span className="text-[var(--color-slate-muted)]">first-class unknown tracking</span>
      </div>

      <div className="grid grid-cols-3 gap-3">
        {Object.entries(byType).map(([type, count]) => (
          <div key={type} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">{type}</h4>
            <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{String(count)}</p>
          </div>
        ))}
      </div>

      {unknowns.length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Recent Unknowns</h4>
          {unknowns.slice(0, 10).map((u) => (
            <div key={String(u.id)} className="flex justify-between text-[11px] border-b border-[var(--color-slate-border)] last:border-0 pb-1 mb-1 last:pb-0 last:mb-0">
              <span className="text-[var(--color-slate-muted)] truncate flex-1">{String(u.description)}</span>
              <span className="text-[var(--color-slate-secondary)] font-mono ml-2">{String(u.type)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
