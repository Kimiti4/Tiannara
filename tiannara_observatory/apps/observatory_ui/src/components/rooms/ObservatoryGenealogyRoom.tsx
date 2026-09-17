'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ObservatoryGenealogyRoom() {
  const [lineage, setLineage] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.meta.lineage().then((d) => { setLineage(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading observatory genealogy...</div>

  const versions = (lineage.versions || []) as Record<string, unknown>[]
  const current = String(lineage.current || '')

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-amber-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Observatory Genealogy</span><span className="text-[var(--color-slate-muted)]">current: v{current}</span></div>
      <div className="space-y-1.5">
        {versions.sort((a, b) => String(a.version || '').localeCompare(String(b.version || ''))).reverse().map((v) => {
        const deployedAt = v.deployed_at as string | undefined
        const changes = v.changes as string[] | undefined
        return (<div key={String(v.version)} className={`rounded-md border p-2.5 space-y-1 ${String(v.version) === current ? 'border-[var(--color-cyan-bright)]/40 bg-[var(--color-cyan-bright)]/5' : 'border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40'}`}>
          <div className="flex justify-between items-center">
            <span className="text-[var(--color-cyan-bright)] font-mono">{String(v.name)}</span>
            <div className="flex gap-2 items-center">
              <span className="text-[10px] text-[var(--color-slate-muted)]">v{String(v.version)}</span>
              <span className={`text-[9px] px-1.5 rounded font-mono ${String(v.certification) === 'certified' ? 'bg-green-900/40 text-green-300' : 'bg-amber-900/40 text-amber-300'}`}>{String(v.certification)}</span>
            </div>
          </div>
          {deployedAt && <p className="text-[9px] text-[var(--color-slate-muted)]">deployed: {deployedAt} · components: {String(v.components)}</p>}
          {changes && Array.isArray(changes) && <div className="text-[9px] text-[var(--color-slate-secondary)]">{changes.map((c) => <span key={c} className="mr-2">→ {c}</span>)}</div>}
        </div>)
      })}
      </div>
    </div>
  )
}
