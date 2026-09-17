'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CertificationRoom() {
  const [data, setData] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.state.certification().then(setData).catch(() => {})
  }, [])

  return (
    <div className="space-y-1 text-xs">
      <p className="text-yellow-400">Campaigns: {String(data.campaign_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Evidence: {String(data.evidence_count ?? '—')}</p>
      <p className="text-[var(--color-slate-muted)]">Readiness: {String(data.readiness_level ?? '—')}</p>
    </div>
  )
}
