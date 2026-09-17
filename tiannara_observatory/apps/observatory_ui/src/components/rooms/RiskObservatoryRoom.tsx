'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface RiskProjection {
  risk_type: string
  probability: number
  impact: number
  severity: number
  time_horizon: string
  mitigation: string
  projected_at: string
}

export function RiskObservatoryRoom() {
  const [projections, setProjections] = useState<RiskProjection[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.cpo.riskProjections().then((data) => {
      const p = ((data as unknown) as { risk_projections: RiskProjection[] }).risk_projections || []
      setProjections(p.sort((a, b) => b.severity - a.severity))
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading risk projections...</div>
  }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-red-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Risk Observatory</span>
        <span className="text-[var(--color-slate-muted)]">forecast constitutional failures before they materialize</span>
      </div>

      {projections.length === 0 ? (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <p className="text-[var(--color-slate-muted)] italic text-[10px]">No risk projections yet.</p>
        </div>
      ) : (
        projections.map((p) => (
          <div key={p.risk_type} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className={`text-[10px] px-1.5 py-0.5 rounded font-mono ${
                  p.severity >= 7 ? 'bg-red-900/40 text-red-300' :
                  p.severity >= 4 ? 'bg-amber-900/40 text-amber-300' :
                  'bg-slate-800 text-slate-300'
                }`}>S{p.severity}/10</span>
                <span className="text-[var(--color-cyan-bright)] text-xs font-mono">{p.risk_type}</span>
              </div>
              <span className="text-[var(--color-slate-muted)] text-[10px]">{p.time_horizon}</span>
            </div>

            <div className="grid grid-cols-2 gap-2 text-[10px]">
              <div>
                <span className="text-[var(--color-slate-muted)]">Probability </span>
                <span className="text-[var(--color-slate-secondary)] font-mono">{(p.probability * 100).toFixed(0)}%</span>
              </div>
              <div>
                <span className="text-[var(--color-slate-muted)]">Impact </span>
                <span className="text-[var(--color-slate-secondary)] font-mono">{(p.impact * 100).toFixed(0)}%</span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <div className="flex-1 h-2 rounded-full bg-[var(--color-slate-surface)] overflow-hidden">
                <div className="h-full rounded-full transition-all" style={{
                  width: `${p.severity * 10}%`,
                  backgroundColor: p.severity >= 7 ? '#ef4444' : p.severity >= 4 ? '#f59e0b' : '#3b82f6'
                }} />
              </div>
            </div>

            <p className="text-[var(--color-slate-muted)] text-[10px]">{p.mitigation}</p>
          </div>
        ))
      )}
    </div>
  )
}
