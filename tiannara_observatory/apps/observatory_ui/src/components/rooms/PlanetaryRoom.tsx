'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function PlanetaryRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.planetary().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-teal-400">Climate Index: {String(data.climate_index ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Energy Grid: {String(data.energy_status ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Infrastructure: {String(data.infrastructure_health ?? '—')}</p>
    </div>
  )
}
