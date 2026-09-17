const BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api/v1'

async function fetchJson<T>(path: string, opts?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    headers: { 'Content-Type': 'application/json', ...opts?.headers },
    ...opts,
  })
  if (!res.ok) throw new Error(`API ${res.status}: ${res.statusText}`)
  return res.json()
}

export const api = {
  status: () => fetchJson<{ status: string; uptime: number; constitution_version: string; api_version: string; subsystems: Record<string, unknown> }>('/status'),

  runtime: {
    health: () => fetchJson<Record<string, unknown>>('/runtime/health'),
    metrics: () => fetchJson<Record<string, unknown>>('/runtime/metrics'),
  },

  events: {
    list: (domain?: string, limit = 100) =>
      fetchJson<Record<string, unknown>[]>(`/events${domain ? `?domain=${domain}` : ''}&limit=${limit}`),
    get: (id: string) => fetchJson<Record<string, unknown>>(`/events/${id}`),
  },

  metrics: {
    list: () => fetchJson<Record<string, unknown>[]>('/metrics'),
    get: (name: string) => fetchJson<Record<string, unknown>>(`/metrics/${name}`),
    trend: (name: string) => fetchJson<Record<string, unknown>>(`/metrics/${name}/trend`),
    forecast: (name: string) => fetchJson<Record<string, unknown>>(`/metrics/${name}/forecast`),
    query: (name: string, since?: string, until?: string) => {
      const params = new URLSearchParams({ name })
      if (since) params.set('since', since)
      if (until) params.set('until', until)
      return fetchJson<Record<string, unknown>[]>(`/metrics/query?${params}`)
    },
  },

  replay: {
    reconstruct: (timestamp?: string, domain?: string) => {
      const params = new URLSearchParams()
      if (timestamp) params.set('timestamp', timestamp)
      if (domain) params.set('domain', domain)
      return fetchJson<Record<string, unknown>>(`/replay?${params}`)
    },
    compare: (since: string, until: string, domain?: string) => {
      const params = new URLSearchParams({ since, until })
      if (domain) params.set('domain', domain)
      return fetchJson<Record<string, unknown>[]>(`/replay/compare?${params}`)
    },
    timeline: (domain: string) => fetchJson<Record<string, unknown>[]>(`/replay/timeline?domain=${domain}`),
    snapshots: (domain: string) => fetchJson<Record<string, unknown>[]>(`/replay/snapshots?domain=${domain}`),
    archaeology: (eventId: string) => fetchJson<Record<string, unknown>>(`/replay/archaeology?event_id=${eventId}`),
    divergence: () => fetchJson<Record<string, unknown>>('/replay/divergence'),
  },

  state: {
    science: () => fetchJson<Record<string, unknown>>('/science'),
    engineering: () => fetchJson<Record<string, unknown>>('/engineering'),
    knowledge: () => fetchJson<Record<string, unknown>>('/knowledge'),
    planetary: () => fetchJson<Record<string, unknown>>('/planetary'),
    civilization: () => fetchJson<Record<string, unknown>>('/civilization'),
    evolution: () => fetchJson<Record<string, unknown>>('/evolution'),
    governance: () => fetchJson<Record<string, unknown>>('/governance'),
    certification: () => fetchJson<Record<string, unknown>>('/certification'),
  },

  cil: {
    health: () => fetchJson<Record<string, unknown>>('/cil/health'),
    patterns: () => fetchJson<{ patterns: Record<string, unknown>[] }>('/cil/patterns'),
    trends: () => fetchJson<Record<string, unknown>>('/cil/trends'),
    recommendations: () => fetchJson<{ recommendations: Record<string, unknown>[] }>('/cil/recommendations'),
    syntheses: () => fetchJson<{ syntheses: Record<string, unknown>[] }>('/cil/syntheses'),
    risk: () => fetchJson<Record<string, unknown>>('/cil/risk'),
    causal: (id: string) => fetchJson<Record<string, unknown>>(`/cil/causal/${id}`),
    report: () => fetchJson<Record<string, unknown>>('/cil/report'),
  },

  cpo: {
    forecasts: () => fetchJson<{ forecasts: Record<string, unknown>[] }>('/cpo/forecasts'),
    scenarios: () => fetchJson<Record<string, unknown>>('/cpo/scenarios'),
    riskProjections: () => fetchJson<{ risk_projections: Record<string, unknown>[] }>('/cpo/risk-projections'),
    capacity: () => fetchJson<Record<string, unknown>>('/cpo/capacity'),
    missionForecasts: () => fetchJson<Record<string, unknown>>('/cpo/mission-forecasts'),
    preparedness: () => fetchJson<Record<string, unknown>>('/cpo/preparedness'),
  },

  epistemic: {
    summary: () => fetchJson<Record<string, unknown>>('/epistemic/summary'),
    confidence: () => fetchJson<{ confidence: Record<string, unknown>[] }>('/epistemic/confidence'),
    evidence: () => fetchJson<Record<string, unknown>>('/epistemic/evidence'),
    unknowns: () => fetchJson<{ unknowns: Record<string, unknown>[]; counts: Record<string, unknown> }>('/epistemic/unknowns'),
    contradictions: () => fetchJson<{ contradictions: Record<string, unknown>[] }>('/epistemic/contradictions'),
    assumptions: () => fetchJson<{ assumptions: Record<string, unknown>[] }>('/epistemic/assumptions'),
    bias: () => fetchJson<{ readings: Record<string, unknown>[]; index: number }>('/epistemic/bias'),
  },

  mission: {
    list: () => fetchJson<{ missions: Record<string, unknown>[] }>('/mission/missions'),
    scheduler: () => fetchJson<Record<string, unknown>>('/mission/scheduler'),
    analytics: () => fetchJson<Record<string, unknown>>('/mission/analytics'),
    portfolio: () => fetchJson<Record<string, unknown>>('/mission/portfolio'),
    timeline: () => fetchJson<{ timeline: Record<string, unknown>[] }>('/mission/timeline'),
    health: (id: string) => fetchJson<Record<string, unknown>>(`/mission/health/${id}`),
  },

  strategy: {
    plans: () => fetchJson<Record<string, unknown>>('/strategy/plans'),
    plan: (horizon: string) => fetchJson<Record<string, unknown>>(`/strategy/plans/${horizon}`),
    capabilities: () => fetchJson<{ capabilities: Record<string, unknown> }>('/strategy/capabilities'),
    capability: (id: string) => fetchJson<Record<string, unknown>>(`/strategy/capabilities/${id}`),
    capabilityDependencies: (id: string) => fetchJson<{ dependencies: Record<string, unknown>[] }>(`/strategy/capabilities/${id}/dependencies`),
    technologies: () => fetchJson<{ technologies: Record<string, unknown> }>('/strategy/technologies'),
    resources: () => fetchJson<Record<string, unknown>>('/strategy/resources'),
    resourceOptimization: () => fetchJson<Record<string, unknown>>('/strategy/resources/optimization'),
    bottlenecks: () => fetchJson<{ bottlenecks: Record<string, unknown>[]; rankings: Record<string, unknown> }>('/strategy/bottlenecks'),
    opportunities: () => fetchJson<{ opportunities: Record<string, unknown>[]; pipeline: Record<string, unknown> }>('/strategy/opportunities'),
    risks: () => fetchJson<{ risks: Record<string, unknown>[]; summary: Record<string, unknown> }>('/strategy/risks'),
  },

  civilization: {
    state: () => fetchJson<Record<string, unknown>>('/civilization/state'),
    diffusion: () => fetchJson<{ technologies: Record<string, unknown> }>('/civilization/diffusion'),
    infrastructure: () => fetchJson<Record<string, unknown>>('/civilization/infrastructure'),
    economy: () => fetchJson<Record<string, unknown>>('/civilization/economy'),
    society: () => fetchJson<Record<string, unknown>>('/civilization/society'),
    resilience: () => fetchJson<Record<string, unknown>>('/civilization/resilience'),
    kardashev: () => fetchJson<{ status: Record<string, unknown>; projection: Record<string, unknown> }>('/civilization/kardashev'),
  },

  futures: {
    list: () => fetchJson<{ futures: Record<string, unknown>[] }>('/futures/list'),
    counterfactuals: () => fetchJson<{ counterfactuals: Record<string, unknown>[] }>('/futures/counterfactuals'),
    tree: () => fetchJson<{ tree: Record<string, unknown>; total_branches: number }>('/futures/tree'),
    rankings: () => fetchJson<{ rankings: [string, Record<string, unknown>][] }>('/futures/rankings'),
    compare: (a: string, b: string) => fetchJson<Record<string, unknown>>(`/futures/compare?a=${a}&b=${b}`),
    opportunities: () => fetchJson<{ opportunities: Record<string, unknown>[]; leverage_points: Record<string, unknown>[] }>('/futures/opportunities'),
    existentialRisks: () => fetchJson<{ risks: Record<string, unknown>[]; summary: Record<string, unknown> }>('/futures/existential-risks'),
    simulations: () => fetchJson<{ simulations: Record<string, unknown>[] }>('/futures/simulations'),
  },

  meta: {
    status: () => fetchJson<Record<string, unknown>>('/meta/status'),
    blindSpots: () => fetchJson<{ blind_spots: string[] }>('/meta/blind-spots'),
    instrumentation: () => fetchJson<{ proposals: Record<string, unknown>[] }>('/meta/instrumentation'),
    architecture: () => fetchJson<{ proposals: Record<string, unknown>[] }>('/meta/architecture'),
    governance: () => fetchJson<{ proposals: Record<string, unknown>[]; audit_log: Record<string, unknown>[] }>('/meta/governance'),
    immune: () => fetchJson<Record<string, unknown>>('/meta/immune'),
    certification: () => fetchJson<{ scores: Record<string, unknown> }>('/meta/certification'),
    lineage: () => fetchJson<{ versions: Record<string, unknown>[]; current: string }>('/meta/lineage'),
  },

  ops: {
    plans: () => fetchJson<Record<string, unknown>>('/ops/plans'),
    execution: () => fetchJson<Record<string, unknown>>('/ops/execution'),
    resources: () => fetchJson<Record<string, unknown>>('/ops/resources'),
    authorizations: () => fetchJson<{ authorizations: Record<string, unknown>[] }>('/ops/authorizations'),
    safety: () => fetchJson<Record<string, unknown>>('/ops/safety'),
    recovery: () => fetchJson<Record<string, unknown>>('/ops/recovery'),
    replay: () => fetchJson<{ events: Record<string, unknown>[] }>('/ops/replay'),
  },

  federation: {
    nodes: () => fetchJson<{ nodes: Record<string, unknown>[] }>('/federation/nodes'),
    exchanges: () => fetchJson<{ exchanges: Record<string, unknown>[]; stats: Record<string, unknown> }>('/federation/exchanges'),
    consensus: () => fetchJson<{ proposals: Record<string, unknown>[] }>('/federation/consensus'),
    members: () => fetchJson<{ members: Record<string, unknown>[]; stats: Record<string, unknown> }>('/federation/members'),
    replay: () => fetchJson<{ events: Record<string, unknown>[] }>('/federation/replay'),
    memory: () => fetchJson<Record<string, unknown>>('/federation/memory'),
    trust: () => fetchJson<{ trust_graph: Record<string, unknown>[] }>('/federation/trust'),
  },
}
