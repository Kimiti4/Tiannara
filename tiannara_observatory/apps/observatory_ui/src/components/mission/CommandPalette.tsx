'use client'

import { useState, useCallback, useRef, useEffect } from 'react'
import type { CommandAction } from '@/types'

interface Props {
  commands: CommandAction[]
  onClose: () => void
}

export function CommandPalette({ commands, onClose }: Props) {
  const [query, setQuery] = useState('')
  const inputRef = useRef<HTMLInputElement>(null)

  const filtered = query
    ? commands.filter((c) => c.label.toLowerCase().includes(query.toLowerCase()))
    : commands

  const [selected, setSelected] = useState(0)

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  const execute = useCallback(
    (cmd: CommandAction) => {
      cmd.action()
      onClose()
    },
    [onClose],
  )

  const handleKey = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'ArrowDown') { e.preventDefault(); setSelected((s) => Math.min(s + 1, filtered.length - 1)) }
      if (e.key === 'ArrowUp') { e.preventDefault(); setSelected((s) => Math.max(s - 1, 0)) }
      if (e.key === 'Enter' && filtered[selected]) execute(filtered[selected])
      if (e.key === 'Escape') onClose()
    },
    [filtered, selected, execute, onClose],
  )

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]">
      <div className="fixed inset-0 bg-black/60" onClick={onClose} />
      <div className="relative w-full max-w-xl rounded-lg border border-[var(--color-slate-border)] bg-[var(--color-slate-surface)] shadow-2xl">
        <div className="flex items-center border-b border-[var(--color-slate-border)] px-3">
          <span className="text-xs text-[var(--color-slate-muted)] mr-2">&gt;</span>
          <input
            ref={inputRef}
            value={query}
            onChange={(e) => { setQuery(e.target.value); setSelected(0) }}
            onKeyDown={handleKey}
            placeholder="Type a command..."
            className="flex-1 bg-transparent py-3 text-lg text-[var(--color-slate-text)] outline-none placeholder:text-[var(--color-slate-muted)]"
          />
          <span className="text-[10px] text-[var(--color-slate-muted)]">Ctrl+Shift+P</span>
        </div>
        <div className="max-h-80 overflow-y-auto py-2">
          {filtered.map((cmd, i) => (
            <button
              key={cmd.id}
              onClick={() => execute(cmd)}
              className={`w-full px-4 py-2 text-left text-sm flex items-center justify-between ${
                i === selected ? 'bg-[var(--color-cyan-bright)]/10 text-white' : 'text-[var(--color-slate-secondary)]'
              }`}
            >
              <span>{cmd.label}</span>
              <span className="text-xs text-[var(--color-slate-muted)]">{cmd.category}</span>
            </button>
          ))}
          {filtered.length === 0 && (
            <p className="px-4 py-3 text-sm text-[var(--color-slate-muted)]">No matching commands</p>
          )}
        </div>
      </div>
    </div>
  )
}
