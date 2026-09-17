'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function EvolutionCenterRoom() {
  const [proposals, setProposals] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.meta.architecture().catch(() => ({ proposals: [] })),
      api.meta.certification().catch(() => ({ scores: {} })),
    ]).then(([a, c]) => { setProposals([...(a as { proposals: Record<string, unknown>[] }).proposals || []]); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading evolution center...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-emerald-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Evolution Center</span><span className="text-[var(--color-slate-muted)]">proposed changes → validation → certification → deployment</span></div>
      <div className="space-y-2">
        {proposals.map((p) => (<div key={String(p.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(p.name)}</span><span className={`text-[10px] px-1.5 rounded font-mono ${String(p.status) === 'deployed' ? 'bg-green-900/40 text-green-300' : String(p.status) === 'validating' ? 'bg-blue-900/40 text-blue-300' : String(p.status) === 'simulating' ? 'bg-amber-900/40 text-amber-300' : 'bg-slate-800/40 text-slate-300'}`}>{String(p.status)}</span></div>
          <p className="text-[var(--color-slate-muted)] text-[10px]">{String(p.description)}</p>
          {p.impact != null && <div className="grid grid-cols-2 gap-2 text-[10px]">
            <div><span className="text-[var(--color-slate-muted)]">Impact</span><p className="font-mono text-green-400">{(Number(p.impact || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Risk</span><p className="font-mono text-amber-400">{(Number(p.risk || 0) * 100).toFixed(0)}%</p></div>
          </div>}
        </div>))}
      </div>
    </div>
  )
}
