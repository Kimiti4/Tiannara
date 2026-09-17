'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function DiscoveryChallengeCenterRoom() {
  const [scheduler, setScheduler] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.mission.scheduler().then((data) => { setScheduler(data as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading discovery challenge center...</div>

  const running = (scheduler.running as string[]) || []

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-yellow-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Discovery Challenge Center</span><span className="text-[var(--color-slate-muted)]">challenge coordination hub</span></div>
      <div className="grid grid-cols-3 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Queue</h4><p className="text-[var(--color-cyan-bright)] text-sm font-mono">{String(scheduler.queue_size ?? '—')}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Running</h4><p className="text-amber-400 text-sm font-mono">{running.length}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Scheduled</h4><p className="text-green-400 text-sm font-mono">{String(scheduler.total_scheduled ?? '—')}</p>
        </div>
      </div>
      {running.length > 0 && <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Running Missions</h4>
        {running.map((id) => <p key={id} className="text-[11px] font-mono text-[var(--color-slate-secondary)]">{id}</p>)}
      </div>}
    </div>
  )
}
