'use client'

import { useRoomStream } from '@/lib/stream'
import { DataPanel, MetricRow, StatBox, HealthBar } from './DataPanel'
import { UptimeSparkline, DiscoveryChart, PipelineDoughnut, ProgressTimeline } from '@/components/charts/ObservatoryCharts'

const UPTIME_DATA: { day: string; value: number }[] = []
const DISCOVERY_DATA: { label: string; discoveries: number; validations: number; principles: number }[] = []
const PIPELINE_DATA: { label: string; value: number; color: string }[] = []
const PROGRESS_DATA: { label: string; value: number }[] = []

export function FullDashboard() {
  const { connected } = useRoomStream('control')

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-2.5 p-3 auto-rows-min overflow-y-auto h-full">
      {/* 1. Constitutional */}
      <DataPanel title="1. CONSTITUTIONAL OBSERVATORY" className="xl:col-span-1">
        <div className="flex items-center gap-4">
          <div className="shrink-0 w-20 h-20 rounded-full border-2 border-[var(--color-emerald-bright)] flex items-center justify-center">
            <span className="font-mono text-2xl font-bold text-[var(--color-emerald-bright)]">MEASURED</span>
          </div>
          <div className="flex-1 space-y-1">
            <MetricRow label="Governance Compliance" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
            <MetricRow label="Policy Adherence" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
            <MetricRow label="Audit Trail Integrity" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
            <MetricRow label="Unknown Preservation" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
          </div>
        </div>
        <div className="mt-2">
          <span className="inline-block rounded-md border border-[var(--color-emerald-bright)] bg-[var(--color-emerald-bright)]/10 px-3 py-1 text-[10px] font-semibold tracking-wider text-[var(--color-emerald-bright)]">VALID</span>
        </div>
      </DataPanel>

      {/* 2. Runtime */}
      <DataPanel title="2. RUNTIME OBSERVATORY" className="xl:col-span-1">
        <div className="flex gap-2 mb-2">
          <StatBox label="UPTIME" value="LIVE" />
          <StatBox label="REPLAY INTEGRITY" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
        </div>
        <UptimeSparkline data={UPTIME_DATA} />
        <div className="grid grid-cols-2 gap-1">
          <MetricRow label="Checkpoints Today" value="—" />
          <MetricRow label="Recovery Success" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Events Processed" value="—" />
          <MetricRow label="Active Workers" value="—" />
          <MetricRow label="Queue Depth (max)" value="—" />
          <MetricRow label="Memory Growth" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
        </div>
        <div className="flex items-center gap-1.5 mt-1">
          <span className={`inline-block h-1.5 w-1.5 rounded-full ${connected ? 'bg-[var(--color-emerald-bright)]' : 'bg-[var(--color-rose-bright)]'}`} />
          <span className="text-[10px] text-[var(--color-slate-muted)]">{connected ? 'LIVE' : 'OFFLINE'}</span>
        </div>
      </DataPanel>

      {/* 3. Scientific Discovery */}
      <DataPanel title="3. SCIENTIFIC DISCOVERY" className="xl:col-span-1">
        <div className="space-y-1">
          <MetricRow label="Active Hypotheses" value="—" />
          <MetricRow label="Hypotheses Tested" value="—" />
          <MetricRow label="Hypotheses Validated" value="—" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Experiments Running" value="—" />
          <MetricRow label="Simulations Running" value="—" />
          <MetricRow label="New Discoveries (7d)" value="—" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Knowledge Growth (7d)" value="+MEASURED" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Scientific ROI (7d)" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
        </div>
        <DiscoveryChart data={DISCOVERY_DATA} />
      </DataPanel>

      {/* 4. Engineering */}
      <DataPanel title="4. ENGINEERING OBSERVATORY" className="xl:col-span-1">
        <div className="grid grid-cols-2 gap-2">
          <div className="space-y-1">
            <MetricRow label="Active Programs" value="—" />
            <MetricRow label="Active Designs" value="—" />
            <MetricRow label="Designs Verified" value="—" />
            <MetricRow label="Optimizations (7d)" value="—" />
            <MetricRow label="Tech Readiness (avg)" value="MEASURED" />
          </div>
          <div>
            <h3 className="text-[10px] tracking-wider text-[var(--color-slate-muted)] mb-1">PIPELINE</h3>
            <PipelineDoughnut data={PIPELINE_DATA} />
            <div className="flex flex-wrap gap-1.5 mt-1">
              <span className="flex items-center gap-1 text-[9px] text-[var(--color-slate-secondary)]"><span className="inline-block w-2 h-2 rounded-full bg-[var(--color-cyan-bright)]" />Design</span>
              <span className="flex items-center gap-1 text-[9px] text-[var(--color-slate-secondary)]"><span className="inline-block w-2 h-2 rounded-full bg-[var(--color-violet-bright)]" />Verification</span>
              <span className="flex items-center gap-1 text-[9px] text-[var(--color-slate-secondary)]"><span className="inline-block w-2 h-2 rounded-full bg-[var(--color-emerald-bright)]" />Optimization</span>
            </div>
          </div>
        </div>
      </DataPanel>

      {/* 5. Knowledge */}
      <DataPanel title="5. KNOWLEDGE OBSERVATORY" className="xl:col-span-1">
        <div className="space-y-1">
          <MetricRow label="Total Concepts" value="—" />
          <MetricRow label="Relationships" value="—" />
          <MetricRow label="Theories" value="—" />
          <MetricRow label="Principles" value="—" />
          <MetricRow label="Models" value="9,—" />
          <MetricRow label="Knowledge Density" value="0.78" />
          <MetricRow label="Compression Ratio" value="12.6x" />
          <MetricRow label="Domain Coverage" value="MEASURED" color="text-[var(--color-emerald-bright)]" />
        </div>
      </DataPanel>

      {/* 6. Planetary */}
      <DataPanel title="7. PLANETARY OBSERVATORY" className="xl:col-span-1">
        <h3 className="text-[11px] font-semibold text-[var(--color-amber-bright)] mb-2">PLANETARY HEALTH — MEASURED</h3>
        <div className="space-y-1">
          <HealthBar label="Climate Stability" value={78.2} />
          <HealthBar label="Water Resources" value={82.1} />
          <HealthBar label="Food Security" value={85.7} />
          <HealthBar label="Energy Stability" value={88.3} />
          <HealthBar label="Biodiversity" value={76.4} />
          <HealthBar label="Infrastructure" value={89.1} />
        </div>
        <div className="mt-2 inline-block rounded-md border border-[var(--color-amber-bright)] bg-[var(--color-amber-bright)]/10 px-2 py-0.5 text-[10px] font-semibold text-[var(--color-amber-bright)]">MODERATE</div>
      </DataPanel>

      {/* 7. Civilization */}
      <DataPanel title="8. CIVILIZATIONAL OBSERVATORY" className="xl:col-span-1">
        <h3 className="text-[11px] font-semibold text-[var(--color-cyan-bright)] mb-2">INNOVATION INDEX — MEASURED</h3>
        <div className="grid grid-cols-2 gap-1">
          <MetricRow label="Scientific Capacity" value="70.3%" />
          <MetricRow label="Engineering Capacity" value="74.8%" />
          <MetricRow label="Infrastructure Growth" value="68.9%" />
          <MetricRow label="Education Capacity" value="69.1%" />
          <MetricRow label="Healthcare Capacity" value="71.3%" />
          <MetricRow label="Sustainability" value="66.7%" />
          <MetricRow label="Space Capability" value="65.4%" />
          <MetricRow label="Kardashev Progress" value="0.72" />
        </div>
        <ProgressTimeline data={PROGRESS_DATA} />
      </DataPanel>

      {/* 8. Evolution */}
      <DataPanel title="9. EVOLUTION OBSERVATORY" className="xl:col-span-1">
        <div className="space-y-1">
          <MetricRow label="Runtime Generations" value="37" />
          <MetricRow label="Improvements Proposed" value="542" />
          <MetricRow label="Improvements Validated" value="321" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Improvements Deployed" value="287" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Regression Rate" value="0.23%" color="text-[var(--color-amber-bright)]" />
          <MetricRow label="Improvement Velocity (7d)" value="+14.6%" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Self-Modification Events" value="1,872" />
        </div>
        <div className="flex gap-2 mt-2">
          {['Gen 33', 'Gen 34', 'Gen 35', 'Gen 36', 'Gen 37'].map((g) => (
            <div key={g} className="flex-1 flex flex-col items-center gap-1 text-center">
              <span className="text-[9px] font-mono text-[var(--color-slate-muted)]">{g}</span>
              <span className="inline-flex h-4 w-4 items-center justify-center rounded-full bg-[var(--color-emerald-bright)]/20 border border-[var(--color-emerald-bright)] text-[8px] text-[var(--color-emerald-bright)]">✓</span>
              <span className="text-[8px] text-[var(--color-slate-secondary)] leading-tight">Improvement</span>
            </div>
          ))}
        </div>
      </DataPanel>

      {/* 9. Certification */}
      <DataPanel title="CERTIFICATION OBSERVATORY" className="xl:col-span-1">
        <div className="space-y-1">
          <MetricRow label="Campaigns" value="48" />
          <MetricRow label="Evidence Items" value="12,847" />
          <MetricRow label="Readiness Level" value="L5" color="text-[var(--color-amber-bright)]" />
          <MetricRow label="Certifications Issued" value="—" color="text-[var(--color-emerald-bright)]" />
          <MetricRow label="Active Reviews" value="27" />
          <MetricRow label="Avg. Time to Certify" value="3.2d" />
        </div>
      </DataPanel>

      {/* 10. Archaeology & Replay */}
      <DataPanel title="10. ARCHAEOLOGY & REPLAY" className="xl:col-span-1">
        <div className="mb-2">
          <div className="flex justify-between text-[9px] font-mono text-[var(--color-slate-muted)] mb-1">
            <span>2025-02-01</span><span>2025-03-01</span><span>2025-04-01</span><span>2025-05-01</span><span>Today</span>
          </div>
          <input type="range" defaultValue={85} className="w-full h-1 rounded-full appearance-none bg-white/10 outline-none [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:w-3 [&::-webkit-slider-thumb]:h-3 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-[var(--color-cyan-bright)] [&::-webkit-slider-thumb]:shadow-[0_0_8px_var(--color-cyan-glow)] [&::-webkit-slider-thumb]:cursor-pointer" />
        </div>
        <div className="rounded-md border border-[var(--color-slate-border)] bg-[var(--color-cyan-bright)]/5 p-2 mb-2">
          <div className="text-[9px] tracking-wider text-[var(--color-slate-muted)]">SELECTED POINT</div>
          <div className="font-mono text-[11px] text-[var(--color-cyan-bright)]">2025-05-28 14:37:42 UTC</div>
          <div className="flex gap-3 mt-1">
            <span className="text-[10px] text-[var(--color-emerald-bright)]">Replay Ready</span>
            <span className="text-[10px] text-[var(--color-emerald-bright)]">MEASURED Integrity</span>
          </div>
        </div>
        <div className="flex gap-1.5">
          {['⟲ Replay', '⏩ Fast Forward', 'Step Through'].map((label) => (
            <button key={label} className="flex-1 rounded-md border border-[var(--color-slate-border)] bg-[var(--color-cyan-bright)]/5 px-2 py-1 text-[10px] text-[var(--color-cyan-bright)] hover:bg-[var(--color-cyan-bright)]/10 transition-colors">
              {label}
            </button>
          ))}
        </div>
      </DataPanel>
    </div>
  )
}
