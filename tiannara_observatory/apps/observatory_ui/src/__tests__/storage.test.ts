import { describe, it, expect, beforeEach } from 'vitest'
import { storage } from '@/lib/storage'
import type { MissionLayout, WidgetConfig } from '@/types'

beforeEach(() => {
  localStorage.clear()
})

describe('storage', () => {
  it('saves and loads widgets per room', () => {
    const widgets: WidgetConfig[] = [
      { id: 'w1', type: 'health', title: 'Health', room: 'runtime', x: 0, y: 0, w: 1, h: 1 },
    ]
    storage.saveWidgets('runtime', widgets)
    const loaded = storage.loadWidgets('runtime')
    expect(loaded).toEqual(widgets)
    expect(storage.loadWidgets('science')).toEqual([])
  })

  it('saves and loads layouts', () => {
    const layout: MissionLayout = {
      id: 'l1',
      name: 'Test Layout',
      mode: 'laboratory',
      widgets: [],
      createdAt: '2025-01-01T00:00:00Z',
      updatedAt: '2025-01-01T00:00:00Z',
    }
    storage.saveLayout(layout)
    const all = storage.getAllLayouts()
    expect(all).toHaveLength(1)
    expect(all[0].name).toBe('Test Layout')
  })

  it('deletes layouts', () => {
    const layout: MissionLayout = {
      id: 'l1',
      name: 'To Delete',
      mode: 'laboratory',
      widgets: [],
      createdAt: '',
      updatedAt: '',
    }
    storage.saveLayout(layout)
    storage.deleteLayout('l1')
    expect(storage.getAllLayouts()).toHaveLength(0)
  })

  it('saves and loads mission mode', () => {
    storage.saveMode('emergency')
    expect(storage.loadMode()).toBe('emergency')
    storage.saveMode('laboratory')
    expect(storage.loadMode()).toBe('laboratory')
  })
})
