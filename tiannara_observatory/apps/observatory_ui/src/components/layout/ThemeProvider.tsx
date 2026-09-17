'use client'

import { createContext, useContext } from 'react'

type Theme = 'dark'

interface ThemeCtx {
  theme: Theme
}

const ThemeContext = createContext<ThemeCtx>({ theme: 'dark' })

export const useTheme = () => useContext(ThemeContext)

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return <ThemeContext.Provider value={{ theme: 'dark' }}>{children}</ThemeContext.Provider>
}
