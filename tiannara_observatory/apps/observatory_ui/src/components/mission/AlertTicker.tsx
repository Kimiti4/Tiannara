'use client'

import { useState } from 'react'

interface AlertItem { type: string; text: string; time: string }

const INITIAL: AlertItem[] = [
  { type: 'warning', text: 'High computational load on Simulation Cluster 3', time: '13:41:22' },
  { type: 'info', text: 'New dataset integrated: Ocean Microbiome Atlas v2', time: '13:35:02' },
  { type: 'success', text: 'Hypothesis H-2025-0515-0912 validated', time: '13:22:17' },
  { type: 'info', text: 'Engineering Program EP-2025-0510 completed verification', time: '13:15:44' },
]

const TYPE_CLS: Record<string, string> = {
  warning: 'text-[var(--color-amber-bright)]',
  info: 'text-[var(--color-cyan-bright)]',
  success: 'text-[var(--color-emerald-bright)]',
  critical: 'text-[var(--color-rose-bright)]',
}

export function AlertTicker() {
  const [items] = useState(INITIAL)

  return (
    <div className="flex items-center gap-4 border-b border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/80 px-6 py-1.5 text-[11px]">
      <div className="flex items-center gap-2 shrink-0">
        <span className="text-[9px] tracking-widest text-[var(--color-slate-muted)]">ACTIVE ALERTS</span>
        <span className="font-mono text-[10px] text-[var(--color-amber-bright)]">▲ 0</span>
        <span className="font-mono text-[10px] text-[var(--color-cyan-bright)]">● 2</span>
      </div>

      <div className="flex gap-4 overflow-hidden flex-1">
        {items.map((a, i) => (
          <span key={i} className={`whitespace-nowrap ${TYPE_CLS[a.type] || 'text-[var(--color-slate-secondary)]'}`}>
            {a.time} – {a.text}
          </span>
        ))}
      </div>

      <button className="shrink-0 text-[10px] text-[var(--color-cyan-bright)] hover:text-[var(--color-emerald-bright)] transition-colors">
        VIEW ALL →
      </button>
    </div>
  )
}
