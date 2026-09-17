'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface HorizonData {
  horizon: string
  sample_count: number
  current: number | null
  mean: number | null
  min: number | null
  max: number | null
  slope: number | null
  direction: string
}

interface MetricTrend {
  metric: string
  data_points: number
  horizons: HorizonData[]
}

export function TrendObservatoryRoom() {
  const [trends, setTrends] = useState<Record<string, MetricTrend>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.cil.trends().then((data) => {
      setTrends(data as Record<string, MetricTrend>)
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading trend data...</div>
  }

  const trendEntries = Object.entries(trends)

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-emerald-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Trend Observatory</span>
        <span className="text-[var(--color-slate-muted)]">long-term constitutional trajectories</span>
      </div>

      {trendEntries.length === 0 ? (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <p className="text-[var(--color-slate-muted)] italic text-[10px]">No trend data yet. Trend data accumulates as events are observed.</p>
        </div>
      ) : (
        trendEntries.map(([name, trend]) => (
          <div key={name} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
            <div className="flex items-center justify-between">
              <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase font-mono">{name}</h4>
              <span className="text-[var(--color-slate-muted)] text-[10px]">{trend.data_points} data points</span>
            </div>

            {trend.horizons.map((h) => (
              <div key={h.horizon} className="border-b border-[var(--color-slate-border)] last:border-0 pb-1.5 mb-1.5 last:pb-0 last:mb-0">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-[var(--color-slate-muted)] text-[10px]">{h.horizon}</span>
                  <span className={`text-[10px] font-mono ${
                    h.direction === 'increasing' ? 'text-green-400' :
                    h.direction === 'decreasing' ? 'text-red-400' : 'text-slate-400'
                  }`}>
                    {h.direction === 'increasing' ? '↑' : h.direction === 'decreasing' ? '↓' : '→'} {h.direction}
                  </span>
                </div>
                <div className="grid grid-cols-4 gap-2 text-[10px] font-mono">
                  <div><span className="text-[var(--color-slate-muted)]">current </span><span className="text-[var(--color-slate-secondary)]">{h.current?.toFixed(2) ?? '—'}</span></div>
                  <div><span className="text-[var(--color-slate-muted)]">mean </span><span className="text-[var(--color-slate-secondary)]">{h.mean?.toFixed(2) ?? '—'}</span></div>
                  <div><span className="text-[var(--color-slate-muted)]">min </span><span className="text-[var(--color-slate-secondary)]">{h.min?.toFixed(2) ?? '—'}</span></div>
                  <div><span className="text-[var(--color-slate-muted)]">max </span><span className="text-[var(--color-slate-secondary)]">{h.max?.toFixed(2) ?? '—'}</span></div>
                </div>
                {h.slope !== null && (
                  <div className="text-[10px] text-[var(--color-slate-muted)] mt-0.5">
                    slope: {h.slope.toFixed(4)} · samples: {h.sample_count}
                  </div>
                )}
              </div>
            ))}
          </div>
        ))
      )}
    </div>
  )
}
