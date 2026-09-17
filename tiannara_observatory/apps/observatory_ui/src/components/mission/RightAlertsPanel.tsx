'use client'

import { useState } from 'react'
import { IconWarning, IconInfo, IconCheck } from '@/components/icons/ObservatoryIcons'

type AlertItem = { type: 'warning' | 'info' | 'success'; time: string; message: string }

const INITIAL: AlertItem[] = [
  { type: 'warning', time: '13:41:22', message: 'High computational load on Simulation Cluster 3' },
  { type: 'info', time: '13:35:02', message: 'New dataset integrated: Ocean Microbiome Atlas v2' },
  { type: 'success', time: '13:22:17', message: 'Hypothesis H-2025-0515-0912 validated' },
  { type: 'info', time: '13:15:44', message: 'Engineering Program EP-2025-0510 completed verification' },
  { type: 'warning', time: '13:05:12', message: 'Data latency detected in Satellite Stream 7' },
]

const ICONS: Record<string, typeof IconWarning> = { warning: IconWarning, info: IconInfo, success: IconCheck }

const BORDERS: Record<string, string> = {
  warning: 'border-l-[var(--color-amber-bright)]',
  info: 'border-l-[var(--color-cyan-bright)]',
  success: 'border-l-[var(--color-emerald-bright)]',
}

const ICON_CLS: Record<string, string> = {
  warning: 'text-[var(--color-amber-bright)]',
  info: 'text-[var(--color-cyan-bright)]',
  success: 'text-[var(--color-emerald-bright)]',
}

export function RightAlertsPanel() {
  const [alerts] = useState(INITIAL)

  return (
    <aside className="glass rounded-lg p-4 overflow-y-auto flex flex-col h-full">
      <div className="flex items-center justify-between mb-3">
        <h3 className="text-xs font-semibold tracking-wider">ALERTS & NOTIFICATIONS</h3>
        <button className="text-[10px] text-[var(--color-cyan-bright)] hover:text-[var(--color-emerald-bright)]">VIEW ALL</button>
      </div>

      <div className="flex flex-col gap-2 flex-1">
        {alerts.map((a, i) => {
          const Icon = ICONS[a.type]
          return (
            <div
              key={i}
              className={`flex gap-2 rounded-md bg-black/20 p-2.5 border-l-2 ${BORDERS[a.type]} hover:bg-black/30 transition-colors`}
            >
              <Icon size={14} className={`shrink-0 mt-0.5 ${ICON_CLS[a.type]}`} />
              <div className="min-w-0">
                <div className="font-mono text-[10px] text-[var(--color-slate-muted)]">{a.time}</div>
                <div className="text-[11px] text-[var(--color-slate-secondary)] leading-relaxed">{a.message}</div>
              </div>
            </div>
          )
        })}
      </div>
    </aside>
  )
}
