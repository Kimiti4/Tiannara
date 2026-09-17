'use client'

import { createContext, useContext, useState, useCallback } from 'react'

interface Session {
  identity: string
  loginTime: string
  lastActivity: string
  activeRoom: string | null
}

interface SessionCtx {
  session: Session | null
  updateActivity: (room?: string) => void
  clearSession: () => void
}

function loadSession(): Session | null {
  if (typeof window === 'undefined') return null
  try {
    const raw = localStorage.getItem('obs:session')
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

const SessionContext = createContext<SessionCtx>({
  session: null,
  updateActivity: () => {},
  clearSession: () => {},
})

export const useSession = () => useContext(SessionContext)

export function SessionProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(loadSession)

  const updateActivity = useCallback((room?: string) => {
    setSession((prev) => {
      if (!prev) return prev
      const next = { ...prev, lastActivity: new Date().toISOString(), activeRoom: room ?? prev.activeRoom }
      localStorage.setItem('obs:session', JSON.stringify(next))
      return next
    })
  }, [])

  const clearSession = useCallback(() => {
    setSession(null)
    localStorage.removeItem('obs:session')
  }, [])

  return <SessionContext.Provider value={{ session, updateActivity, clearSession }}>{children}</SessionContext.Provider>
}
