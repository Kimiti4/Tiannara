'use client'

export function DashboardFooter() {
  return (
    <footer className="flex items-center justify-between border-t border-[var(--color-slate-border)] bg-[var(--color-slate-deep)]/95 px-6 py-2 text-[10px] text-[var(--color-slate-muted)]">
      <div className="flex items-center gap-2">
        <span>Tiannara Constitutional OS v25.9.0</span>
        <span className="text-[var(--color-slate-border)]">|</span>
        <span>Expand Knowledge. Preserve Life.</span>
        <span className="text-[var(--color-slate-border)]">|</span>
        <span>Learn Continuously. Improve Perpetually.</span>
      </div>
      <span className="text-[var(--color-emerald-bright)]">All systems operational.</span>
    </footer>
  )
}
