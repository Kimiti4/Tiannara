'use client'

interface Props {
  title: string
  children: React.ReactNode
  className?: string
}

export function DataPanel({ title, children, className = '' }: Props) {
  return (
    <section className={`glass-hover rounded-lg p-4 ${className}`}>
      <h2 className="text-xs font-semibold tracking-wider text-[var(--color-slate-text)] mb-3">{title}</h2>
      <div className="space-y-2">
        {children}
      </div>
    </section>
  )
}

export function MetricRow({ label, value, color }: { label: string; value: string; color?: string }) {
  return (
    <div className="flex items-center justify-between py-1 border-b border-white/5 last:border-0">
      <span className="text-[11px] text-[var(--color-slate-secondary)]">{label}</span>
      <span className={`font-mono text-xs font-semibold ${color || 'text-[var(--color-slate-text)]'}`}>{value}</span>
    </div>
  )
}

export function StatBox({ label, value, color }: { label: string; value: string; color?: string }) {
  return (
    <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-cyan-bright)]/5 p-3">
      <div className="text-[9px] tracking-widest text-[var(--color-slate-muted)] mb-1">{label}</div>
      <div className={`font-mono text-sm font-semibold ${color || 'text-[var(--color-cyan-bright)]'}`}>{value}</div>
    </div>
  )
}

export function HealthBar({ label, value, max = 100 }: { label: string; value: number; max?: number }) {
  const pct = Math.round((value / max) * 100)
  return (
    <div className="flex items-center gap-2">
      <span className="flex-1 text-[11px] text-[var(--color-slate-secondary)]">{label}</span>
      <div className="flex-[2] h-1.5 rounded-full bg-white/10 overflow-hidden">
        <div
          className="h-full rounded-full transition-all duration-500"
          style={{
            width: `${pct}%`,
            background: `linear-gradient(90deg, var(--color-cyan-bright), var(--color-emerald-bright))`,
          }}
        />
      </div>
      <span className="flex-[0_0_40px] font-mono text-[11px] text-right text-[var(--color-slate-text)]">{pct}%</span>
    </div>
  )
}
