'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function StrategyCenterRoom() {
  const [plans, setPlans] = useState<Record<string, unknown>>({})
  const [risks, setRisks] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.strategy.plans().catch(() => ({})),
      api.strategy.risks().catch(() => ({ risks: [], summary: {} })),
    ]).then(([p, r]) => { setPlans(p as Record<string, unknown>); setRisks(r as Record<string, unknown>); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading strategy center...</div>

  const plansObj = plans as Record<string, Record<string, unknown>>
  const riskSummary = (risks.summary || {}) as Record<string, unknown>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-fuchsia-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Strategy Center</span><span className="text-[var(--color-slate-muted)]">long-term roadmap · strategic priorities</span></div>
      <div className="grid grid-cols-5 gap-2">
        {['d30', 'm6', 'y2', 'y10', 'y50'].map((h) => {
          const plan = plansObj[h] || {}
          return (<div key={h} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2 space-y-1">
            <h4 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] uppercase">{h.replace('d', '30d ').replace('m', '6m ').replace('y', '')}{h.startsWith('y') ? 'yr' : ''}</h4>
            {(plan.domains as Record<string, number>) && Object.entries(plan.domains as Record<string, number> || {}).map(([d, v]) => (
              <div key={d} className="flex justify-between text-[10px]"><span className="text-[var(--color-slate-muted)]">{d}</span><span className="font-mono text-[var(--color-cyan-bright)]">{(v * 100).toFixed(0)}%</span></div>
            ))}
          </div>)
        })}
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Strategic Risk Summary</h4>
        <div className="grid grid-cols-3 gap-3">
          <div><span className="text-[var(--color-slate-muted)]">Total Risks</span><p className="font-mono text-amber-400">{String(riskSummary.total_risks ?? '—')}</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Mean Risk Score</span><p className="font-mono text-amber-400">{(Number(riskSummary.mean_risk_score ?? 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Critical</span><p className="font-mono text-red-400">{String(riskSummary.critical_risks ?? '—')}</p></div>
        </div>
      </div>
    </div>
  )
}
