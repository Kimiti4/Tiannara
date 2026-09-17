'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface ReadinessEntry {
  dimension: string
  score: number
  status: string
  requirements: string[]
  gaps: string[]
  assessed_at: string
}

export function PreparednessDashboardRoom() {
  const [readiness, setReadiness] = useState<Record<string, ReadinessEntry>>({})
  const [capacity, setCapacity] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.cpo.preparedness().catch(() => ({ readiness: {} })),
      api.cpo.capacity().catch(() => ({})),
    ]).then(([r, c]) => {
      const report = (r as { readiness: Record<string, ReadinessEntry> }).readiness || {}
      setReadiness(report)
      setCapacity(c as Record<string, unknown>)
      setLoading(false)
    })
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading preparedness data...</div>
  }

  const entries: ReadinessEntry[] = Object.values(readiness) || []

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-emerald-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Preparedness Dashboard</span>
        <span className="text-[var(--color-slate-muted)]">constitutional readiness at a glance</span>
      </div>

      {entries.length === 0 ? (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <p className="text-[var(--color-slate-muted)] italic text-[10px]">No readiness data available.</p>
        </div>
      ) : (
        entries.map((e) => (
          <div key={e.dimension} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className={`inline-block h-2 w-2 rounded-full ${
                  e.status === 'ready' ? 'bg-green-500' :
                  e.status === 'progressing' ? 'bg-amber-500' :
                  e.status === 'developing' ? 'bg-blue-500' : 'bg-slate-500'
                }`} />
                <span className="text-[var(--color-cyan-bright)] text-xs font-mono">{e.dimension}</span>
              </div>
              <span className={`text-[10px] font-mono ${
                e.status === 'ready' ? 'text-green-400' :
                e.status === 'progressing' ? 'text-amber-400' :
                e.status === 'developing' ? 'text-blue-400' : 'text-slate-400'
              }`}>{e.status}</span>
            </div>

            <div className="flex items-center gap-2">
              <div className="flex-1 h-2 rounded-full bg-[var(--color-slate-surface)] overflow-hidden">
                <div className="h-full rounded-full transition-all" style={{
                  width: `${(e.score * 100).toFixed(0)}%`,
                  backgroundColor: e.score >= 0.8 ? '#22c55e' : e.score >= 0.5 ? '#f59e0b' : e.score >= 0.2 ? '#3b82f6' : '#64748b'
                }} />
              </div>
              <span className="font-mono text-[var(--color-slate-secondary)] w-10 text-right">{(e.score * 100).toFixed(0)}%</span>
            </div>

            {e.requirements && e.requirements.length > 0 && (
              <div className="text-[10px]">
                <span className="text-[var(--color-slate-muted)]">Requirements: </span>
                {e.requirements.map((r, i) => (
                  <span key={r} className="text-[var(--color-slate-secondary)]">
                    {r}{i < e.requirements.length - 1 ? ', ' : ''}
                  </span>
                ))}
              </div>
            )}

            {e.gaps && e.gaps.length > 0 && (
              <div className="text-[10px]">
                <span className="text-red-400">Gaps: </span>
                {e.gaps.map((g, i) => (
                  <span key={g} className="text-red-300">
                    {g}{i < e.gaps.length - 1 ? ', ' : ''}
                  </span>
                ))}
              </div>
            )}
          </div>
        ))
      )}
    </div>
  )
}
