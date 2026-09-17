'use client'

import { ROOMS } from '@/lib/commands'

interface Props {
  activeRoom?: string
  collapsed: boolean
  onToggle: () => void
  onNavigate: (slug: string) => void
}

export function Sidebar({ activeRoom, collapsed, onToggle, onNavigate }: Props) {
  return (
    <aside
      className={`flex flex-col border-r border-slate-800 bg-slate-950 transition-all ${
        collapsed ? 'w-12' : 'w-48'
      }`}
    >
      <button
        onClick={onToggle}
        className="flex h-10 items-center justify-center border-b border-slate-800 text-slate-500 hover:text-slate-300"
      >
        {collapsed ? '▶' : '◀'}
      </button>

      <nav className="flex-1 overflow-y-auto py-2">
        {ROOMS.map((room) => {
          const isActive = room.slug === activeRoom
          return (
            <button
              key={room.slug}
              onClick={() => onNavigate(room.slug)}
              className={`flex w-full items-center gap-2 px-3 py-2 text-left text-sm transition-colors ${
                isActive
                  ? 'border-l-2 border-cyan-400 bg-slate-800 text-cyan-300'
                  : 'border-l-2 border-transparent text-slate-400 hover:bg-slate-800 hover:text-slate-200'
              }`}
              title={collapsed ? room.name : undefined}
            >
              <span className="text-base">{room.icon}</span>
              {!collapsed && (
                <span className="truncate">{room.name}</span>
              )}
            </button>
          )
        })}
      </nav>

      <div className="border-t border-slate-800 p-2">
        <button
          onClick={() => onNavigate('settings')}
          className={`flex w-full items-center gap-2 rounded px-2 py-1.5 text-xs text-slate-500 hover:bg-slate-800 hover:text-slate-300 ${
            collapsed ? 'justify-center' : ''
          }`}
        >
          <span>⚙</span>
          {!collapsed && <span>Settings</span>}
        </button>
      </div>
    </aside>
  )
}
