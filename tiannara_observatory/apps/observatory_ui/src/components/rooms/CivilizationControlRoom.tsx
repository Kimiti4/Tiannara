'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CivilizationControlRoom() {
  const [state, setState] = useState<Record<string, unknown>>({})
  const [economy, setEconomy] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.civilization.state().catch(() => ({})),
      api.civilization.economy().catch(() => ({})),
    ]).then(([s, e]) => { setState(s as Record<string, unknown>); setEconomy(e as Record<string, unknown>); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading civilization control...</div>

  const dims = ['scientific_capability', 'engineering_capability', 'infrastructure', 'education', 'innovation', 'energy', 'governance', 'resilience']

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-sky-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Civilization Control Center</span><span className="text-[var(--color-slate-muted)]">global civilization state</span></div>
      <div className="grid grid-cols-4 gap-2">
        {dims.map((d) => (<div key={d} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2 space-y-1">
          <h4 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] uppercase">{d.replace(/_/g, ' ')}</h4>
          <p className={`font-mono text-sm ${Number(state[d] || 0) >= 0.6 ? 'text-green-400' : Number(state[d] || 0) >= 0.4 ? 'text-amber-400' : 'text-red-400'}`}>{(Number(state[d] || 0) * 100).toFixed(0)}%</p>
        </div>))}
      </div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Knowledge Economy</h4>
        <div className="grid grid-cols-3 gap-3">
          <div><span className="text-[var(--color-slate-muted)]">Production</span><p className="font-mono text-[var(--color-cyan-bright)]">{(Number(economy.knowledge_production ?? 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Transfer</span><p className="font-mono text-[var(--color-cyan-bright)]">{(Number(economy.knowledge_transfer ?? 0) * 100).toFixed(0)}%</p></div>
          <div><span className="text-[var(--color-slate-muted)]">Innovation Velocity</span><p className="font-mono text-[var(--color-cyan-bright)]">{(Number(economy.innovation_velocity ?? 0) * 100).toFixed(0)}%</p></div>
        </div>
      </div>
    </div>
  )
}
