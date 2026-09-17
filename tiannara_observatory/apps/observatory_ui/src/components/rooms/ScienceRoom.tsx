'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ScienceRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.science().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-cyan-400">Discoveries: {String(data.discovery_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Active Experiments: {String(data.active_experiments ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Hypotheses: {String(data.hypothesis_count ?? '—')}</p>
    </div>
  )
}
