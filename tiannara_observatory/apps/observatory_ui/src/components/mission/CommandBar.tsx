'use client'

import { useState, useEffect } from 'react'
import { CommandPalette } from './CommandPalette'
import { buildCommands, ROOMS } from '@/lib/commands'
import type { MissionMode } from '@/types'

interface Props {
  mode: MissionMode
  onModeChange: (mode: MissionMode) => void
  onNavigate: (slug: string) => void
}

const MODES: { value: MissionMode; label: string }[] = [
  { value: 'laboratory', label: 'Laboratory' },
  { value: 'discovery', label: 'Discovery' },
  { value: 'certification', label: 'Certification' },
  { value: 'planetary', label: 'Planetary' },
  { value: 'civilization', label: 'Civilization' },
  { value: 'emergency', label: 'Emergency' },
]

export function CommandBar({ mode, onModeChange, onNavigate }: Props) {
  const [paletteOpen, setPaletteOpen] = useState(false)

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'P') {
        e.preventDefault()
        setPaletteOpen((p) => !p)
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault()
        setPaletteOpen((p) => !p)
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  return (
    <>
      <header className="flex h-12 items-center justify-between border-b border-slate-800 bg-slate-950 px-4">
        <div className="flex items-center gap-4">
          <span className="text-lg font-bold tracking-tight text-cyan-400">◇ Mission Control</span>
          <nav className="hidden md:flex items-center gap-1">
            {ROOMS.map((room) => (
              <button
                key={room.slug}
                onClick={() => onNavigate(room.slug)}
                className="rounded px-2 py-1 text-xs text-slate-400 hover:bg-slate-800 hover:text-slate-200"
              >
                {room.icon} {room.name}
              </button>
            ))}
          </nav>
        </div>

        <div className="flex items-center gap-3">
          <select
            value={mode}
            onChange={(e) => onModeChange(e.target.value as MissionMode)}
            className="rounded border border-slate-700 bg-slate-900 px-2 py-1 text-xs text-slate-300"
          >
            {MODES.map((m) => (
              <option key={m.value} value={m.value}>{m.label}</option>
            ))}
          </select>

          <button
            onClick={() => setPaletteOpen(true)}
            className="flex items-center gap-1 rounded border border-slate-700 bg-slate-900 px-2 py-1 text-xs text-slate-400 hover:border-slate-500"
          >
            ⌘K / ⌘⇧P
          </button>
        </div>
      </header>

      {paletteOpen && (
        <CommandPalette
          commands={buildCommands(onNavigate)}
          onClose={() => setPaletteOpen(false)}
        />
      )}
    </>
  )
}
