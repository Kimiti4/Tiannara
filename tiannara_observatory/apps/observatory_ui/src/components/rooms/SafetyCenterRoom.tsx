'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function SafetyCenterRoom() {
  const [safety, setSafety] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.ops.safety().then((d) => { setSafety(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading safety center...</div>

  const interventions = (safety.interventions || []) as Record<string, unknown>[]
  const halted = Boolean(safety.halted)

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className={`inline-block h-2 w-2 rounded-full ${halted ? 'bg-red-500' : 'bg-green-500'}`} /><span className="text-[var(--color-cyan-bright)] font-medium">Safety Center</span>
        {halted && <span className="text-red-400 font-mono text-[10px]">HALTED: {String(safety.halt_reason)}</span>}
        {!halted && <span className="text-green-400 text-[10px]">{String(safety.mode)}</span>}
      </div>
      <div className="grid grid-cols-2 gap-3">
        {interventions.map((si) => (<div key={String(si.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="font-mono text-[var(--color-cyan-bright)]">{String(si.type).replace(/_/g, ' ')}</span>
            <span className={`text-[10px] px-1.5 rounded font-mono ${si.detected ? 'bg-red-900/40 text-red-300' : 'bg-green-900/40 text-green-300'}`}>{si.detected ? 'TRIGGERED' : 'OK'}</span>
          </div>
          <div className="flex justify-between text-[10px]"><span className="text-[var(--color-slate-muted)]">current: {(Number(si.current_value || 0) * 100).toFixed(0)}%</span><span className="text-red-400">threshold: {(Number(si.threshold || 0) * 100).toFixed(0)}%</span></div>
        </div>))}
      </div>
    </div>
  )
}
