'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CivilizationRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.civilization().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-rose-400">Innovation Index: {String(data.innovation_index ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Technology Level: {String(data.tech_level ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Kardashev Stage: {String(data.kardashev_stage ?? '—')}</p>
    </div>
  )
}
