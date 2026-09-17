'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface Recommendation {
  id: string
  source: string
  category: string
  text: string
  metadata: Record<string, unknown>
  generated_at: string
  acknowledged: boolean
  priority: number
}

export function ConstitutionalAdvisorRoom() {
  const [recommendations, setRecommendations] = useState<Recommendation[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.cil.recommendations().then((data) => {
      setRecommendations(((data as unknown) as { recommendations: Recommendation[] }).recommendations || [])
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading recommendations...</div>
  }

  const activeRecs = recommendations.filter((r) => !r.acknowledged)
  const acknowledgedRecs = recommendations.filter((r) => r.acknowledged)

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-amber-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Constitutional Advisor</span>
        <span className="text-[var(--color-slate-muted)]">decision support · advisory only</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Active</h4>
          <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{activeRecs.length}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Acknowledged</h4>
          <p className="text-[var(--color-slate-secondary)] text-sm font-mono">{acknowledgedRecs.length}</p>
        </div>
      </div>

      {activeRecs.length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Active Recommendations</h4>
          {activeRecs.sort((a, b) => b.priority - a.priority).map((r) => (
            <div key={r.id} className="border-b border-[var(--color-slate-border)] last:border-0 pb-1.5 mb-1.5 last:pb-0 last:mb-0">
              <div className="flex items-center gap-2">
                <span className={`text-[10px] px-1.5 py-0.5 rounded font-mono ${
                  r.priority >= 80 ? 'bg-red-900/40 text-red-300' :
                  r.priority >= 60 ? 'bg-amber-900/40 text-amber-300' :
                  'bg-slate-800 text-slate-300'
                }`}>P{r.priority}</span>
                <span className="text-[var(--color-slate-muted)] text-[10px]">{r.source}/{r.category}</span>
              </div>
              <p className="text-[var(--color-slate-secondary)] text-xs mt-0.5">{r.text}</p>
              <p className="text-[var(--color-slate-muted)] text-[9px] mt-0.5">
                {r.generated_at ? new Date(r.generated_at).toLocaleString() : '—'}
              </p>
            </div>
          ))}
        </div>
      )}

      {activeRecs.length === 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Active Recommendations</h4>
          <p className="text-[var(--color-slate-muted)] italic text-[10px] mt-1">No active recommendations. The system is operating within expected parameters.</p>
        </div>
      )}

      {acknowledgedRecs.length > 0 && (
        <details className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <summary className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase cursor-pointer">
            Acknowledged ({acknowledgedRecs.length})
          </summary>
          <div className="mt-1.5 space-y-1.5">
            {acknowledgedRecs.map((r) => (
              <div key={r.id} className="opacity-50">
                <p className="text-[var(--color-slate-secondary)] text-xs">{r.text}</p>
                <p className="text-[var(--color-slate-muted)] text-[9px]">{r.source}/{r.category}</p>
              </div>
            ))}
          </div>
        </details>
      )}
    </div>
  )
}
