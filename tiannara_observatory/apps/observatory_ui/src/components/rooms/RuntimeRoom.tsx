'use client'

import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function RuntimeRoom() {
  const [health, setHealth] = useState<Record<string, unknown>>({})

  useEffect(() => {
    api.runtime.health().then(setHealth).catch(() => {})
  }, [])

  return (
    <div className="space-y-2 text-xs">
      <div className="flex items-center gap-2">
        <span className="inline-block h-2 w-2 rounded-full bg-green-500" />
        <span>OTP: {String(health.otp_status || 'unknown')}</span>
      </div>
      <div className="text-[var(--color-slate-muted)]">
        <span>PID: {String(health.pid || 'N/A')}</span>
      </div>
    </div>
  )
}
