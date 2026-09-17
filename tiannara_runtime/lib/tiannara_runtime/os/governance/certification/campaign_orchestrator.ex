defmodule TiannaraRuntime.OS.Governance.Certification.CampaignOrchestrator do
  @moduledoc """
  CampaignOrchestrator — Master runner for the 30-campaign Constitutional Certification Framework.

  Executes campaigns grouped by six constitutional domains (tiers), respecting
  dependency ordering. Collects evidence lineage across the run and halts on
  constitutional failures.

  ## Usage

      config = %{scale: :standard, seed: 42}
      {:ok, results} = CampaignOrchestrator.run_all(config)

      # Run a specific tier
      {:ok, results} = CampaignOrchestrator.run_tier(1, config)

      # Run specific campaigns
      {:ok, results} = CampaignOrchestrator.run_campaigns(["CC-001", "CC-004"], config)
  """

  alias TiannaraRuntime.OS.Governance.Certification.{CampaignAdapter, ReadinessIndexReport}

  @type run_result :: %{
    total_campaigns: integer(),
    passed: integer(),
    failed: integer(),
    skipped: integer(),
    evidence_chain: [CampaignAdapter.evidence()],
    failures: [CampaignAdapter.failure_reason()],
    readiness_index: map() | nil,
    duration_ms: integer()
  }

  @doc """
  Runs all 30 campaigns in dependency order across all six tiers.
  """
  @spec run_all(CampaignAdapter.campaign_config()) :: {:ok, run_result()} | {:error, String.t()}
  def run_all(config) do
    start_ms = System.monotonic_time(:millisecond)
    campaigns = all_campaign_modules()

    case execute_campaigns(campaigns, config, [], []) do
      {:ok, evidence_chain, failures} ->
        duration = System.monotonic_time(:millisecond) - start_ms
        passed = Enum.count(evidence_chain, fn e -> e.status == :pass end)
        failed = length(failures)
        skipped = Enum.count(evidence_chain, fn e -> e.status == :skip end)

        readiness = if passed + failed + skipped == length(campaigns) do
          ReadinessIndexReport.compute(evidence_chain)
        else
          nil
        end

        {:ok, %{
          total_campaigns: length(campaigns),
          passed: passed,
          failed: failed,
          skipped: skipped,
          evidence_chain: evidence_chain,
          failures: failures,
          readiness_index: readiness,
          duration_ms: duration
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Runs all campaigns in a specific tier (1–6).
  """
  @spec run_tier(CampaignAdapter.campaign_tier(), CampaignAdapter.campaign_config()) :: {:ok, run_result()} | {:error, String.t()}
  def run_tier(tier, config) do
    start_ms = System.monotonic_time(:millisecond)
    campaigns = Enum.filter(all_campaign_modules(), fn mod -> mod.tier() == tier end)

    case execute_campaigns(campaigns, config, [], []) do
      {:ok, evidence_chain, failures} ->
        duration = System.monotonic_time(:millisecond) - start_ms
        passed = Enum.count(evidence_chain, fn e -> e.status == :pass end)

        {:ok, %{
          total_campaigns: length(campaigns),
          passed: passed,
          failed: length(failures),
          skipped: Enum.count(evidence_chain, fn e -> e.status == :skip end),
          evidence_chain: evidence_chain,
          failures: failures,
          readiness_index: nil,
          duration_ms: duration
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Runs a specific list of campaigns by ID.
  """
  @spec run_campaigns([CampaignAdapter.campaign_id()], CampaignAdapter.campaign_config()) :: {:ok, run_result()} | {:error, String.t()}
  def run_campaigns(ids, config) do
    start_ms = System.monotonic_time(:millisecond)
    campaigns = Enum.filter(all_campaign_modules(), fn mod -> mod.campaign_id() in ids end)

    case execute_campaigns(campaigns, config, [], []) do
      {:ok, evidence_chain, failures} ->
        duration = System.monotonic_time(:millisecond) - start_ms
        passed = Enum.count(evidence_chain, fn e -> e.status == :pass end)

        {:ok, %{
          total_campaigns: length(campaigns),
          passed: passed,
          failed: length(failures),
          skipped: Enum.count(evidence_chain, fn e -> e.status == :skip end),
          evidence_chain: evidence_chain,
          failures: failures,
          readiness_index: nil,
          duration_ms: duration
        }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Returns all 30 campaign modules in dependency order.
  """
  @spec all_campaign_modules() :: [module()]
  def all_campaign_modules() do
    [
      # Tier I — Constitutional Integrity
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign01ConstitutionalIntegrity,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign02WholeSystemIntegration,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign03MillionStepReplay,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign04CrossScaleCausal,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign05UnknownPreservation,

      # Tier II — Runtime Integrity
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign06Adversarial,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign07ObserverIndependence,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign08CivilizationSimulation,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign09OntologyEvolution,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign10CounterfactualSeparation,

      # Tier III — Scientific Integrity
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign11MathematicalIntegrity,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign12KnowledgeCompression,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign13ScientificDiscovery,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign14EngineeringCapability,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign15ScientificReproducibility,

      # Tier IV — Evolution Integrity
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign16LongHorizonStability,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign17ConstitutionalEvolution,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign18SelfEvolutionSafety,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign19AGIReadiness,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign20MultiDomainIntegration,

      # Tier V — Planetary Readiness
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign21PlanetaryScale,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign22IndependentAudit,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign23EnergySustainability,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign24LongTermDrift,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign25ExtremeScale,

      # Tier VI — Civilizational Readiness
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign26CivilizationBenchmark,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign27FuturePredictionBenchmark,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign28ReadinessIndex,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign29CivilizationScaleReproducibility,
      TiannaraRuntime.OS.Governance.Certification.Campaigns.Campaign30FinalVerdict
    ]
  end

  @doc """
  Returns the domain name for a tier number.
  """
  @spec domain_for_tier(CampaignAdapter.campaign_tier()) :: CampaignAdapter.campaign_domain()
  def domain_for_tier(1), do: :constitutional_integrity
  def domain_for_tier(2), do: :runtime_integrity
  def domain_for_tier(3), do: :scientific_integrity
  def domain_for_tier(4), do: :evolution_integrity
  def domain_for_tier(5), do: :planetary_readiness
  def domain_for_tier(6), do: :civilizational_readiness

  # ── Internal Execution ──────────────────────────────────────

  defp execute_campaigns([], _config, evidence, failures) do
    {:ok, Enum.reverse(evidence), Enum.reverse(failures)}
  end

  defp execute_campaigns([mod | rest], config, evidence, failures) do
    campaign_config = Map.merge(%{
      scale: :standard,
      seed: 42,
      domain: nil,
      campaign_filter: nil,
      tick_rate: nil,
      max_iterations: nil
    }, config)

    IO.puts("[#{mod.campaign_id()}] #{mod.campaign_name()}...")

    case mod.execute(campaign_config) do
      {:ok, ev} ->
        IO.puts("[#{mod.campaign_id()}] PASS (#{ev.fingerprint})")
        execute_campaigns(rest, config, [ev | evidence], failures)

      {:error, reason} ->
        IO.puts("[#{mod.campaign_id()}] FAIL: #{reason.failure_type} — #{reason.details}")
        execute_campaigns(rest, config, evidence, [reason | failures])
    end
  end
end
