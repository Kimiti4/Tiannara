'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ScientificCampaignRoom() {
  const [missions, setMissions] = useState<Record<string, unknown>[]>([])
  const [timeline, setTimeline] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.mission.list().catch(() => ({ missions: [] })),
      api.mission.timeline().catch(() => ({ timeline: [] })),
    ]).then(([m, t]) => {
      setMissions(((m as { missions: Record<string, unknown>[] }).missions || []))
      setTimeline(((t as { timeline: Record<string, unknown>[] }).timeline || []))
      setLoading(false)
    })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading campaigns...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-teal-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Scientific Campaign View</span></div>
      {missions.map((m) => {
        const domains = m.domains as string[] | undefined
        return (<div key={String(m.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(m.name || m.id)}</span><span className="text-[var(--color-slate-muted)]">{String(m.status)}</span></div>
          <p className="text-[var(--color-slate-muted)] text-[10px]">{String(m.description || '')}</p>
          {domains && Array.isArray(domains) && <div className="flex gap-1 flex-wrap"><span className="text-[var(--color-slate-muted)] text-[9px]">domains:</span> {domains.map((d) => <span key={d} className="text-[9px] bg-[var(--color-slate-surface)] px-1 rounded text-[var(--color-slate-secondary)]">{d}</span>)}</div>}
        </div>)
      })}
    </div>
  )
}
