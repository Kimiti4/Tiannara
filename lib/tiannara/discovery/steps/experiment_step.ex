defmodule Tiannara.Discovery.Steps.ExperimentStep do
  @moduledoc """
  A REAL, minimal experiment step.

  It compares two world-model observation entities referenced by the step
  input and produces a GENUINE evidence record: the divergence is computed
  from the actual stored values by actual code. Inputs are seeded; the
  measurement is EARNED — which is exactly the boundary the EpistemicSeeder's
  manifest was built to protect, and exactly what the pipeline telemetry's
  earned-vs-seeded read needs.

  No simulator, no LLM, no tensor math: nothing with its own failure surface
  is introduced (rules.md: "Capability must never outpace verification").

  Provenance names this module as producer and lists the consumed entities,
  so the record is auditable and reproducible (rules.md: "Maintain audit
  trails"; "Support reproducibility").

  Input contract (the WorkflowEngine passes `step.input` verbatim):
    `%{entity_a: id, entity_b: id, tolerance: number}` — or `%{inputs: [a, b],
    tolerance: number}` for callers that already carry an entity-id list.

  Composition note: this step RETURNS + PUBLISHES evidence. It does NOT write
  a world entity — WorldStateSynchronizer (Commit B2) owns that write, so
  there is one writer per concern (rules.md: "Minimal coupling").
  """

  @behaviour Tiannara.Discovery.Step

  alias Tiannara.Discovery.{Step, Topics}
  alias Tiannara.World.UnifiedWorldModel

  @impl true
  def step_type, do: :experiment

  @impl true
  def required_capability, do: :observation_comparison

  @impl true
  def validate_input(input) do
    cond do
      not is_map(input) ->
        {:error, :missing_input}

      entity_ids(input) == [] ->
        {:error, :missing_entities}

      true ->
        :ok
    end
  end

  @impl true
  def execute(input, _ctx) do
    [a_id, b_id] = entity_ids(input)
    tolerance = Map.get(input, :tolerance, 1.0)

    a = read_value(a_id)
    b = read_value(b_id)
    divergence = compute_divergence(a, b)

    outcome =
      cond do
        divergence == nil -> :inconclusive
        divergence > tolerance -> :confirmed
        true -> :refuted
      end

    confidence = Step.confidence_from_divergence(divergence, tolerance)

    evidence = %{
      outcome: outcome,
      confidence: confidence,
      uncertainty: 1.0 - confidence,
      measurement: %{
        divergence: divergence,
        tolerance: tolerance,
        a: a,
        b: b,
        a_entity: a_id,
        b_entity: b_id
      },
      source_entities: Enum.reject([a_id, b_id], &is_nil/1),
      provenance: %{
        origin: :experiment_step,
        produced_by: __MODULE__,
        produced_at: DateTime.utc_now(),
        note: "Measurement over seeded inputs — evidence is earned, inputs are seeded."
      }
    }

    publish(Topics.evidence_routed(), %{step_id: Map.get(input, :id), evidence: evidence})
    publish(Topics.experiment_completed(), %{step_id: Map.get(input, :id), outcome: outcome})

    {:ok,
     %{
       evidence: [evidence],
       confidence: confidence,
       quality_metrics: %{
         outcome: outcome,
         divergence: divergence,
         tolerance: tolerance,
         source_entity_count: length(evidence.source_entities)
       },
       resource_usage: %{world_reads: 2},
       experiment: evidence
     }}
  end

  @impl true
  def compensate(_input, _result, _ctx), do: :ok

  @impl true
  def metadata, do: %{description: "Compares two observations and measures divergence"}

  # ── private ────────────────────────────────────────────

  defp entity_ids(input) when is_map(input) do
    cond do
      Map.has_key?(input, :entity_a) or Map.has_key?(input, :entity_b) ->
        [Map.get(input, :entity_a), Map.get(input, :entity_b)]

      true ->
        case Map.get(input, :inputs) do
          [_, _] = ids -> ids
          _ -> []
        end
    end
  end

  defp entity_ids(_), do: []

  defp read_value(nil), do: nil

  defp read_value(id) do
    case UnifiedWorldModel.get_entity(id) do
      {:ok, entity} when is_map(entity) -> attr_value(entity)
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp attr_value(entity) do
    case Map.get(entity, :attributes) do
      %{} = attrs ->
        cond do
          Map.has_key?(attrs, :value) -> Map.get(attrs, :value)
          Map.has_key?(attrs, "value") -> Map.get(attrs, "value")
          true -> nil
        end

      _ ->
        nil
    end
  end

  defp compute_divergence(a, b) when is_number(a) and is_number(b), do: abs(a - b)

  defp compute_divergence(a, b) when not is_nil(a) and not is_nil(b) do
    if a == b, do: 0.0, else: 1.0
  end

  defp compute_divergence(_, _), do: nil

  defp publish(topic, payload) do
    Tiannara.CEL.Services.EventBus.Safe.publish(topic, payload)
    :ok
  end
end
