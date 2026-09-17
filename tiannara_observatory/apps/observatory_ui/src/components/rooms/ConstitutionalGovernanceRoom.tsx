'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ConstitutionalGovernanceRoom() {
  const [proposals, setProposals] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.meta.governance().then((d) => { setProposals((d as { proposals: Record<string, unknown>[] }).proposals || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading constitutional governance...</div>

  const statusColors: Record<string, string> = { proposed: 'text-amber-400', simulating: 'text-blue-400', validating: 'text-purple-400', certifying: 'text-cyan-400', deployed: 'text-green-400' }

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-rose-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Constitutional Governance</span><span className="text-[var(--color-slate-muted)]">live governance of the Observatory</span></div>
      <div className="space-y-2">
        {proposals.map((p) => {
        const cert = p.certification as string | undefined
        const simResult = p.simulation_result as string | undefined
        const reviewStatus = p.review_status as string | undefined
        return (<div key={String(p.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(p.title)}</span><span className={`text-[10px] font-mono ${statusColors[String(p.status)] || ''}`}>{String(p.status)}</span></div>
          <div className="flex gap-3 text-[10px] text-[var(--color-slate-muted)]">
            <span>source: {String(p.submitted_by)}</span>
            {cert && <span className="text-green-400">certified: {cert}</span>}
            {simResult && <span className={`${simResult === 'passed' ? 'text-green-400' : 'text-red-400'}`}>{simResult}</span>}
          </div>
          {reviewStatus && <span className="text-[9px] text-[var(--color-slate-muted)]">review: {reviewStatus}</span>}
        </div>)
      })}
      </div>
    </div>
  )
}
