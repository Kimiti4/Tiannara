'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'
export function EpistemicAtlasRoom() {
  const [summary, setSummary] = useState<Record<string, unknown>>({})
  const [bias, setBias] = useState<{ readings: Record<string, unknown>[]; index: number }>({ readings: [], index: 0 })
  const [loading, setLoading] = useState(true)
  useEffect(() => {
    Promise.all([api.epistemic.summary().catch(() => ({})), api.epistemic.bias().catch(() => ({ readings: [], index: 0 }))])
      .then(([s, b]) => { setSummary(s as Record<string, unknown>); setBias(b as { readings: Record<string, unknown>[]; index: number }); setLoading(false) })
  }, [])
  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading epistemic atlas...</div>
  const categories = summary.categories as Record<string, number> | undefined
  return <div className="space-y-3 text-xs">
    <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-indigo-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Epistemic Atlas</span><span className="text-[var(--color-slate-muted)]">knowledge confidence · bias · assumptions</span></div>
    <div className="grid grid-cols-3 gap-3">
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Objects</h4>
        <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{String(summary.total_objects ?? '—')}</p>
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Mean Confidence</h4>
        <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{(Number(summary.mean_confidence ?? 0) * 100).toFixed(0)}%</p>
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Bias Index</h4>
        <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{(bias.index * 100).toFixed(0)}%</p>
      </div>
    </div>
    {categories && <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
      <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Confidence by Category</h4>
      {Object.entries(categories).map(([cat, cnt]) => (
        <div key={cat} className="flex justify-between text-[11px]"><span className="text-[var(--color-slate-muted)]">{cat}</span><span className="font-mono text-[var(--color-slate-secondary)]">{cnt}</span></div>
      ))}
    </div>}
  </div>
}
