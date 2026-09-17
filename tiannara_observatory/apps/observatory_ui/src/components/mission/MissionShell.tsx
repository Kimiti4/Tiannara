'use client'

import { useState, useEffect, useCallback } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import { DashboardHeader } from './DashboardHeader'
import { AlertTicker } from './AlertTicker'
import { LeftSidebar } from './LeftSidebar'
import { RightAlertsPanel } from './RightAlertsPanel'
import { DashboardFooter } from './DashboardFooter'
import { CommandPalette } from './CommandPalette'
import { Workspace } from './Workspace'
import { storage } from '@/lib/storage'
import { ROOMS, buildCommands } from '@/lib/commands'
import type { WidgetConfig } from '@/types'

function loadWidgetsForRoom(room: string): WidgetConfig[] {
  const saved = storage.loadWidgets(room)
  if (saved.length > 0) return saved
  return [{ id: `${room}-default`, type: 'events', title: `${room} stream`, room, x: 0, y: 0, w: 4, h: 2 }]
}

function RoomContent({ roomSlug, roomName }: { roomSlug: string; roomName: string }) {
  const [widgets, setWidgets] = useState<WidgetConfig[]>(() => loadWidgetsForRoom(roomSlug))

  const persistWidgets = useCallback(
    (next: WidgetConfig[]) => {
      setWidgets(next)
      storage.saveWidgets(roomSlug, next)
    },
    [roomSlug],
  )

  const handleReorder = useCallback(
    (reordered: WidgetConfig[]) => persistWidgets(reordered),
    [persistWidgets],
  )

  const removeWidget = useCallback(
    (id: string) => persistWidgets(widgets.filter((w) => w.id !== id)),
    [widgets, persistWidgets],
  )

  const handleResize = useCallback(
    (id: string, w: number, h: number) => {
      const next = widgets.map((wd) => (wd.id === id ? { ...wd, w, h } : wd))
      persistWidgets(next)
    },
    [widgets, persistWidgets],
  )

  return (
    <Workspace
      roomSlug={roomSlug}
      roomName={roomName}
      widgets={widgets}
      onReorder={handleReorder}
      onRemove={removeWidget}
      onResize={handleResize}
    />
  )
}

export function MissionShell() {
  const router = useRouter()
  const pathname = usePathname()
  const [collapsed, setCollapsed] = useState(false)
  const [paletteOpen, setPaletteOpen] = useState(false)

  const roomSlug = pathname?.split('/').pop() || 'runtime'
  const currentRoom = ROOMS.find((r) => r.slug === roomSlug) || ROOMS[0]

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.shiftKey && e.key === 'P') {
        e.preventDefault(); setPaletteOpen((p) => !p)
      }
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault(); setPaletteOpen((p) => !p)
      }
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [])

  const navigate = useCallback(
    (slug: string) => {
      router.push(slug === 'runtime' || slug === 'mission-control' ? '/mission-control' : `/mission-control/${slug}`)
    },
    [router],
  )

  return (
    <div className="flex h-screen flex-col bg-gradient-to-br from-[var(--color-slate-deep)] via-[#1a1f3a] to-[var(--color-slate-deep)]">
      <DashboardHeader identity={null} onNavigate={navigate} onOpenPalette={() => setPaletteOpen(true)} />
      <AlertTicker />

      <div className="flex flex-1 overflow-hidden gap-1.5 p-1.5">
        <LeftSidebar activeRoom={roomSlug} collapsed={collapsed} onToggle={() => setCollapsed((c) => !c)} onNavigate={navigate} />

        <RoomContent key={roomSlug} roomSlug={roomSlug} roomName={currentRoom.name} />

        <div className="w-72 shrink-0 hidden xl:flex">
          <RightAlertsPanel />
        </div>
      </div>

      <DashboardFooter />

      {paletteOpen && (
        <CommandPalette
          commands={buildCommands(navigate)}
          onClose={() => setPaletteOpen(false)}
        />
      )}
    </div>
  )
}
