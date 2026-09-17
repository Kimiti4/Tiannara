'use client'

import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react'
import { apiClient, UserProfile } from '@/lib/api'
import { useRouter } from 'next/navigation'

interface AuthContextType {
  user: UserProfile | null
  isLoading: boolean
  isAuthenticated: boolean
  login: (email: string, password: string) => Promise<void>
  signup: (name: string, email: string, password: string) => Promise<void>
  logout: () => void
  refreshProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserProfile | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()
  const inactivityTimeout = 30 * 60 * 1000 // 30 minutes in milliseconds
  let inactivityTimer: NodeJS.Timeout | null = null

  // Check for existing session on mount
  useEffect(() => {
    checkAuth()
    return () => {
      if (inactivityTimer) {
        clearTimeout(inactivityTimer)
      }
    }
  }, [])

  // Reset inactivity timer on user activity
  useEffect(() => {
    if (!user) return

    const resetTimer = () => {
      if (inactivityTimer) {
        clearTimeout(inactivityTimer)
      }
      inactivityTimer = setTimeout(() => {
        console.log('Auto-logout due to inactivity')
        logout()
      }, inactivityTimeout)
    }

    // List of events to track for activity
    const events = ['mousedown', 'keydown', 'scroll', 'touchstart']
    
    // Add event listeners
    events.forEach(event => {
      window.addEventListener(event, resetTimer)
    })

    // Initial timer setup
    resetTimer()

    // Cleanup
    return () => {
      events.forEach(event => {
        window.removeEventListener(event, resetTimer)
      })
      if (inactivityTimer) {
        clearTimeout(inactivityTimer)
      }
    }
  }, [user])

  const checkAuth = async () => {
    try {
      const response = await apiClient.getProfile()
      const profile = (response.data as { user?: UserProfile })?.user ?? response.data
      if (response.success && profile) {
        setUser(profile as UserProfile)
      } else {
        apiClient.clearToken()
      }
    } catch (error) {
      console.error('Auth check failed:', error)
      apiClient.clearToken()
    }
    setIsLoading(false)
  }

  const login = async (email: string, password: string) => {
    setIsLoading(true)
    try {
      const response = await apiClient.login(email, password)
      
      if (response.success && response.data) {
        const user = response.data.user
        if (!user) {
          throw new Error('No user profile received from server')
        }
        setUser(user)
        router.push('/dashboard')
      } else {
        console.error('Login failed:', response.error)
        throw new Error(response.error || 'Login failed')
      }
    } catch (error) {
      console.error('Login error:', error)
      throw error
    } finally {
      setIsLoading(false)
    }
  }

  const signup = async (name: string, email: string, password: string) => {
    setIsLoading(true)
    try {
      const response = await apiClient.signup(name, email, password)
      
      if (response.success && response.data?.user) {
        setUser(response.data.user)
        router.push('/dashboard')
      } else {
        throw new Error(response.error || 'Signup failed')
      }
    } catch (error) {
      console.error('Signup error:', error)
      throw error
    } finally {
      setIsLoading(false)
    }
  }

  const logout = async () => {
    try {
      await apiClient.logout()
    } catch {
      apiClient.clearToken()
    }
    setUser(null)
    router.push('/login')
  }

  const refreshProfile = async () => {
    try {
      const response = await apiClient.getProfile()
      const profile = (response.data as { user?: UserProfile })?.user ?? response.data
      if (response.success && profile) {
        setUser(profile as UserProfile)
      }
    } catch (error) {
      console.error('Failed to refresh profile:', error)
    }
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        login,
        signup,
        logout,
        refreshProfile,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
