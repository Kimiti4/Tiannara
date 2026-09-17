'use client'

import { useState } from 'react'

interface Props {
  onLogin: (identity: string) => void
}

export function LoginScreen({ onLogin }: Props) {
  const [identity, setIdentity] = useState('')
  const [password, setPassword] = useState('')

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-950">
      <form
        onSubmit={(e) => { e.preventDefault(); onLogin(identity) }}
        className="w-full max-w-sm rounded-lg border border-slate-800 bg-slate-900 p-8"
      >
        <h1 className="mb-2 text-center text-lg font-bold text-cyan-400">◇ Mission Control</h1>
        <p className="mb-6 text-center text-xs text-slate-500">Constitutional Observatory Core</p>

        <label className="mb-1 block text-xs text-slate-400">Operator Identity</label>
        <input
          value={identity}
          onChange={(e) => setIdentity(e.target.value)}
          className="mb-4 w-full rounded border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-200 placeholder:text-slate-600"
          placeholder="e.g. commander-leela"
        />

        <label className="mb-1 block text-xs text-slate-400">Passphrase</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mb-6 w-full rounded border border-slate-700 bg-slate-950 px-3 py-2 text-sm text-slate-200 placeholder:text-slate-600"
          placeholder="••••••••"
        />

        <button
          type="submit"
          className="w-full rounded bg-cyan-600 py-2 text-sm font-medium text-white hover:bg-cyan-500"
        >
          Authenticate
        </button>
      </form>
    </div>
  )
}
