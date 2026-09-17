'use client'

import { WidgetGrid } from './WidgetGrid'
import { FullDashboard } from './FullDashboard'
import { LazyRoom } from '@/components/rooms/RoomRegistry'
import { StreamAwareWidget } from './StreamAwareWidget'
import type { WidgetConfig } from '@/types'

interface Props {
  roomSlug: string
  roomName: string
  widgets: WidgetConfig[]
  onReorder: (widgets: WidgetConfig[]) => void
  onRemove: (id: string) => void
  onResize: (id: string, w: number, h: number) => void
}

export function Workspace({ roomSlug, roomName, widgets, onReorder, onRemove, onResize }: Props) {
  const isMain = roomSlug === 'runtime' || roomSlug === 'mission-control'

  if (isMain) {
    return (
      <main className="flex flex-1 flex-col overflow-hidden">
        <FullDashboard />
      </main>
    )
  }

  return (
    <main className="flex flex-1 flex-col overflow-hidden">
      <div className="border-b border-[var(--color-slate-border)] px-4 py-2 flex items-center gap-2">
        <h2 className="text-sm font-semibold text-[var(--color-slate-text)]">{roomName}</h2>
        <span className="text-[10px] text-[var(--color-slate-muted)] font-mono">/ {roomSlug}</span>
      </div>
      <div className="flex-1 overflow-y-auto">
        <WidgetGrid
          widgets={widgets}
          onReorder={onReorder}
          onRemove={onRemove}
          onResize={onResize}
          renderWidget={(w) => (
            <StreamAwareWidget widget={w}>
              <LazyRoom slug={roomSlug} />
            </StreamAwareWidget>
          )}
        />
      </div>
    </main>
  )
}
