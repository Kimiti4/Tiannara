'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ExistentialRiskCenterRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.futures.existentialRisks().then((d) => { setData(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading existential risk center...</div>

  const risks = (data.risks || []) as Record<string, unknown>[]
  const summary = (data.summary || {}) as Record<string, unknown>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-red-600" /><span className="text-[var(--color-cyan-bright)] font-medium">Existential Risk Center</span><span className="text-[var(--color-slate-muted)]">existential · collapse · catastrophic</span></div>
      <div className="grid grid-cols-4 gap-2">
        <div className="rounded-md border border-red-900/40 bg-red-950/20 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-red-400 uppercase">Existential Risk</h4><p className="text-red-300 text-sm font-mono">{(Number(summary.existential_risk || 0) * 100).toFixed(1)}%</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Total Risks</h4><p className="font-mono text-[var(--color-cyan-bright)]">{String(summary.total_risks ?? '—')}</p>
        </div>
        <div className="rounded-md border border-amber-900/40 bg-amber-950/20 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-amber-400 uppercase">Existential</h4><p className="font-mono text-amber-300">{String(summary.existential_count ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">No Recovery</h4><p className="font-mono text-red-400">{String(summary.no_recovery_count ?? '—')}</p>
        </div>
      </div>
      <div className="space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Risk Rankings</h4>
        {risks.sort((a, b) => Number(b.risk_score || 0) - Number(a.risk_score || 0)).map((r) => (<div key={String(r.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(r.name)}</span><span className={`text-[10px] px-1.5 rounded font-mono ${Number(r.risk_score || 0) >= 0.15 ? 'bg-red-900/40 text-red-300' : 'bg-amber-900/40 text-amber-300'}`}>{(Number(r.risk_score || 0) * 100).toFixed(1)}%</span></div>
          <div className="grid grid-cols-4 gap-2 text-[10px]">
            <div><span className="text-[var(--color-slate-muted)]">Likelihood</span><p className="font-mono">{(Number(r.likelihood || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Impact</span><p className="font-mono">{(Number(r.impact || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Horizon</span><p className="font-mono">{String(r.time_horizon_years)}yr</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Recovery</span><p className="font-mono">{r.recovery_possible ? '✓' : '✗'}</p></div>
          </div>
        </div>))}
      </div>
    </div>
  )
}
