'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ResourceCommandRoom() {
  const [resources, setResources] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.ops.resources().then((d) => { setResources(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading resource command...</div>

  const resourcesList = ['cpu', 'gpu', 'memory', 'storage', 'human_operators', 'budget', 'energy']

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-amber-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Resource Command</span><span className="text-[var(--color-slate-muted)]">live allocation and optimization</span></div>
      <div className="grid grid-cols-2 gap-3">
        {resourcesList.map((rk) => {
          const r = resources[rk] as Record<string, unknown> || {}
          return (<div key={rk} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
            <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">{rk.replace(/_/g, ' ')}</h4>
            <div className="flex justify-between text-sm"><span className="font-mono text-[var(--color-cyan-bright)]">{String(r.allocated)}</span><span className="text-[var(--color-slate-muted)]">/ {String(r.total)} {String(r.unit)}</span></div>
            <div className="w-full h-1.5 bg-[var(--color-slate-surface)] rounded-full overflow-hidden">
              <div className={`h-full rounded-full ${Number(r.available || 0) / Number(r.total || 1) < 0.15 ? 'bg-red-500' : Number(r.available || 0) / Number(r.total || 1) < 0.3 ? 'bg-amber-500' : 'bg-green-500'}`}
                style={{ width: `${(Number(r.allocated || 0) / Number(r.total || 1) * 100).toFixed(0)}%` }} />
            </div>
            <div className="text-[9px] text-[var(--color-slate-muted)]">{String(r.available)} available</div>
          </div>)
        })}
      </div>
    </div>
  )
}
