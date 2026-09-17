'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function MetaObservatoryRoom() {
  const [status, setStatus] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.meta.status().catch(() => ({})),
      api.meta.blindSpots().catch(() => ({ blind_spots: [] })),
    ]).then(([s, b]) => { setStatus({ ...(s as Record<string, unknown>), ...(b as Record<string, unknown>) }); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading meta-observatory...</div>

  const metrics = [
    { label: 'Observability Coverage', value: status.observability_coverage },
    { label: 'Instrumentation', value: status.instrumentation_completeness },
    { label: 'Metric Quality', value: status.metric_quality },
    { label: 'Visualization Quality', value: status.visualization_quality },
    { label: 'Governance Stability', value: status.governance_stability },
    { label: 'Self-Improvement Yield', value: status.self_improvement_yield },
    { label: 'Observatory Fitness', value: status.observatory_fitness },
  ]
  const blindSpots = (status.blind_spots || []) as string[]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-sky-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Meta-Observatory</span><span className="text-[var(--color-slate-muted)]">watching the watcher</span></div>
      <div className="grid grid-cols-4 gap-2">
        {metrics.map((m) => (<div key={m.label} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2 space-y-1">
          <h4 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] uppercase">{m.label}</h4>
          <p className={`font-mono text-sm ${Number(m.value || 0) >= 0.7 ? 'text-green-400' : Number(m.value || 0) >= 0.5 ? 'text-amber-400' : 'text-red-400'}`}>{(Number(m.value || 0) * 100).toFixed(0)}%</p>
        </div>))}
      </div>
      {blindSpots.length > 0 && <div className="rounded-md border border-amber-900/40 bg-amber-950/20 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-amber-400 uppercase">Blind Spots</h4>
        {blindSpots.map((bs) => <p key={bs} className="text-[11px] font-mono text-amber-300">{bs}</p>)}
      </div>}
    </div>
  )
}
