'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ResilienceCenterRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.civilization.resilience().then((d) => { setData(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading resilience center...</div>

  const threats = (data.threats || []) as Record<string, unknown>[]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-rose-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Resilience Center</span><span className="text-[var(--color-slate-muted)]">vulnerabilities · recovery · adaptation</span></div>
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Resilience</h4><p className="text-green-400 text-sm font-mono">{(Number(data.resilience_score ?? 0) * 100).toFixed(0)}%</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Recovery</h4><p className="text-amber-400 text-sm font-mono">{(Number(data.recovery_capacity ?? 0) * 100).toFixed(0)}%</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Adaptive</h4><p className="text-cyan-400 text-sm font-mono">{(Number(data.adaptive_capacity ?? 0) * 100).toFixed(0)}%</p>
        </div>
      </div>
      <div className="space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Threat Assessment</h4>
        {threats.sort((a, b) => Number(b.risk_score || 0) - Number(a.risk_score || 0)).map((t) => (<div key={String(t.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(t.name)}</span><span className="text-[10px] text-red-400 font-mono">{(Number(t.risk_score || 0) * 100).toFixed(0)}%</span></div>
          <div className="grid grid-cols-3 gap-2 text-[10px]">
            <div><span className="text-[var(--color-slate-muted)]">Likelihood</span><p className="font-mono">{(Number(t.likelihood || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Impact</span><p className="font-mono">{(Number(t.impact || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Preparedness</span><p className="font-mono text-green-400">{(Number(t.preparedness || 0) * 100).toFixed(0)}%</p></div>
          </div>
        </div>))}
      </div>
    </div>
  )
}
