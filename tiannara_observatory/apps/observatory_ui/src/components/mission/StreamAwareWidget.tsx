'use client'

import { useStreamMetrics } from '@/lib/stream'
import type { WidgetConfig } from '@/types'

interface Props {
  widget: WidgetConfig
  children?: React.ReactNode
}

export function StreamAwareWidget({ widget, children }: Props) {
  const { connected, totalEvents, priorityBreakdown, lastEvent } = useStreamMetrics(widget.room)

  return (
    <div className="space-y-2 text-xs">
      <div className="flex items-center gap-2">
        <span className={`inline-block h-1.5 w-1.5 rounded-full ${connected ? 'bg-green-500' : 'bg-red-500'}`} />
        <span className="text-slate-500">{connected ? 'Live' : 'Disconnected'}</span>
        <span className="text-slate-600">{totalEvents} events</span>
      </div>

      {Object.entries(priorityBreakdown).some(([, count]) => count > 0) && (
        <div className="flex gap-2 flex-wrap">
          {Object.entries(priorityBreakdown).map(([key, count]) =>
            count > 0 ? (
              <span key={key} className="text-[10px] text-slate-600">
                {key}: {count}
              </span>
            ) : null
          )}
        </div>
      )}

      {lastEvent && (
        <div className="rounded border border-slate-800 bg-slate-950 p-2 text-[10px] text-slate-500">
          <span className="text-slate-400">{lastEvent.type}</span>
          {' — '}{lastEvent.id?.slice(0, 12)}
        </div>
      )}

      {children}
    </div>
  )
}
