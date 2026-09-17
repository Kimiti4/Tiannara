'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function KnowledgeRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.knowledge().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-violet-400">Concepts: {String(data.concept_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Relations: {String(data.relation_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Unknowns: {String(data.unknown_count ?? '—')}</p>
    </div>
  )
}
