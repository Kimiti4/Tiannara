'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function PortfolioViewRoom() {
  const [analytics, setAnalytics] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.mission.analytics().then((data) => { setAnalytics(data as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading portfolio view...</div>

  const items = [
    { label: 'Completion Rate', value: `${(Number(analytics.completion_rate ?? 0) * 100).toFixed(0)}%`, color: 'text-green-400' },
    { label: 'Active Rate', value: `${(Number(analytics.active_rate ?? 0) * 100).toFixed(0)}%`, color: 'text-amber-400' },
    { label: 'Campaign Success', value: `${(Number(analytics.campaign_success_rate ?? 0) * 100).toFixed(0)}%`, color: 'text-cyan-400' },
    { label: 'Mission Readiness', value: `${(Number(analytics.mission_readiness ?? 0) * 100).toFixed(0)}%`, color: 'text-blue-400' },
    { label: 'Avg Discovery Time', value: `${String(analytics.avg_discovery_time ?? '—')}d`, color: 'text-purple-400' },
  ]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-pink-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Portfolio View</span><span className="text-[var(--color-slate-muted)]">scientific investment dashboard</span></div>
      <div className="grid grid-cols-3 gap-3">
        {items.map((i) => (
          <div key={i.label} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">{i.label}</h4>
            <p className={`${i.color} text-sm font-mono`}>{i.value}</p>
          </div>
        ))}
      </div>
    </div>
  )
}
