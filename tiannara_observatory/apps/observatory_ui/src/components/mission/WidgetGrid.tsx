'use client'

import { useState, useCallback } from 'react'
import {
  DndContext,
  closestCenter,
  KeyboardSensor,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
} from '@dnd-kit/core'
import {
  SortableContext,
  sortableKeyboardCoordinates,
  rectSortingStrategy,
  arrayMove,
} from '@dnd-kit/sortable'
import { Widget } from './Widget'
import type { WidgetConfig } from '@/types'

interface Props {
  widgets: WidgetConfig[]
  onReorder?: (widgets: WidgetConfig[]) => void
  onRemove: (id: string) => void
  onResize?: (id: string, w: number, h: number) => void
  renderWidget: (w: WidgetConfig) => React.ReactNode
}

export function WidgetGrid({ widgets, onReorder, onRemove, onResize, renderWidget }: Props) {
  const [items, setItems] = useState(() => widgets.map((w) => w.id))

  const sensors = useSensors(
    useSensor(PointerSensor, { activationConstraint: { distance: 8 } }),
    useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates })
  )

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      const { active, over } = event
      if (over && active.id !== over.id) {
        const oldIdx = items.indexOf(active.id as string)
        const newIdx = items.indexOf(over.id as string)
        const nextIds = arrayMove(items, oldIdx, newIdx)
        setItems(nextIds)
        const reordered = nextIds.map((id) => widgets.find((w) => w.id === id)!).filter(Boolean)
        onReorder?.(reordered)
      }
    },
    [items, widgets, onReorder]
  )

  if (widgets.length === 0) {
    return (
      <div className="flex flex-1 items-center justify-center text-slate-600">
        <p className="text-sm">No widgets yet. Use Ctrl+Shift+P to add widgets.</p>
      </div>
    )
  }

  return (
    <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
      <SortableContext items={items} strategy={rectSortingStrategy}>
        <div className="grid grid-cols-4 gap-3 p-4 auto-rows-[minmax(120px,auto)]">
          {widgets.map((w) => (
            <Widget key={w.id} widget={w} onRemove={onRemove} onResize={onResize}>
              {renderWidget(w)}
            </Widget>
          ))}
        </div>
      </SortableContext>
    </DndContext>
  )
}
