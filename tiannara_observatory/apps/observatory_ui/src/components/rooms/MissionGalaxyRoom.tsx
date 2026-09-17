'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function MissionGalaxyRoom() {
  const [portfolio, setPortfolio] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.mission.portfolio().then((data) => { setPortfolio(data as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading mission galaxy...</div>

  const byStatus = portfolio.by_status as Record<string, number> || {}
  const domains = portfolio.domain_distribution as Record<string, number> || {}

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-blue-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Mission Galaxy</span><span className="text-[var(--color-slate-muted)]">portfolio and domain distribution</span></div>
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Diversity</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{(Number(portfolio.diversity_score ?? 0) * 100).toFixed(0)}%</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Total</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{String(portfolio.total_missions ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Risk Exposure</h4>
          <p className="text-amber-400 text-sm font-mono">{(Number(portfolio.risk_exposure ?? 0) * 100).toFixed(0)}%</p>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">By Status</h4>
          {Object.entries(byStatus).map(([s, c]) => (
            <div key={s} className="flex justify-between text-[11px]"><span className="text-[var(--color-slate-muted)]">{s}</span><span className="font-mono text-[var(--color-cyan-bright)]">{c}</span></div>
          ))}
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">By Domain</h4>
          {Object.entries(domains).sort(([, a], [, b]) => Number(b) - Number(a)).map(([d, c]) => (
            <div key={d} className="flex justify-between text-[11px]"><span className="text-[var(--color-slate-muted)]">{d}</span><span className="font-mono text-[var(--color-cyan-bright)]">{c}</span></div>
          ))}
        </div>
      </div>
    </div>
  )
}
