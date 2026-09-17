'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function OperationsCommandRoom() {
  const [plans, setPlans] = useState<Record<string, unknown>[]>([])
  const [exec, setExec] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    Promise.all([
      api.ops.plans().catch(() => ({ plans: [] })),
      api.ops.execution().catch(() => ({})),
    ]).then(([p, e]) => { setPlans((p as { plans: Record<string, unknown>[] }).plans || []); setExec(e as Record<string, unknown>); setLoading(false) })
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading operations command...</div>

  const queue = (exec.execution_queue || []) as string[]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-blue-600" /><span className="text-[var(--color-cyan-bright)] font-medium">Operations Command</span><span className="text-[var(--color-slate-muted)]">NASA mission control for Tiannara</span></div>
      <div className="grid grid-cols-3 gap-2">
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Active</h4><p className="font-mono text-amber-400">{((exec.active_operations || []) as string[]).length}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Queue</h4><p className="font-mono text-[var(--color-cyan-bright)]">{queue.length}</p>
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Status</h4><p className="font-mono text-green-400">{String(exec.status || '—')}</p>
        </div>
      </div>
      <div className="space-y-1.5">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Operational Plans</h4>
        {plans.map((p) => (<div key={String(p.id)} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(p.action)}</span><span className={`text-[10px] px-1.5 rounded font-mono ${String(p.status) === 'executing' ? 'bg-green-900/40 text-green-300' : String(p.status) === 'approved' ? 'bg-blue-900/40 text-blue-300' : String(p.status) === 'proposed' ? 'bg-amber-900/40 text-amber-300' : 'bg-purple-900/40 text-purple-300'}`}>{String(p.status)}</span></div>
          <p className="text-[var(--color-slate-muted)] text-[10px]">{String(p.target)} — {String(p.reason)}</p>
          <div className="flex gap-3 text-[10px]"><span className="text-[var(--color-slate-muted)]">benefit: {(Number(p.benefit || 0) * 100).toFixed(0)}%</span><span className="text-amber-400">risk: {(Number(p.risk || 0) * 100).toFixed(0)}%</span></div>
        </div>))}
      </div>
    </div>
  )
}
