'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function PlanetaryTwinRoom() {
  const [infra, setInfra] = useState<Record<string, unknown>>({})
  const [society, setSociety] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.civilization.infrastructure().catch(() => ({ sectors: {} })),
      api.civilization.society().catch(() => ({})),
    ]).then(([i, s]) => { setInfra(i as Record<string, unknown>); setSociety(s as Record<string, unknown>); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading planetary twin...</div>

  const sectors = (infra.sectors || {}) as Record<string, Record<string, unknown>>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-green-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Planetary Twin</span><span className="text-[var(--color-slate-muted)]">infrastructure · economy · education</span></div>
      <div className="grid grid-cols-2 gap-3">
        {Object.entries(sectors).map(([id, s]) => {
          const bottlenecks = s.bottlenecks as string[] | undefined
          return (<div key={id} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(s.name || id)}</span><span className={`text-[10px] font-mono ${Number(s.maturity || 0) >= 0.65 ? 'text-green-400' : 'text-amber-400'}`}>{(Number(s.maturity || 0) * 100).toFixed(0)}%</span></div>
          <div className="text-[10px] text-[var(--color-slate-muted)]">capacity: {String(s.capacity)} · growth: {(Number(s.growth_rate || 0) * 100).toFixed(0)}%/yr</div>
          {bottlenecks && Array.isArray(bottlenecks) && <div className="flex gap-1 flex-wrap"><span className="text-[9px] text-red-400">bottlenecks:</span> {bottlenecks.map((b) => <span key={b} className="text-[9px] bg-red-900/30 px-1 rounded text-red-300">{b}</span>)}</div>}
        </div>)
        })}
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Societal Indicators</h4>
        <div className="grid grid-cols-4 gap-2 text-[10px]">
          <div><span className="text-[var(--color-slate-muted)]">Population</span><p className="font-mono text-[var(--color-cyan-bright)]">{String(society.population ?? '—')}</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Literacy</span><p className="font-mono">{(Number(society.literacy_rate ?? 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Urbanization</span><p className="font-mono">{(Number(society.urbanization ?? 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Life Exp.</span><p className="font-mono">{String(society.life_expectancy ?? '—')}</p></div>
        </div>
      </div>
    </div>
  )
}
