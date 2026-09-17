'use client'

import { useSortable } from '@dnd-kit/sortable'
import { CSS } from '@dnd-kit/utilities'
import type { WidgetConfig } from '@/types'

interface Props {
  widget: WidgetConfig
  onRemove?: (id: string) => void
  onResize?: (id: string, w: number, h: number) => void
  children?: React.ReactNode
}

export function Widget({ widget, onRemove, onResize, children }: Props) {
  const { attributes, listeners, setNodeRef, transform, transition, isDragging } = useSortable({
    id: widget.id,
  })

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    gridColumn: `span ${widget.w}`,
    gridRow: `span ${widget.h}`,
    opacity: isDragging ? 0.5 : 1,
    zIndex: isDragging ? 50 : 'auto',
  }

  return (
    <div
      ref={setNodeRef}
      style={style}
      className="group relative flex flex-col overflow-hidden rounded-lg border border-slate-800 bg-slate-900"
    >
      <header className="flex items-center justify-between border-b border-slate-800 bg-slate-950/50 px-3 py-1.5">
        <div className="flex items-center gap-2">
          <button
            {...attributes}
            {...listeners}
            className="cursor-grab active:cursor-grabbing text-slate-600 hover:text-slate-400"
            aria-label="Drag widget"
          >
            ⠿
          </button>
          <h3 className="text-xs font-medium text-slate-400">{widget.title}</h3>
        </div>
        <div className="flex items-center gap-1">
          {onResize && (
            <>
              {widget.w < 4 && (
                <button
                  onClick={() => onResize(widget.id, Math.min(widget.w + 1, 4), widget.h)}
                  className="text-[10px] text-slate-600 hover:text-slate-400"
                >
                  →
                </button>
              )}
              {widget.w > 1 && (
                <button
                  onClick={() => onResize(widget.id, Math.max(widget.w - 1, 1), widget.h)}
                  className="text-[10px] text-slate-600 hover:text-slate-400"
                >
                  ←
                </button>
              )}
            </>
          )}
          {onRemove && (
            <button
              onClick={() => onRemove(widget.id)}
              className="ml-1 text-xs text-slate-600 hover:text-red-400"
            >
              ✕
            </button>
          )}
        </div>
      </header>
      <div className="flex-1 overflow-auto p-3 text-xs text-slate-300">{children}</div>
    </div>
  )
}
