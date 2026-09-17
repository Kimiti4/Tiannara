'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ActiveMissionsRoom() {
  const [missions, setMissions] = useState<Record<string, unknown>[]>([])
  const [analytics, setAnalytics] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.mission.list().catch(() => ({ missions: [] })),
      api.mission.analytics().catch(() => ({})),
    ]).then(([m, a]) => {
      setMissions(((m as { missions: Record<string, unknown>[] }).missions || []))
      setAnalytics(a as Record<string, unknown>)
      setLoading(false)
    })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading missions...</div>

  const byStatus = analytics as Record<string, unknown>
  const groups: Record<string, Record<string, unknown>[]> = {}
  missions.forEach((m) => { const s = String(m.status || 'unknown'); if (!groups[s]) groups[s] = []; groups[s].push(m) })

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-green-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Active Missions</span></div>
      <div className="grid grid-cols-4 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Total</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{missions.length}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Completed</h4>
          <p className="text-green-400 text-sm font-mono">{String(byStatus.completion_rate ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Active</h4>
          <p className="text-amber-400 text-sm font-mono">{String(byStatus.active_rate ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Pending</h4>
          <p className="text-slate-400 text-sm font-mono">{String(byStatus.pending_rate ?? '—')}</p>
        </div>
      </div>
      {Object.entries(groups).map(([status, ms]) => (
        <div key={status} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">{status} ({ms.length})</h4>
          {ms.map((m) => (
            <div key={String(m.id)} className="flex justify-between text-[11px] border-b border-[var(--color-slate-border)] last:border-0 pb-1 mb-1 last:pb-0 last:mb-0">
              <span className="text-[var(--color-cyan-bright)]">{String(m.name || m.id)}</span>
              <span className="text-[var(--color-slate-muted)]">P{String(m.priority ?? '—')}</span>
            </div>
          ))}
        </div>
      ))}
    </div>
  )
}
