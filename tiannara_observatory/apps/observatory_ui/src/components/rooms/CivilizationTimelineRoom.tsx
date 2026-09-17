'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CivilizationTimelineRoom() {
  const [diffusion, setDiffusion] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.civilization.diffusion().then((data) => { setDiffusion((data as { technologies: Record<string, unknown> }).technologies || {}); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading civilization timeline...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-amber-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Civilization Timeline</span><span className="text-[var(--color-slate-muted)]">technology diffusion across centuries</span></div>
      {Object.entries(diffusion).sort(([, a], [, b]) => Number((a as Record<string, unknown>).year_discovered || 0) - Number((b as Record<string, unknown>).year_discovered || 0)).map(([id, t]) => {
        const tech = t as Record<string, unknown>
        const yEng = tech.years_to_engineering as number | undefined
        const yMfg = tech.years_to_manufacturing as number | undefined
        const adoptionRate = tech.adoption_rate as number | undefined
        const stageColors: Record<string, string> = { discovery: 'bg-red-900/40 text-red-300', engineering: 'bg-amber-900/40 text-amber-300', manufacturing: 'bg-blue-900/40 text-blue-300', adoption: 'bg-green-900/40 text-green-300', global_diffusion: 'bg-purple-900/40 text-purple-300' }
        return (<div key={id} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(tech.name || id)}</span><span className={`text-[9px] px-1.5 rounded font-mono ${stageColors[String(tech.stage)] || ''}`}>{String(tech.stage).replace(/_/g, ' ')}</span></div>
          <div className="flex gap-3 text-[10px] text-[var(--color-slate-muted)]">
            <span>discovered: {String(tech.year_discovered)}</span>
            {yEng != null && <span>→ engineering: {String(yEng)}yr</span>}
            {yMfg != null && <span>→ manufacturing: {String(yMfg)}yr</span>}
          </div>
          {adoptionRate != null && <div className="w-full h-1.5 bg-[var(--color-slate-surface)] rounded-full overflow-hidden"><div className="h-full rounded-full bg-[var(--color-cyan-bright)]" style={{ width: `${(adoptionRate * 100).toFixed(0)}%` }} /></div>}
        </div>)
      })}
    </div>
  )
}
