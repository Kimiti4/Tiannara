defmodule Tiannara.Omega.LivePipeline do
  @moduledoc """
  The Ω closed-loop live pipeline. Integrates live telemetry observation,
  evidence-driven investigation, correlation-aware CI validation, and
  certification into a single governed cycle:

      live telemetry → observation → anomaly/contradiction
        → evidence-driven investigation → proposal
        → correlation-aware CI validation → certification
        → cycle record (lineage preserved)

  AUTHORITY BOUNDARY: the pipeline observes, investigates, validates, and
  certifies. It does NOT deploy. Deployment remains under Ω.4 governance and
  human judgment (augmentation clause).

  Constitutional basis: Scientific Method, Verification First, Evidence Before
  Confidence, "Every architectural decision should remain traceable",
  augmentation clause.
  """

  alias Tiannara.Telemetry.{AnomalyDetector, SentinelBridge}
  alias Tiannara.Research.Director.EvidenceDriven
  alias Tiannara.Omega.CIWiring
  alias Tiannara.Certification.Pipeline, as: CertPipeline

  defstruct [:cycle_id, :observations, :epistemic_events, :investigation,
             :proposal, :ci_validation, :certificate, :verdict, :lineage]

  @live_policy %{
    observation_collected: :critical,
    investigation_completed: :critical,
    proposal_generated: :critical
  }


  def policy, do: @live_policy

  @doc """
  Runs one closed-loop cycle.

  Options:
    * `:observations` — pre-collected observations (overrides adapter)
    * `:telemetry_adapter` — telemetry source (default RuntimeAdapter)
    * `:ci_provider` — correlation-aware CI provider (optional)
    * `:ci_config` — CI provider config
    * `:growth_window`, `:thresholds` — anomaly detection options
  """
  def run_cycle(opts \\ []) do
    cycle_id = Keyword.get(opts, :cycle_id, make_cycle_id())


    observations = collect_observations(opts)

    epistemic_events =
      observations
      |> AnomalyDetector.detect(opts)
      |> SentinelBridge.to_epistemic_events()

    {investigation, proposal} = investigate(epistemic_events)
    ci_validation = maybe_validate_ci(proposal, opts)
    certificate = certify(observations, investigation, proposal, opts)
    verdict = derive_verdict(investigation, proposal, ci_validation)

    %__MODULE__{
      cycle_id: cycle_id,
      observations: observations,
      epistemic_events: epistemic_events,
      investigation: investigation,
      proposal: proposal,
      ci_validation: ci_validation,
      certificate: certificate,
      verdict: verdict,
      lineage: build_lineage(cycle_id, investigation, proposal, ci_validation)
    }
  end

  # --- steps --------------------------------------------------------------

  defp collect_observations(opts) do
    case Keyword.get(opts, :observations) do
      nil ->
        adapter = Keyword.get(opts, :telemetry_adapter, Tiannara.Telemetry.RuntimeAdapter)
        [adapter.collect([])]

      obs when is_list(obs) ->
        obs
    end
  end

  defp investigate([]), do: {nil, nil}

  defp investigate(events) do
    case Enum.find(events, &EvidenceDriven.research_relevant?/1) do
      nil ->
        {nil, nil}


      event ->
        investigation = EvidenceDriven.investigate(event)
        {investigation, List.first(investigation.proposals)}
    end
  end

  defp maybe_validate_ci(nil, _opts), do: :no_proposal

  defp maybe_validate_ci(proposal, opts) do
    case Keyword.get(opts, :ci_provider) do
      nil ->
        :ci_not_configured

      provider ->
        config = Keyword.get(opts, :ci_config, %{})
        CIWiring.validate(proposal, provider, config, opts)
    end
  end

  defp certify(observations, investigation, proposal, opts) do
    gate_results = %{
      observation_collected: gate_from(length(observations) > 0),
      investigation_completed: gate_from(investigation != nil),
      proposal_generated: gate_from(is_map(proposal))
    }

    CertPipeline.evaluate(gate_results,
      subsystem: :omega_live_pipeline,
      policy: Keyword.get(opts, :certification_policy, @live_policy))
  end

  defp gate_from(true), do: :gate_open
  defp gate_from(false), do: {:gate_closed, [:requirement_not_met]}

  defp derive_verdict(nil, _proposal, _ci), do: :no_investigation_triggered
  defp derive_verdict(_inv, nil, _ci), do: :investigation_without_proposal
  defp derive_verdict(_inv, _proposal, {:ok, _ci}), do: :validated_via_ci
  defp derive_verdict(_inv, _proposal, :ci_not_configured), do: :investigation_complete_no_ci
  defp derive_verdict(_inv, _proposal, _ci_failure), do: :ci_validation_failed

  defp build_lineage(cycle_id, investigation, proposal, ci_validation) do
    [cycle_id]
    |> then(fn l -> if investigation, do: l ++ [investigation.opportunity.id], else: l end)
    |> then(fn l -> if proposal, do: l ++ [proposal.id], else: l end)
    |> then(fn l ->
      case ci_validation do
        {:ok, %{correlation_id: cid}} -> l ++ [cid]
        _ -> l
      end
    end)
  end

  defp make_cycle_id, do: :"cycle-#{System.unique_integer([:monotonic])}"
end