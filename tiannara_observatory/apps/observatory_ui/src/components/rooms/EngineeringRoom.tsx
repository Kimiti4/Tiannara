'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function EngineeringRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.engineering().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-amber-400">Designs: {String(data.design_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Optimizations: {String(data.optimization_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">TRL Assessments: {String(data.trl_assessments ?? '—')}</p>
    </div>
  )
}
