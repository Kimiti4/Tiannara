'use client'

import { useEffect, useState } from 'react'
import { IconMissionControl } from '@/components/icons/ObservatoryIcons'

interface Props {
  identity: string | null
  onNavigate: (slug: string) => void
  onOpenPalette: () => void
}

export function DashboardHeader({ identity, onNavigate, onOpenPalette }: Props) {
  const [clock, setClock] = useState(new Date().toISOString().slice(0, 19).replace('T', ' ') + ' UTC')

  useEffect(() => {
    const t = setInterval(() => {
      setClock(new Date().toISOString().slice(0, 19).replace('T', ' ') + ' UTC')
    }, 1000)
    return () => clearInterval(t)
  }, [])

  return (
    <header className="flex items-center justify-between border-b border-[var(--color-slate-border)] bg-[var(--color-slate-deep)]/95 px-6 py-3 backdrop-blur-md z-50">
      <div className="flex items-center gap-4">
        <button onClick={() => onNavigate('runtime')} className="flex items-center gap-3 group">
          <IconMissionControl className="text-[var(--color-cyan-bright)] group-hover:opacity-80 transition-opacity" size={36} />
          <div>
            <h1 className="text-base font-bold tracking-wider text-[var(--color-slate-text)]">TIANNARA OBSERVATORY</h1>
            <span className="text-[10px] text-[var(--color-slate-secondary)] tracking-widest">Constitutional Planetary Intelligence</span>
          </div>
        </button>
      </div>

      <div className="hidden xl:flex items-center gap-6">
        {[
          { label: 'MISSION STATUS', value: '● NOMINAL', cls: 'text-[var(--color-emerald-bright)]' },
          { label: 'CONSTITUTIONAL HEALTH', value: '99.7%', cls: 'text-[var(--color-emerald-bright)]' },
          { label: 'RUNTIME INTEGRITY', value: '99.99%', cls: 'text-[var(--color-emerald-bright)]' },
          { label: 'SCIENTIFIC DISCOVERY', value: '▲ 24.7%', cls: 'text-[var(--color-emerald-bright)]' },
          { label: 'PLANETARY HEALTH', value: '84.6%', cls: 'text-[var(--color-amber-bright)]' },
          { label: 'CIVILIZATIONAL PROGRESS', value: '72.1%', cls: 'text-[var(--color-cyan-bright)]' },
        ].map((s) => (
          <div key={s.label} className="flex flex-col items-center gap-0.5">
            <span className="text-[9px] text-[var(--color-slate-muted)] tracking-widest">{s.label}</span>
            <span className={`font-mono text-xs font-semibold ${s.cls}`}>{s.value}</span>
          </div>
        ))}
      </div>

      <div className="flex items-center gap-4">
        <div className="text-right">
          <div className="font-mono text-xs text-[var(--color-slate-text)]">{clock}</div>
          <div className="text-[10px] text-[var(--color-slate-muted)]">T+ 128d 17h 42m</div>
        </div>

        <button onClick={onOpenPalette} className="glass rounded-md px-3 py-1.5 text-[11px] text-[var(--color-slate-muted)] hover:border-[var(--color-slate-border-hover)]">
          ⌘K / ⌘⇧P
        </button>

        {identity && (
          <span className="text-[10px] text-[var(--color-slate-muted)] border-l border-[var(--color-slate-border)] pl-3">
            {identity}
          </span>
        )}
      </div>
    </header>
  )
}
