'use client'

import { lazy, Suspense } from 'react'

const RuntimeRoom = lazy(() => import('./RuntimeRoom').then((m) => ({ default: m.RuntimeRoom })))
const ScienceRoom = lazy(() => import('./ScienceRoom').then((m) => ({ default: m.ScienceRoom })))
const EngineeringRoom = lazy(() => import('./EngineeringRoom').then((m) => ({ default: m.EngineeringRoom })))
const KnowledgeRoom = lazy(() => import('./KnowledgeRoom').then((m) => ({ default: m.KnowledgeRoom })))
const EvolutionRoom = lazy(() => import('./EvolutionRoom').then((m) => ({ default: m.EvolutionRoom })))
const CertificationRoom = lazy(() => import('./CertificationRoom').then((m) => ({ default: m.CertificationRoom })))
const PlanetaryRoom = lazy(() => import('./PlanetaryRoom').then((m) => ({ default: m.PlanetaryRoom })))
const CivilizationRoom = lazy(() => import('./CivilizationRoom').then((m) => ({ default: m.CivilizationRoom })))
const ReplayRoom = lazy(() => import('./ReplayRoom').then((m) => ({ default: m.ReplayRoom })))
const ObservationBusRoom = lazy(() => import('./ObservationBusRoom').then((m) => ({ default: m.ObservationBusRoom })))
const ConstitutionalIntelligenceRoom = lazy(() => import('./ConstitutionalIntelligenceRoom').then((m) => ({ default: m.ConstitutionalIntelligenceRoom })))
const CausalExplorerRoom = lazy(() => import('./CausalExplorerRoom').then((m) => ({ default: m.CausalExplorerRoom })))
const TrendObservatoryRoom = lazy(() => import('./TrendObservatoryRoom').then((m) => ({ default: m.TrendObservatoryRoom })))
const ConstitutionalAdvisorRoom = lazy(() => import('./ConstitutionalAdvisorRoom').then((m) => ({ default: m.ConstitutionalAdvisorRoom })))
const ForecastCenterRoom = lazy(() => import('./ForecastCenterRoom').then((m) => ({ default: m.ForecastCenterRoom })))
const ScenarioLabRoom = lazy(() => import('./ScenarioLabRoom').then((m) => ({ default: m.ScenarioLabRoom })))
const RiskObservatoryRoom = lazy(() => import('./RiskObservatoryRoom').then((m) => ({ default: m.RiskObservatoryRoom })))
const PreparednessDashboardRoom = lazy(() => import('./PreparednessDashboardRoom').then((m) => ({ default: m.PreparednessDashboardRoom })))
const EpistemicAtlasRoom = lazy(() => import('./EpistemicAtlasRoom').then((m) => ({ default: m.EpistemicAtlasRoom })))
const UnknownLandscapeRoom = lazy(() => import('./UnknownLandscapeRoom').then((m) => ({ default: m.UnknownLandscapeRoom })))
const EvidenceExplorerRoom = lazy(() => import('./EvidenceExplorerRoom').then((m) => ({ default: m.EvidenceExplorerRoom })))
const ContradictionObservatoryRoom = lazy(() => import('./ContradictionObservatoryRoom').then((m) => ({ default: m.ContradictionObservatoryRoom })))
const ActiveMissionsRoom = lazy(() => import('./ActiveMissionsRoom').then((m) => ({ default: m.ActiveMissionsRoom })))
const MissionGalaxyRoom = lazy(() => import('./MissionGalaxyRoom').then((m) => ({ default: m.MissionGalaxyRoom })))
const ScientificCampaignRoom = lazy(() => import('./ScientificCampaignRoom').then((m) => ({ default: m.ScientificCampaignRoom })))
const DiscoveryChallengeCenterRoom = lazy(() => import('./DiscoveryChallengeCenterRoom').then((m) => ({ default: m.DiscoveryChallengeCenterRoom })))
const PortfolioViewRoom = lazy(() => import('./PortfolioViewRoom').then((m) => ({ default: m.PortfolioViewRoom })))
const StrategyCenterRoom = lazy(() => import('./StrategyCenterRoom').then((m) => ({ default: m.StrategyCenterRoom })))
const CapabilityAtlasRoom = lazy(() => import('./CapabilityAtlasRoom').then((m) => ({ default: m.CapabilityAtlasRoom })))
const TechnologyRoadmapsRoom = lazy(() => import('./TechnologyRoadmapsRoom').then((m) => ({ default: m.TechnologyRoadmapsRoom })))
const BottleneckObservatoryRoom = lazy(() => import('./BottleneckObservatoryRoom').then((m) => ({ default: m.BottleneckObservatoryRoom })))
const OpportunityObservatoryRoom = lazy(() => import('./OpportunityObservatoryRoom').then((m) => ({ default: m.OpportunityObservatoryRoom })))
const CivilizationControlRoom = lazy(() => import('./CivilizationControlRoom').then((m) => ({ default: m.CivilizationControlRoom })))
const PlanetaryTwinRoom = lazy(() => import('./PlanetaryTwinRoom').then((m) => ({ default: m.PlanetaryTwinRoom })))
const CivilizationTimelineRoom = lazy(() => import('./CivilizationTimelineRoom').then((m) => ({ default: m.CivilizationTimelineRoom })))
const KardashevDashboardRoom = lazy(() => import('./KardashevDashboardRoom').then((m) => ({ default: m.KardashevDashboardRoom })))
const ResilienceCenterRoom = lazy(() => import('./ResilienceCenterRoom').then((m) => ({ default: m.ResilienceCenterRoom })))
const FutureGalaxyRoom = lazy(() => import('./FutureGalaxyRoom').then((m) => ({ default: m.FutureGalaxyRoom })))
const CounterfactualStudioRoom = lazy(() => import('./CounterfactualStudioRoom').then((m) => ({ default: m.CounterfactualStudioRoom })))
const FutureComparatorRoom = lazy(() => import('./FutureComparatorRoom').then((m) => ({ default: m.FutureComparatorRoom })))
const ExistentialRiskCenterRoom = lazy(() => import('./ExistentialRiskCenterRoom').then((m) => ({ default: m.ExistentialRiskCenterRoom })))
const MetaObservatoryRoom = lazy(() => import('./MetaObservatoryRoom').then((m) => ({ default: m.MetaObservatoryRoom })))
const InstrumentationExplorerRoom = lazy(() => import('./InstrumentationExplorerRoom').then((m) => ({ default: m.InstrumentationExplorerRoom })))
const EvolutionCenterRoom = lazy(() => import('./EvolutionCenterRoom').then((m) => ({ default: m.EvolutionCenterRoom })))
const ConstitutionalGovernanceRoom = lazy(() => import('./ConstitutionalGovernanceRoom').then((m) => ({ default: m.ConstitutionalGovernanceRoom })))
const ObservatoryGenealogyRoom = lazy(() => import('./ObservatoryGenealogyRoom').then((m) => ({ default: m.ObservatoryGenealogyRoom })))
const OperationsCommandRoom = lazy(() => import('./OperationsCommandRoom').then((m) => ({ default: m.OperationsCommandRoom })))
const ExecutionTimelineRoom = lazy(() => import('./ExecutionTimelineRoom').then((m) => ({ default: m.ExecutionTimelineRoom })))
const ResourceCommandRoom = lazy(() => import('./ResourceCommandRoom').then((m) => ({ default: m.ResourceCommandRoom })))
const SafetyCenterRoom = lazy(() => import('./SafetyCenterRoom').then((m) => ({ default: m.SafetyCenterRoom })))
const FederationCommandRoom = lazy(() => import('./FederationCommandRoom').then((m) => ({ default: m.FederationCommandRoom })))
const GlobalKnowledgeMapRoom = lazy(() => import('./GlobalKnowledgeMapRoom').then((m) => ({ default: m.GlobalKnowledgeMapRoom })))
const DiscoveryFederationRoom = lazy(() => import('./DiscoveryFederationRoom').then((m) => ({ default: m.DiscoveryFederationRoom })))
const ConsensusCenterRoom = lazy(() => import('./ConsensusCenterRoom').then((m) => ({ default: m.ConsensusCenterRoom })))
const CivilizationTimelineFederationRoom = lazy(() => import('./CivilizationTimelineFederationRoom').then((m) => ({ default: m.CivilizationTimelineFederationRoom })))

const ROOM_MAP: Record<string, React.LazyExoticComponent<() => React.ReactNode>> = {
  runtime: RuntimeRoom,
  science: ScienceRoom,
  engineering: EngineeringRoom,
  knowledge: KnowledgeRoom,
  evolution: EvolutionRoom,
  certification: CertificationRoom,
  planetary: PlanetaryRoom,
  civilization: CivilizationRoom,
  replay: ReplayRoom,
  'observation-bus': ObservationBusRoom,
  'constitutional-intelligence': ConstitutionalIntelligenceRoom,
  'causal-explorer': CausalExplorerRoom,
  'trend-observatory': TrendObservatoryRoom,
  'constitutional-advisor': ConstitutionalAdvisorRoom,
  'forecast-center': ForecastCenterRoom,
  'scenario-lab': ScenarioLabRoom,
  'risk-observatory': RiskObservatoryRoom,
  'preparedness-dashboard': PreparednessDashboardRoom,
  'epistemic-atlas': EpistemicAtlasRoom,
  'unknown-landscape': UnknownLandscapeRoom,
  'evidence-explorer': EvidenceExplorerRoom,
  'contradiction-observatory': ContradictionObservatoryRoom,
  'active-missions': ActiveMissionsRoom,
  'mission-galaxy': MissionGalaxyRoom,
  'scientific-campaign': ScientificCampaignRoom,
  'discovery-challenge-center': DiscoveryChallengeCenterRoom,
  'portfolio-view': PortfolioViewRoom,
  'strategy-center': StrategyCenterRoom,
  'capability-atlas': CapabilityAtlasRoom,
  'technology-roadmaps': TechnologyRoadmapsRoom,
  'bottleneck-observatory': BottleneckObservatoryRoom,
  'opportunity-observatory': OpportunityObservatoryRoom,
  'civilization-control': CivilizationControlRoom,
  'planetary-twin': PlanetaryTwinRoom,
  'civilization-timeline': CivilizationTimelineRoom,
  'kardashev-dashboard': KardashevDashboardRoom,
  'resilience-center': ResilienceCenterRoom,
  'future-galaxy': FutureGalaxyRoom,
  'counterfactual-studio': CounterfactualStudioRoom,
  'future-comparator': FutureComparatorRoom,
  'existential-risk-center': ExistentialRiskCenterRoom,
  'meta-observatory': MetaObservatoryRoom,
  'instrumentation-explorer': InstrumentationExplorerRoom,
  'evolution-center': EvolutionCenterRoom,
  'constitutional-governance': ConstitutionalGovernanceRoom,
  'observatory-genealogy': ObservatoryGenealogyRoom,
  'operations-command': OperationsCommandRoom,
  'execution-timeline': ExecutionTimelineRoom,
  'resource-command': ResourceCommandRoom,
  'safety-center': SafetyCenterRoom,
  'federation-command': FederationCommandRoom,
  'global-knowledge-map': GlobalKnowledgeMapRoom,
  'discovery-federation': DiscoveryFederationRoom,
  'consensus-center': ConsensusCenterRoom,
  'civilization-timeline-federation': CivilizationTimelineFederationRoom,
}

export function LazyRoom({ slug }: { slug: string }) {
  const Component = ROOM_MAP[slug]
  if (!Component) return <p className="text-slate-500 p-4">Unknown room: {slug}</p>
  return (
    <Suspense fallback={<p className="text-slate-500 p-4">Loading {slug} room...</p>}>
      <Component />
    </Suspense>
  )
}

export const ROOM_SLUGS = Object.keys(ROOM_MAP)
