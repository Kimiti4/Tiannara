'use client'

import { useState, createContext, useContext } from 'react'
import { LoginScreen } from './LoginScreen'

interface AuthCtx {
  identity: string | null
  login: (i: string) => void
  logout: () => void
}

function loadIdentity(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem('obs:identity')
}

const AuthContext = createContext<AuthCtx>({ identity: null, login: () => {}, logout: () => {} })

export const useAuth = () => useContext(AuthContext)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [identity, setIdentity] = useState<string | null>(loadIdentity)

  const login = (id: string) => {
    setIdentity(id)
    localStorage.setItem('obs:identity', id)
  }

  const logout = () => {
    setIdentity(null)
    localStorage.removeItem('obs:identity')
  }

  if (!identity) {
    return <LoginScreen onLogin={login} />
  }

  return <AuthContext.Provider value={{ identity, login, logout }}>{children}</AuthContext.Provider>
}
