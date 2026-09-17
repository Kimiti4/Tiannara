'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

interface ScenarioEntry {
  scenario: string
  baseline?: Record<string, number>
  outcome?: Record<string, number>
  deltas?: Record<string, number>
  simulated_at?: string
}

const SCENARIO_TYPES = [
  'increase_compute', 'reduce_experiments', 'ontology_expansion',
  'runtime_upgrade', 'new_domain', 'hardware_failure'
]

export function ScenarioLabRoom() {
  const [scenarios, setScenarios] = useState<Record<string, ScenarioEntry>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.cpo.scenarios().then((data) => {
      setScenarios(data as Record<string, ScenarioEntry>)
      setLoading(false)
    }).catch(() => setLoading(false))
  }, [])

  if (loading) {
    return <div className="text-[var(--color-slate-muted)] text-xs">Loading scenarios...</div>
  }

  const metricKeys = ['discovery_rate', 'knowledge_growth', 'theory_evolution', 'resource_usage', 'runtime_load']

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-violet-500" />
        <span className="text-[var(--color-cyan-bright)] font-medium">Scenario Lab</span>
        <span className="text-[var(--color-slate-muted)]">simulate futures before they happen</span>
      </div>

      {Object.keys(scenarios).length === 0 ? (
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5">
          <p className="text-[var(--color-slate-muted)] italic text-[10px]">No scenarios simulated yet. Use the API to run scenario simulations.</p>
        </div>
      ) : (
        Object.entries(scenarios).map(([name, sc]) => (
          <div key={name} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase font-mono">{name}</h4>
            {sc.outcome && (
              <div className="grid grid-cols-2 gap-1 text-[10px]">
                {metricKeys.map((mk) => {
                  const base = sc.baseline?.[mk] ?? 0
                  const out = sc.outcome?.[mk] ?? 0
                  const delta = out - base
                  return (
                    <div key={mk} className="flex items-center justify-between">
                      <span className="text-[var(--color-slate-muted)]">{mk}</span>
                      <span className={`font-mono ${delta > 0 ? 'text-green-400' : delta < 0 ? 'text-red-400' : 'text-slate-400'}`}>
                        {base.toFixed(1)} → {out.toFixed(1)}
                        <span className="ml-1">({delta > 0 ? '+' : ''}{delta.toFixed(2)})</span>
                      </span>
                    </div>
                  )
                })}
              </div>
            )}
          </div>
        ))
      )}
    </div>
  )
}
