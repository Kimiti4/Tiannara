'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function CapabilityAtlasRoom() {
  const [caps, setCaps] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.strategy.capabilities().then((data) => { setCaps((data as { capabilities: Record<string, unknown> }).capabilities || {}); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading capability atlas...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-violet-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Capability Atlas</span><span className="text-[var(--color-slate-muted)]">interactive capability dependency graph</span></div>
      <div className="grid grid-cols-2 gap-3">
        {Object.entries(caps).sort(([, a], [, b]) => Number((b as Record<string, unknown>).trl || 0) - Number((a as Record<string, unknown>).trl || 0)).map(([id, cap]) => {
          const c = cap as Record<string, unknown>
          const domains = c.domains as string[] | undefined
          return (<div key={id} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(c.name || id)}</span><span className={`text-[10px] px-1.5 rounded font-mono ${Number(c.trl || 0) >= 7 ? 'bg-green-900/40 text-green-300' : Number(c.trl || 0) >= 4 ? 'bg-amber-900/40 text-amber-300' : 'bg-red-900/40 text-red-300'}`}>TRL {String(c.trl)}</span></div>
            {domains && Array.isArray(domains) && <div className="flex gap-1 flex-wrap">{domains.map((d) => <span key={d} className="text-[9px] bg-[var(--color-slate-surface)] px-1 rounded text-[var(--color-slate-secondary)]">{d}</span>)}</div>}
          </div>)
        })}
      </div>
    </div>
  )
}
