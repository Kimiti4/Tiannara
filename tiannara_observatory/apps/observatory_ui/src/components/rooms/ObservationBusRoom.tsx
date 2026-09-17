'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface CobStats {
  status?: string
  uptime?: number
  subsystems?: Record<string, unknown>
  events_routed?: number
  queue_depth?: Record<string, number>
  total_subscribers?: number
  lineage_events?: number
}

export function ObservationBusRoom() {
  const [stats, setStats] = useState<CobStats>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.status()
      .then((data) => {
        setStats({
          status: data.status,
          uptime: data.uptime,
          subsystems: data.subsystems,
          events_routed: data.subsystems?.events_routed as number | undefined,
          queue_depth: data.subsystems?.queue_depth as Record<string, number> | undefined,
          total_subscribers: data.subsystems?.total_subscribers as number | undefined,
          lineage_events: data.subsystems?.lineage_events as number | undefined,
        })
        setLoading(false)
      })
      .catch(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading COB metrics...</div>
  }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className={`inline-block h-2 w-2 rounded-full ${stats.status === 'healthy' || stats.status === 'ok' ? 'bg-green-500' : 'bg-amber-500'}`} />
        <span className="text-[var(--color-cyan-bright)] font-medium">Constitutional Observation Bus</span>
        <span className="text-[var(--color-slate-muted)]">v1.0.0</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Throughput</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{stats.events_routed ?? '—'}</p>
          <p className="text-[var(--color-slate-muted)]">events routed</p>
        </div>

        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Subscribers</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{stats.total_subscribers ?? '—'}</p>
          <p className="text-[var(--color-slate-muted)]">active</p>
        </div>

        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Lineage</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{stats.lineage_events ?? '—'}</p>
          <p className="text-[var(--color-slate-muted)]">events tracked</p>
        </div>

        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Uptime</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{stats.uptime ? `${stats.uptime}s` : '—'}</p>
          <p className="text-[var(--color-slate-muted)]">since last restart</p>
        </div>
      </div>

      {stats.queue_depth && Object.keys(stats.queue_depth).length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Priority Queues</h4>
          {Object.entries(stats.queue_depth)
            .sort(([a], [b]) => Number(b) - Number(a))
            .map(([priority, depth]) => (
              <div key={priority} className="flex items-center gap-2">
                <span className="w-20 text-[var(--color-slate-muted)]">P-{priority}</span>
                <div className="flex-1 h-2 rounded-full bg-[var(--color-slate-surface)] overflow-hidden">
                  <div
                    className="h-full rounded-full bg-[var(--color-cyan-bright)] transition-all"
                    style={{ width: `${Math.min(Number(depth) / 100 * 100, 100)}%` }}
                  />
                </div>
                <span className="font-mono text-[var(--color-slate-secondary)] w-12 text-right">{String(depth)}</span>
              </div>
            ))}
        </div>
      )}

      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Subsystems</h4>
        {stats.subsystems ? (
          <div className="grid grid-cols-3 gap-1 text-[11px] font-mono text-[var(--color-slate-secondary)]">
            {Object.entries(stats.subsystems).map(([name, val]) => (
              <div key={name} className="truncate">
                <span className="text-[var(--color-slate-muted)]">{name}:</span> {String(val)}
              </div>
            ))}
          </div>
        ) : (
          <p className="text-[var(--color-slate-muted)] italic">No subsystem data available</p>
        )}
      </div>
    </div>
  )
}
