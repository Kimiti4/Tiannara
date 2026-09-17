import type { MissionLayout, WidgetConfig, MissionMode } from '@/types'

const LAYOUT_KEY = 'obs:layouts'
const MODE_KEY = 'obs:mode'

export const storage = {
  saveLayout: (layout: MissionLayout) => {
    const all = storage.getAllLayouts()
    const idx = all.findIndex((l) => l.id === layout.id)
    if (idx >= 0) all[idx] = layout
    else all.push(layout)
    if (typeof window !== 'undefined') localStorage.setItem(LAYOUT_KEY, JSON.stringify(all))
  },

  getAllLayouts: (): MissionLayout[] => {
    if (typeof window === 'undefined') return []
    try {
      return JSON.parse(localStorage.getItem(LAYOUT_KEY) || '[]')
    } catch {
      return []
    }
  },

  deleteLayout: (id: string) => {
    const all = storage.getAllLayouts().filter((l) => l.id !== id)
    localStorage.setItem(LAYOUT_KEY, JSON.stringify(all))
  },

  saveMode: (mode: MissionMode) => {
    if (typeof window !== 'undefined') localStorage.setItem(MODE_KEY, mode)
  },

  loadMode: (): MissionMode => {
    if (typeof window === 'undefined') return 'laboratory'
    return (localStorage.getItem(MODE_KEY) as MissionMode) || 'laboratory'
  },

  saveWidgets: (room: string, widgets: WidgetConfig[]) => {
    const key = `obs:widgets:${room}`
    localStorage.setItem(key, JSON.stringify(widgets))
  },

  loadWidgets: (room: string): WidgetConfig[] => {
    if (typeof window === 'undefined') return []
    try {
      return JSON.parse(localStorage.getItem(`obs:widgets:${room}`) || '[]')
    } catch {
      return []
    }
  },
}
