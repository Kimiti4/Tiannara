'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface HealthData {
  overall_health?: number
  timestamp?: string
  subsystems?: Record<string, { score: number; drift: string; instability: string; recovery_potential: string }>
  confidence?: number
  drift?: string
  instability?: string
  recovery_potential?: string
}

interface PatternItem {
  id: string
  type: string
  domain: string
  confidence: number
  occurrence_count: number
  last_seen: string
}

interface SynthesisItem {
  name: string
  description: string
  severity: string
  confidence: number
}

export function ConstitutionalIntelligenceRoom() {
  const [health, setHealth] = useState<HealthData>({})
  const [patterns, setPatterns] = useState<PatternItem[]>([])
  const [syntheses, setSyntheses] = useState<SynthesisItem[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.cil.health().catch(() => ({})),
      api.cil.patterns().catch(() => ({ patterns: [] })),
      api.cil.syntheses().catch(() => ({ syntheses: [] })),
    ]).then(([h, p, s]) => {
      setHealth(h as HealthData)
      setPatterns(((p as unknown) as { patterns: PatternItem[] }).patterns || [])
      setSyntheses(((s as unknown) as { syntheses: SynthesisItem[] }).syntheses || [])
      setLoading(false)
    })
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading constitutional intelligence...</div>
  }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className={`inline-block h-2 w-2 rounded-full ${health.overall_health && health.overall_health > 0.6 ? 'bg-green-500' : 'bg-amber-500'}`} />
        <span className="text-[var(--color-cyan-bright)] font-medium">Constitutional Intelligence</span>
        <span className="text-[var(--color-slate-muted)]">M10</span>
      </div>

      {health.overall_health !== undefined && (
        <div className="grid grid-cols-4 gap-3">
          <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1 col-span-2">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Overall Health</h4>
            <div className="flex items-center gap-2">
              <div className="flex-1 h-3 rounded-full bg-[var(--color-slate-surface)] overflow-hidden">
                <div className="h-full rounded-full bg-[var(--color-cyan-bright)] transition-all" style={{ width: `${(health.overall_health * 100).toFixed(0)}%` }} />
              </div>
              <span className="font-mono text-[var(--color-cyan-bright)]">{(health.overall_health * 100).toFixed(0)}%</span>
            </div>
          </div>

          <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Confidence</h4>
            <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{health.confidence ? `${(health.confidence * 100).toFixed(0)}%` : '—'}</p>
          </div>

          <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Stability</h4>
            <p className="text-[var(--color-cyan-bright)] text-sm font-mono">{health.instability ?? '—'}</p>
          </div>
        </div>
      )}

      {health.subsystems && Object.keys(health.subsystems).length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Subsystem Health</h4>
          {Object.entries(health.subsystems).map(([name, info]) => (
            <div key={name} className="flex items-center gap-2">
              <span className="w-24 text-[var(--color-slate-muted)] truncate">{name}</span>
              <div className="flex-1 h-2 rounded-full bg-[var(--color-slate-surface)] overflow-hidden">
                <div className="h-full rounded-full transition-all" style={{
                  width: `${(info.score / 100 * 100).toFixed(0)}%`,
                  backgroundColor: info.score > 70 ? 'var(--color-cyan-bright)' : info.score > 40 ? '#f59e0b' : '#ef4444'
                }} />
              </div>
              <span className="font-mono text-[var(--color-slate-secondary)] w-8 text-right">{info.score.toFixed(0)}</span>
              <span className={`text-[10px] w-16 text-right ${info.drift === 'high' ? 'text-red-400' : info.drift === 'moderate' ? 'text-amber-400' : 'text-green-400'}`}>
                {info.drift}
              </span>
            </div>
          ))}
        </div>
      )}

      {patterns.length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Patterns ({patterns.length})</h4>
          {patterns.slice(0, 8).map((p) => (
            <div key={p.id} className="flex items-center justify-between text-[11px]">
              <span className="text-[var(--color-slate-secondary)]">{p.type} <span className="text-[var(--color-slate-muted)]">({p.domain})</span></span>
              <span className="text-[var(--color-slate-muted)] font-mono">{(p.confidence * 100).toFixed(0)}% · {p.occurrence_count}x</span>
            </div>
          ))}
        </div>
      )}

      {syntheses.length > 0 && (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Knowledge Syntheses</h4>
          {syntheses.map((s) => (
            <div key={s.name} className="border-b border-[var(--color-slate-border)] last:border-0 pb-1.5 mb-1.5 last:pb-0 last:mb-0">
              <div className="flex items-center gap-2">
                <span className={`text-[10px] px-1.5 py-0.5 rounded font-mono ${
                  s.severity === 'critical' ? 'bg-red-900/40 text-red-300' :
                  s.severity === 'high' ? 'bg-amber-900/40 text-amber-300' :
                  'bg-slate-800 text-slate-300'
                }`}>{s.severity}</span>
                <span className="text-[var(--color-cyan-bright)] text-xs">{s.name}</span>
              </div>
              <p className="text-[var(--color-slate-muted)] text-[10px] mt-0.5">{s.description}</p>
            </div>
          ))}
        </div>
      )}

      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Root Causes</h4>
        <p className="text-[var(--color-slate-muted)] italic text-[10px]">
          Use the Causal Explorer to trace root causes interactively.
        </p>
      </div>
    </div>
  )
}
