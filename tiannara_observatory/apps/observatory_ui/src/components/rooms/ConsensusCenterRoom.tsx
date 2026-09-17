'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ConsensusCenterRoom() {
  const [props, setProps] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.federation.consensus().then((d) => { setProps((d as { proposals: Record<string, unknown>[] }).proposals || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading consensus center...</div>

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-rose-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Consensus Center</span><span className="text-[var(--color-slate-muted)]">evidence-based constitutional consensus</span></div>
      <div className="space-y-2">
        {props.map((p) => (<div key={String(p.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1.5">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(p.title)}</span>
            <span className={`text-[10px] px-1.5 rounded font-mono ${String(p.status) === 'certified' ? 'bg-green-900/40 text-green-300' : String(p.status) === 'converging' ? 'bg-blue-900/40 text-blue-300' : 'bg-amber-900/40 text-amber-300'}`}>{String(p.status)}</span>
          </div>
          <div className="grid grid-cols-4 gap-2 text-[10px]">
            <div><span className="text-[var(--color-slate-muted)]">Evidence</span><p className="font-mono">{String(p.evidence_count)}</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Verifications</span><p className="font-mono">{String(p.verification_count)}</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Reproducibility</span><p className="font-mono text-green-400">{(Number(p.reproducibility_score || 0) * 100).toFixed(0)}%</p></div>
            <div><span className="text-[var(--color-slate-muted)]">Constitution</span><p className="font-mono text-cyan-400">{(Number(p.constitution_alignment || 0) * 100).toFixed(0)}%</p></div>
          </div>
          <div className="text-[9px] text-[var(--color-slate-muted)]">submitted by {String(p.submitted_by)}</div>
        </div>))}
      </div>
    </div>
  )
}
