'use client'

import { useState } from 'react'
import { Search, ExternalLink, Loader2, ShieldCheck, FlaskConical } from 'lucide-react'

type Source = { title: string; url: string; snippet?: string; text?: string; fetched?: boolean }

export default function ResearchPage() {
  const [query, setQuery] = useState('')
  const [sources, setSources] = useState<Source[]>([])
  const [analysis, setAnalysis] = useState<any>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function runResearch(e: React.FormEvent) {
    e.preventDefault()
    if (!query.trim()) return
    setLoading(true); setError('')
    try {
      const res = await fetch('/api/v1/chat/research', {
        method: 'POST',
        credentials: 'include',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ query, num_results: 6, fetch_sources: true })
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.detail || 'Research request failed')
      setSources(data.sources || [])
      setAnalysis(data.analysis)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Research request failed')
    } finally { setLoading(false) }
  }

  return (
    <div className="tiannara-grid min-h-full max-w-[1500px] mx-auto p-8">
      <div className="mb-8">
        <p className="text-xs uppercase tracking-[0.25em] text-cyan-300/80 mb-2">Independent Research</p>
        <h1 className="text-3xl font-bold text-white">Research Laboratory</h1>
        <p className="mt-2 max-w-3xl text-slate-400">Search the live web, preserve source provenance, and ask Tiannara to analyze the evidence. External sources remain distinguishable from Tiannara conclusions.</p>
      </div>
      <form onSubmit={runResearch} className="tiannara-panel rounded-2xl p-5 mb-6">
        <div className="flex gap-3">
          <Search className="w-5 h-5 text-cyan-300 mt-3" />
          <input value={query} onChange={e=>setQuery(e.target.value)} placeholder="Ask a research question…" className="flex-1 bg-transparent outline-none text-white placeholder-slate-500 text-lg" />
          <button disabled={loading} className="rounded-xl bg-gradient-to-r from-violet-600 to-cyan-600 px-5 py-2 font-medium text-white disabled:opacity-50">{loading ? <Loader2 className="w-5 h-5 animate-spin"/> : 'Research'}</button>
        </div>
      </form>
      {error && <div className="mb-6 rounded-xl border border-red-500/20 bg-red-500/10 p-4 text-red-300">{error}</div>}
      {analysis && <section className="tiannara-panel rounded-2xl p-6 mb-6"><div className="flex items-center gap-2 mb-3"><FlaskConical className="w-5 h-5 text-violet-300"/><h2 className="font-semibold text-white">Tiannara analysis</h2></div><pre className="whitespace-pre-wrap text-sm leading-6 text-slate-300">{JSON.stringify(analysis, null, 2)}</pre></section>}
      <div className="flex items-center gap-2 mb-4 text-xs text-slate-500"><ShieldCheck className="w-4 h-4 text-emerald-400"/> Sources are evidence candidates; verify important claims independently.</div>
      <section className="grid gap-4 md:grid-cols-2">
        {sources.map((s,i)=><article key={s.url || i} className="tiannara-panel rounded-2xl p-5"><div className="flex justify-between gap-4"><h3 className="font-medium text-white">{s.title || 'Untitled source'}</h3>{s.url && <a href={s.url} target="_blank" rel="noreferrer" className="text-cyan-300"><ExternalLink className="w-4 h-4"/></a>}</div><p className="mt-2 text-sm text-slate-400">{s.text || s.snippet || 'No extractable text.'}</p><p className="mt-3 text-xs text-slate-600 break-all">{s.url}</p></article>)}
      </section>
    </div>
  )
}
