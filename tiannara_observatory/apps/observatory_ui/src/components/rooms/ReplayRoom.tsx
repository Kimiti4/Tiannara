'use client'

import { useState } from 'react'
import { api } from '@/lib/api'

export function ReplayRoom() {
  const [snapshots, setSnapshots] = useState<Record<string, unknown>[]>([])

  const load = () => {
    api.replay.snapshots('runtime').then(setSnapshots).catch(() => {})
  }

  return (
    <div className="space-y-2 text-xs">
      <button onClick={load} className="rounded border border-[var(--color-slate-border)] px-2 py-1 text-[var(--color-slate-muted)] hover:bg-slate-800">
        Load Snapshots
      </button>
      {snapshots.length > 0 && (
        <ul className="space-y-1">
          {snapshots.slice(0, 10).map((s, i) => (
            <li key={i} className="flex items-center gap-2 text-[var(--color-slate-muted)]">
              <span className="inline-block h-1.5 w-1.5 rounded-full bg-cyan-500" />
              {String(s.generation ?? s.timestamp ?? s.id ?? `snapshot-${i}`)}
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}
