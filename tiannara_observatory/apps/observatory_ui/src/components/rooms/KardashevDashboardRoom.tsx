'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function KardashevDashboardRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.civilization.kardashev().then((d) => { setData(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading Kardashev dashboard...</div>

  const status = (data.status || {}) as Record<string, unknown>
  const projection = (data.projection || {}) as Record<string, unknown>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-purple-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Kardashev Dashboard</span><span className="text-[var(--color-slate-muted)]">civilization capability tracking</span></div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-3 space-y-2">
        <div className="flex justify-between items-center"><span className="text-[var(--color-slate-muted)] text-[10px]">Current Level</span><span className="text-2xl font-mono text-[var(--color-cyan-bright)]">{Number(status.current_level || 0).toFixed(2)}</span></div>
        <div className="w-full h-2 bg-[var(--color-slate-surface)] rounded-full overflow-hidden">
          <div className="h-full rounded-full bg-gradient-to-r from-amber-500 via-green-500 to-purple-500" style={{ width: `${(Number(status.current_level || 0) / 2.0 * 100).toFixed(0)}%` }} />
        </div>
        <div className="flex justify-between text-[9px] text-[var(--color-slate-muted)]"><span>Type 0</span><span>Type I (1.0)</span><span>Type II (2.0)</span></div>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Energy</h4>
          <p className="font-mono text-sm text-[var(--color-cyan-bright)]">{String(status.energy_consumption_tw)} TW</p>
          <p className="text-[9px] text-[var(--color-slate-muted)]">of {String(status.planetary_capacity_tw)} TW capacity</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Growth Rate</h4>
          <p className="font-mono text-sm text-green-400">{(Number(status.growth_rate ?? 0) * 100).toFixed(1)}%/yr</p>
        </div>
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Projections</h4>
        <div className="grid grid-cols-3 gap-2">
          <div><span className="text-[var(--color-slate-muted)]">50yr</span><p className="font-mono text-amber-400">{Number(projection.p50 || 0).toFixed(2)}</p></div>
          <div><span className="text-[var(--color-slate-muted)]">100yr</span><p className="font-mono text-green-400">{Number(projection.p100 || 0).toFixed(2)}</p></div>
          <div><span className="text-[var(--color-slate-muted)]">500yr</span><p className="font-mono text-purple-400">{Number(projection.p500 || 0).toFixed(2)}</p></div>
        </div>
        <div className="text-[10px]"><span className="text-[var(--color-slate-muted)]">Type I ETA: </span><span className="font-mono text-[var(--color-cyan-bright)]">{String(projection.type_I_eta)}</span></div>
      </div>
    </div>
  )
}
