'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface CausalData {
  event_id?: string
  ancestors?: string[]
  descendants?: string[]
}

interface RiskEntry {
  domain: string
  severity: number
  probability: number
  impact: number
  risk_score: number
  risk_level: string
}

export function CausalExplorerRoom() {
  const [eventId, setEventId] = useState('')
  const [causal, setCausal] = useState<CausalData>({})
  const [risk, setRisk] = useState<RiskEntry[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.cil.risk().then((data) => {
      const entries = Object.values(data) as RiskEntry[]
      setRisk(entries.sort((a, b) => b.risk_score - a.risk_score))
    }).catch(() => {})
    setLoading(false)
  }, [])

  const handleSearch = async () => {
    if (!eventId.trim()) return
    try {
      const data = await api.cil.causal(eventId.trim())
      setCausal(data as CausalData)
    } catch {
      setCausal({ event_id: eventId, ancestors: [], descendants: [] })
    }
  }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-purple-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Causal Explorer</span>
        <span className="text-[var(--color-slate-muted)]">trace root causes interactively</span>
      </div>

      <div className="flex gap-2">
        <input
          type="text"
          value={eventId}
          onChange={(e) => setEventId(e.target.value)}
          placeholder="Enter event ID to trace..."
          className="flex-1 rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/60 px-2.5 py-1.5 text-xs text-[var(--color-slate-secondary)] placeholder-[var(--color-slate-muted)] outline-none focus:border-[var(--color-cyan-bright)]"
          onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
        />
        <button
          onClick={handleSearch}
          className="rounded-md bg-[var(--color-cyan-bright)]/10 border border-[var(--color-slate-border)] px-2.5 py-1.5 text-xs text-[var(--color-cyan-bright)] hover:bg-[var(--color-cyan-bright)]/20 transition-colors"
        >
          Trace
        </button>
      </div>

      {causal.event_id && (
        <div className="grid grid-cols-2 gap-3">
          <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Ancestors (Root Causes)</h4>
            {causal.ancestors && causal.ancestors.length > 0 ? (
              causal.ancestors.map((id, i) => (
                <div key={id} className="flex items-center gap-1.5 font-mono text-[10px]">
                  <span className="text-[var(--color-slate-muted)]">L{(causal.ancestors?.length ?? 0) - i}</span>
                  <span className="text-amber-400">◀</span>
                  <span className="text-[var(--color-slate-secondary)] truncate">{id}</span>
                </div>
              ))
            ) : (
              <p className="text-[var(--color-slate-muted)] italic text-[10px]">No ancestors found — this may be a root event.</p>
            )}
          </div>

          <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Descendants (Effects)</h4>
            {causal.descendants && causal.descendants.length > 0 ? (
              causal.descendants.map((id, i) => (
                <div key={id} className="flex items-center gap-1.5 font-mono text-[10px]">
                  <span className="text-[var(--color-slate-secondary)] truncate">{id}</span>
                  <span className="text-cyan-400">▶</span>
                  <span className="text-[var(--color-slate-muted)]">L{i + 1}</span>
                </div>
              ))
            ) : (
              <p className="text-[var(--color-slate-muted)] italic text-[10px]">No descendants found.</p>
            )}
          </div>
        </div>
      )}

      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Risk Matrix</h4>
        {risk.map((r) => (
          <div key={r.domain} className="flex items-center gap-2 text-[11px]">
            <span className="w-20 text-[var(--color-slate-muted)] truncate">{r.domain}</span>
            <div className="flex-1 h-2 rounded-full bg-[var(--color-slate-surface)] overflow-hidden">
              <div className="h-full rounded-full transition-all" style={{
                width: `${Math.min(r.risk_score / 25 * 100, 100)}%`,
                backgroundColor: r.risk_level === 'critical' ? '#ef4444' : r.risk_level === 'high' ? '#f59e0b' : r.risk_level === 'medium' ? '#3b82f6' : '#22c55e'
              }} />
            </div>
            <span className={`text-[10px] w-14 text-right font-mono ${
              r.risk_level === 'critical' ? 'text-red-400' :
              r.risk_level === 'high' ? 'text-amber-400' :
              r.risk_level === 'medium' ? 'text-blue-400' : 'text-green-400'
            }`}>{r.risk_level}</span>
            <span className="font-mono text-[var(--color-slate-secondary)] w-8 text-right">{r.risk_score.toFixed(1)}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
