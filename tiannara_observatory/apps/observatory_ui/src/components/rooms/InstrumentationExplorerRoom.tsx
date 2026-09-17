'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function InstrumentationExplorerRoom() {
  const [proposals, setProposals] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.meta.instrumentation().then((d) => { setProposals((d as { proposals: Record<string, unknown>[] }).proposals || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading instrumentation explorer...</div>

  const statusColors: Record<string, string> = { proposed: 'text-amber-400', simulating: 'text-blue-400', validating: 'text-purple-400', deployed: 'text-green-400' }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-violet-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Instrumentation Explorer</span><span className="text-[var(--color-slate-muted)]">proposed new telemetry · metrics · dashboards</span></div>
      <div className="grid grid-cols-2 gap-3">
        {proposals.map((p) => (<div key={String(p.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(p.name)}</span><span className={`text-[10px] font-mono ${statusColors[String(p.status)] || ''}`}>{String(p.status)}</span></div>
          <p className="text-[var(--color-slate-muted)] text-[10px]">{String(p.description)}</p>
          <span className="text-[9px] text-[var(--color-slate-muted)]">type: {String(p.type)}</span>
        </div>))}
      </div>
    </div>
  )
}
