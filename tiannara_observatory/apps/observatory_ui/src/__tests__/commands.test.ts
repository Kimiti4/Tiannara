import { describe, it, expect } from 'vitest'
import { ROOMS, buildCommands } from '@/lib/commands'

describe('commands', () => {
  it('has 10 mission rooms', () => {
    expect(ROOMS).toHaveLength(10)
    expect(ROOMS.map((r) => r.slug)).toContain('runtime')
    expect(ROOMS.map((r) => r.slug)).toContain('replay')
  })

  it('builds navigation commands', () => {
    let called = ''
    const navigate = (s: string) => { called = s }
    const cmds = buildCommands(navigate)
    const navCmds = cmds.filter((c) => c.category === 'Navigation')
    expect(navCmds.length).toBeGreaterThanOrEqual(10)

    const runtimeCmd = navCmds.find((c) => c.id === 'nav-runtime')
    expect(runtimeCmd).toBeDefined()
    runtimeCmd!.action()
    expect(called).toBe('runtime')
  })
})
