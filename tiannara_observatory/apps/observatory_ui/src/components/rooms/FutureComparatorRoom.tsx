'use client'
import { useEffect, useState } from 'react'
import { api } from '@/lib/api'

export function FutureComparatorRoom() {
  const [tree, setTree] = useState<Record<string, unknown>>({})
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    api.futures.tree().then((d) => { setTree(d as Record<string, unknown>); setLoading(false) }).catch(() => setLoading(false))
  }, [])

  if (loading) return <div className="text-[var(--color-slate-muted)] text-xs">Loading future comparator...</div>

  const rawTree = (tree.tree || {}) as Record<string, unknown>
  const branchCount = Number(tree.total_branches || 0)

  const root = rawTree.root as Record<string, unknown> || {}
  const children = (root.children || []) as string[]

  return (
    <div className="space-y-3 text-xs">
      <div className="flex items-center gap-2"><span className="inline-block h-2 w-2 rounded-full bg-cyan-500" /><span className="text-[var(--color-cyan-bright)] font-medium">Future Comparator</span><span className="text-[var(--color-slate-muted)]">{branchCount} branches across tree</span></div>
      <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/40 p-3 space-y-2">
        <h4 className="text-[10px] tracking-widest text-[var(--color-slate-muted)] uppercase">Present → Future Branches</h4>
        <div className="space-y-1">
          {children.map((cid) => {
            const node = rawTree[cid] as Record<string, unknown> || {}
            const grandchildren = node.children as string[] | undefined
            return (<div key={cid} className="border border-[var(--color-slate-border)] rounded p-2 space-y-1">
              <div className="flex justify-between"><span className="text-[var(--color-cyan-bright)] font-mono">{String(node.name || cid)}</span><span className="font-mono text-[10px]">{(Number(node.probability || 0) * 100).toFixed(0)}%</span></div>
              <div className="grid grid-cols-3 gap-2 text-[10px]">
                <div><span className="text-[var(--color-slate-muted)]">Benefit</span><p className="font-mono text-green-400">{(Number(node.benefit || 0) * 100).toFixed(0)}%</p></div>
                <div><span className="text-[var(--color-slate-muted)]">Risk</span><p className="font-mono text-amber-400">{(Number(node.risk || 0) * 100).toFixed(0)}%</p></div>
                <div><span className="text-[var(--color-slate-muted)]">Fitness</span><p className="font-mono text-cyan-400">{(Number(node.fitness || 0) * 100).toFixed(0)}%</p></div>
              </div>
              {grandchildren && grandchildren.length > 0 && <div className="ml-3 space-y-1 pt-1 border-t border-[var(--color-slate-border)]">
                {grandchildren.map((gcid) => {
                  const gnode = rawTree[gcid] as Record<string, unknown> || {}
                  return (<div key={gcid} className="flex justify-between text-[10px]"><span className="text-[var(--color-slate-secondary)]">{String(gnode.name || gcid)}</span><span className="font-mono">{(Number(gnode.probability || 0) * 100).toFixed(0)}%</span></div>)
                })}
              </div>}
            </div>)
          })}
        </div>
      </div>
    </div>
  )
}
