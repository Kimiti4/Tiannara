'use client'

import { IconMissionControl, IconShield, IconRuntime, IconScience, IconEngineering, IconKnowledge, IconTheory, IconPlanetary, IconCivilization, IconEvolution, IconReplay, IconObservationBus, IconSettings, IconCertificate, IconAlert } from '@/components/icons/ObservatoryIcons'
import type { ComponentType, SVGProps } from 'react'

interface NavEntry { slug: string; label: string; icon: ComponentType<SVGProps<SVGSVGElement> & { size?: number }> }

const NAV_ITEMS: NavEntry[] = [
  { slug: 'runtime', label: 'Mission Control', icon: IconMissionControl },
  { slug: 'constitutional', label: 'Constitutional', icon: IconShield },
  { slug: 'runtime', label: 'Runtime', icon: IconRuntime },
  { slug: 'science', label: 'Scientific Discovery', icon: IconScience },
  { slug: 'engineering', label: 'Engineering', icon: IconEngineering },
  { slug: 'knowledge', label: 'Knowledge', icon: IconKnowledge },
  { slug: 'theory', label: 'Theory Ecology', icon: IconTheory },
  { slug: 'planetary', label: 'Planetary', icon: IconPlanetary },
  { slug: 'civilization', label: 'Civilization', icon: IconCivilization },
  { slug: 'evolution', label: 'Evolution', icon: IconEvolution },
  { slug: 'replay', label: 'Archaeology & Replay', icon: IconReplay },
  { slug: 'observation-bus', label: 'Observation Bus', icon: IconObservationBus },
  { slug: 'constitutional-intelligence', label: 'Constitutional Intelligence', icon: IconShield },
  { slug: 'causal-explorer', label: 'Causal Explorer', icon: IconTheory },
  { slug: 'trend-observatory', label: 'Trend Observatory', icon: IconRuntime },
  { slug: 'constitutional-advisor', label: 'Constitutional Advisor', icon: IconCertificate },
  { slug: 'forecast-center', label: 'Forecast Center', icon: IconRuntime },
  { slug: 'scenario-lab', label: 'Scenario Lab', icon: IconTheory },
  { slug: 'risk-observatory', label: 'Risk Observatory', icon: IconAlert },
  { slug: 'preparedness-dashboard', label: 'Preparedness', icon: IconShield },
  { slug: 'epistemic-atlas', label: 'Epistemic Atlas', icon: IconScience },
  { slug: 'unknown-landscape', label: 'Unknown Landscape', icon: IconTheory },
  { slug: 'evidence-explorer', label: 'Evidence Explorer', icon: IconKnowledge },
  { slug: 'contradiction-observatory', label: 'Contradictions', icon: IconAlert },
  { slug: 'active-missions', label: 'Active Missions', icon: IconRuntime },
  { slug: 'mission-galaxy', label: 'Mission Galaxy', icon: IconCivilization },
  { slug: 'scientific-campaign', label: 'Scientific Campaign', icon: IconScience },
  { slug: 'discovery-challenge-center', label: 'Challenge Center', icon: IconCertificate },
  { slug: 'portfolio-view', label: 'Portfolio View', icon: IconEvolution },
  { slug: 'strategy-center', label: 'Strategy Center', icon: IconMissionControl },
  { slug: 'capability-atlas', label: 'Capability Atlas', icon: IconKnowledge },
  { slug: 'technology-roadmaps', label: 'Technology Roadmaps', icon: IconEvolution },
  { slug: 'bottleneck-observatory', label: 'Bottleneck Observatory', icon: IconAlert },
  { slug: 'opportunity-observatory', label: 'Opportunity Observatory', icon: IconScience },
  { slug: 'civilization-control', label: 'Civilization Control', icon: IconCivilization },
  { slug: 'planetary-twin', label: 'Planetary Twin', icon: IconPlanetary },
  { slug: 'civilization-timeline', label: 'Civilization Timeline', icon: IconReplay },
  { slug: 'kardashev-dashboard', label: 'Kardashev Dashboard', icon: IconTheory },
  { slug: 'resilience-center', label: 'Resilience Center', icon: IconShield },
  { slug: 'future-galaxy', label: 'Future Galaxy', icon: IconCivilization },
  { slug: 'counterfactual-studio', label: 'Counterfactual Studio', icon: IconTheory },
  { slug: 'future-comparator', label: 'Future Comparator', icon: IconScience },
  { slug: 'existential-risk-center', label: 'Existential Risk Center', icon: IconAlert },
  { slug: 'meta-observatory', label: 'Meta-Observatory', icon: IconObservationBus },
  { slug: 'instrumentation-explorer', label: 'Instrumentation Explorer', icon: IconScience },
  { slug: 'evolution-center', label: 'Evolution Center', icon: IconEvolution },
  { slug: 'constitutional-governance', label: 'Constitutional Governance', icon: IconShield },
  { slug: 'observatory-genealogy', label: 'Observatory Genealogy', icon: IconReplay },
  { slug: 'operations-command', label: 'Operations Command', icon: IconRuntime },
  { slug: 'execution-timeline', label: 'Execution Timeline', icon: IconReplay },
  { slug: 'resource-command', label: 'Resource Command', icon: IconEvolution },
  { slug: 'safety-center', label: 'Safety Center', icon: IconAlert },
  { slug: 'federation-command', label: 'Federation Command', icon: IconCivilization },
  { slug: 'global-knowledge-map', label: 'Global Knowledge Map', icon: IconKnowledge },
  { slug: 'discovery-federation', label: 'Discovery Federation', icon: IconScience },
  { slug: 'consensus-center', label: 'Consensus Center', icon: IconShield },
  { slug: 'civilization-timeline-federation', label: 'Civ Timeline (Fed)', icon: IconReplay },
]

const QUICK_ACTIONS = [
  'Open Discovery Challenge',
  'Submit Observation',
  'Create Hypothesis',
  'Start Experiment',
  'Run Simulation',
  'Engineering Design',
  'View Replay Timeline',
]

interface Props {
  activeRoom?: string
  collapsed: boolean
  onToggle: () => void
  onNavigate: (slug: string) => void
}

export function LeftSidebar({ activeRoom, collapsed, onToggle, onNavigate }: Props) {
  return (
    <aside
      className={`flex flex-col border-r border-[var(--color-slate-border)] bg-[var(--color-slate-surface)]/60 backdrop-blur-md transition-all duration-200 ${
        collapsed ? 'w-14' : 'w-56'
      }`}
    >
      <button
        onClick={onToggle}
        className="flex h-9 items-center justify-center border-b border-[var(--color-slate-border)] text-[var(--color-slate-muted)] hover:text-[var(--color-slate-secondary)] text-xs"
      >
        {collapsed ? '▶' : '◀'}
      </button>

      <nav className="flex-1 overflow-y-auto py-2 space-y-0.5 px-1">
        {NAV_ITEMS.map((item) => {
          const Icon = item.icon
          const isActive = item.slug === activeRoom
          return (
            <button
              key={`${item.slug}-${item.label}`}
              onClick={() => onNavigate(item.slug)}
              className={`flex w-full items-center gap-2.5 rounded-md px-2.5 py-1.5 text-left text-xs transition-colors ${
                isActive
                  ? 'bg-[var(--color-cyan-bright)]/10 border border-[var(--color-slate-border)] text-[var(--color-cyan-bright)]'
                  : 'text-[var(--color-slate-secondary)] hover:bg-[var(--color-cyan-bright)]/5 hover:text-[var(--color-cyan-bright)]'
              }`}
              title={collapsed ? item.label : undefined}
            >
              <Icon size={16} className="shrink-0" strokeWidth={isActive ? 2 : 1.5} />
              {!collapsed && <span className="truncate">{item.label}</span>}
            </button>
          )
        })}
      </nav>

      {!collapsed && (
        <div className="border-t border-[var(--color-slate-border)] p-2 space-y-1">
          <h3 className="text-[9px] tracking-widest text-[var(--color-slate-muted)] px-2 py-1">QUICK ACTIONS</h3>
          {QUICK_ACTIONS.map((action) => (
            <button
              key={action}
              className="w-full rounded-md border border-[var(--color-slate-border)] bg-[var(--color-cyan-bright)]/5 px-2.5 py-1.5 text-left text-[11px] text-[var(--color-cyan-bright)] hover:bg-[var(--color-cyan-bright)]/10 transition-colors"
            >
              {action}
            </button>
          ))}
        </div>
      )}

      <div className="border-t border-[var(--color-slate-border)] p-2">
        <button
          onClick={() => onNavigate('settings')}
          className={`flex w-full items-center gap-2 rounded-md px-2.5 py-1.5 text-xs text-[var(--color-slate-muted)] hover:bg-[var(--color-cyan-bright)]/5 hover:text-[var(--color-slate-secondary)] transition-colors ${
            collapsed ? 'justify-center' : ''
          }`}
        >
          <IconSettings size={16} />
          {!collapsed && <span>Settings</span>}
        </button>
      </div>
    </aside>
  )
}
