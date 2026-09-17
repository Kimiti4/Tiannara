'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface ForecastHorizon {
  horizon: string
  predicted_value: number
  confidence: number
}

interface ForecastEntry {
  metric: string
  horizons: ForecastHorizon[]
  generated_at: string
}

export function ForecastCenterRoom() {
  const [forecasts, setForecasts] = useState<ForecastEntry[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.cpo.forecasts().then((data) => {
      const f = ((data as unknown) as { forecasts: ForecastEntry[] }).forecasts || []
      setForecasts(f)
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading forecasts...</div>
  }

  const horizons = ['1h', '24h', '7d', '30d', '1y']

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-sky-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Forecast Center</span>
        <span className="text-[var(--color-slate-muted)]">multi-horizon constitutional predictions</span>
      </div>

      {forecasts.length === 0 ? (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <p className="text-[var(--color-slate-muted)] italic text-[10px]">No forecasts available. Data accumulates as events are processed.</p>
        </div>
      ) : (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-2 overflow-x-auto">
          <table className="w-full text-[11px] font-mono">
            <thead>
              <tr className="text-[var(--color-slate-muted)] text-[10px] tracking-wider">
                <th className="text-left py-1 pr-3">Metric</th>
                {horizons.map((h) => (
                  <th key={h} className="text-right px-2 py-1">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {forecasts.map((f) => (
                <tr key={f.metric} className="border-t border-[var(--color-slate-border)]">
                  <td className="py-1.5 pr-3 text-[var(--color-slate-secondary)]">{f.metric}</td>
                  {horizons.map((h) => {
                    const hd = f.horizons?.find((fh) => fh.horizon === h)
                    return (
                      <td key={h} className="text-right px-2 py-1.5">
                        <span className="text-[var(--color-cyan-bright)]">{hd ? hd.predicted_value.toFixed(1) : '—'}</span>
                        {hd && (
                          <span className="text-[var(--color-slate-muted)] ml-1 text-[9px]">
                            ({(hd.confidence * 100).toFixed(0)}%)
                          </span>
                        )}
                      </td>
                    )
                  })}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
