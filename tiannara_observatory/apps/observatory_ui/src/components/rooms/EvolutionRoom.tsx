'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function EvolutionRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.evolution().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-emerald-400">Generations: {String(data.generation_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Candidates: {String(data.candidate_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Regressions: {String(data.regression_count ?? '—')}</p>
    </div>
  )
}
