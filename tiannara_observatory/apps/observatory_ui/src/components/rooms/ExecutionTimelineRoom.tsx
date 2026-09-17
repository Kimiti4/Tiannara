'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function ExecutionTimelineRoom() {
  const [events, setEvents] = useState<Record<string, unknown>[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.ops.replay().then((d) => { setEvents((d as { events: Record<string, unknown>[] }).events || []); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading execution timeline...</div>

  const grouped = events.reduce<Record<string, Record<string, unknown>[]>>((acc, e) => {
    const oid = String(e.operation_id)
    if (!acc[oid]) acc[oid] = []
    acc[oid].push(e)
    return acc
  }, {})

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-teal-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Execution Timeline</span><span className="text-[var(--color-slate-muted)]">plan → authorize → execute → verify → replay</span></div>
      <div className="space-y-2">
        {Object.entries(grouped).map(([oid, evts]) => (<div key={oid} className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-2.5 space-y-1">
          <h4 className="text-[var(--color-cyan-bright)] font-mono text-[11px]">{oid}</h4>
          <div className="space-y-0.5">
            {evts.sort((a, b) => String(a.timestamp || '').localeCompare(String(b.timestamp || ''))).map((e, idx) => {
              const result = e.result as string | undefined
              return (<div key={idx} className="flex items-center gap-2 text-[10px]">
                <span className="text-[var(--color-slate-muted)] w-20">{String(e.action)}</span>
                <span className="text-[var(--color-slate-secondary)]">{String(e.actor)}</span>
                {result && <span className={`${result === 'success' || result === 'passed' ? 'text-green-400' : 'text-red-400'}`}>{result}</span>}
              </div>)
            })}
          </div>
        </div>))}
      </div>
    </div>
  )
}
