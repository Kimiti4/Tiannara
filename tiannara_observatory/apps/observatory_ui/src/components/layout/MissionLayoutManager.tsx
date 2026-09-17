'use client'

import { useState, useCallback } from 'react'
import { storage } from '@/lib/storage'
import type { WidgetConfig } from '@/types'

const WIDGET_TEMPLATES: Record<string, WidgetConfig[]> = {
  runtime: [
    { id: 'health-1', type: 'health', title: 'System Health', room: 'runtime', x: 0, y: 0, w: 1, h: 1 },
    { id: 'events-1', type: 'events', title: 'Live Events', room: 'runtime', x: 1, y: 0, w: 2, h: 2 },
    { id: 'metrics-1', type: 'metrics', title: 'Key Metrics', room: 'runtime', x: 3, y: 0, w: 1, h: 2 },
  ],
  science: [
    { id: 'sc-events-1', type: 'events', title: 'Science Events', room: 'science', x: 0, y: 0, w: 2, h: 2 },
    { id: 'sc-metrics-2', type: 'metrics', title: 'Discovery Metrics', room: 'science', x: 2, y: 0, w: 2, h: 1 },
  ],
  replay: [
    { id: 'rp-timeline-1', type: 'timeline', title: 'Timeline', room: 'replay', x: 0, y: 0, w: 2, h: 2 },
    { id: 'rp-replay-1', type: 'replay', title: 'Replay Controls', room: 'replay', x: 2, y: 0, w: 2, h: 1 },
  ],
}

interface Props {
  room: string
  children: (widgets: WidgetConfig[], removeWidget: (id: string) => void) => React.ReactNode
}

export function MissionLayoutManager({ room, children }: Props) {
  const [widgets, setWidgets] = useState<WidgetConfig[]>(() => {
    const saved = storage.loadWidgets(room)
    if (saved.length > 0) return saved
    return WIDGET_TEMPLATES[room] || [{ id: `${room}-default`, type: 'events', title: `${room} stream`, room, x: 0, y: 0, w: 4, h: 2 }]
  })

  const removeWidget = useCallback(
    (id: string) => {
      const next = widgets.filter((w) => w.id !== id)
      setWidgets(next)
      storage.saveWidgets(room, next)
    },
    [widgets, room],
  )

  return <>{children(widgets, removeWidget)}</>
}
