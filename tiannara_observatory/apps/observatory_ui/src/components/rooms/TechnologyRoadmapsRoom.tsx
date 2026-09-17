'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function TechnologyRoadmapsRoom() {
  const [techs, setTechs] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.strategy.technologies().then((data) => { setTechs((data as { technologies: Record<string, unknown> }).technologies || {}); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading technology roadmaps...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-cyan-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Technology Roadmaps</span><span className="text-[var(--color-slate-muted)]">TRL · dependencies · timelines</span></div>
      {Object.entries(techs).sort(([, a], [, b]) => Number((b as Record<string, unknown>).trl || 0) - Number((a as Record<string, unknown>).trl || 0)).map(([id, t]) => {
        const tech = t as Record<string, unknown>
        const deps = tech.dependencies as string[] | undefined
        return (<div key={id} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <div className="flex justify-between items-center"><span className="text-[var(--color-cyan-bright)] font-mono text-sm">{String(tech.name || id)}</span><span className={`text-[10px] px-2 py-0.5 rounded font-mono ${Number(tech.trl || 0) >= 7 ? 'bg-green-900/40 text-green-300' : Number(tech.trl || 0) >= 4 ? 'bg-amber-900/40 text-amber-300' : 'bg-red-900/40 text-red-300'}`}>TRL {String(tech.trl)}</span></div>
          <div className="grid grid-cols-4 gap-2 text-[10px]">
            <div><span className="text-[var(--color-slate-muted)]">Risk</span><p className="font-mono text-amber-400">{(Number(tech.risk || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Benefit</span><p className="font-mono text-green-400">{(Number(tech.benefit || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Discovery</span><p className="font-mono text-[var(--color-cyan-bright)]">{String(tech.est_discovery_months)}mo</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Engineering</span><p className="font-mono text-[var(--color-cyan-bright)]">{String(tech.est_engineering_months)}mo</p></div>
          </div>
          {deps && Array.isArray(deps) && <div className="flex gap-1 flex-wrap"><span className="text-[var(--color-slate-muted)] text-[9px]">depends:</span> {deps.map((d) => <span key={d} className="text-[9px] bg-[var(--color-slate-surface)] px-1 rounded text-[var(--color-slate-secondary)]">{d}</span>)}</div>}
        </div>)
      })}
    </div>
  )
}
