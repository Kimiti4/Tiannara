defmodule Tiannara.World.EvidenceValidator do
  @moduledoc """
  Evidence Validator — enforces the "Evidence Before Confidence" constitutional mandate.

  Continuously audits entities to ensure no entity holds high confidence
  without a valid, traceable evidence chain.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, WorldQueryEngine, ProvenanceEngine}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @validation_interval :timer.hours(12)
  @min_evidence_for_high_confidence 2
  @high_confidence_threshold 0.8

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :evidence_validator

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [:evidence_chain_validation, :confidence_audit, :provenance_verification, :invalid_knowledge_flagging]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_world_model, :provenance_engine]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)

    health = if stats.active_violations > 0, do: 0.7, else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: health,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def validate_all, do: GenServer.call(__MODULE__, :validate_all, :timer.minutes(5))

  def validate_entity_evidence(entity_id) do
    GenServer.call(__MODULE__, {:validate_entity, entity_id})
  end

  def violations, do: GenServer.call(__MODULE__, :violations)

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    schedule_validation()
    {:ok, %{
      active_violations: [],
      validations_run: 0,
      last_validation_at: nil,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call(:validate_all, _from, state) do
    Logger.info("EvidenceValidator: Starting evidence validation sweep")

      {:ok, result} = WorldQueryEngine.find(min_confidence: @high_confidence_threshold, status: :active, limit: 10_000)

    violations =
      Enum.flat_map(result.results, fn entity ->
        case validate_entity_evidence_internal(entity) do
          {:ok, _} -> []
          {:error, reason} ->
            [%{
              id: "violation_#{entity.id}",
              entity_id: entity.id,
              entity_type: entity.type,
              confidence: entity.confidence,
              reason: reason,
              severity: :high,
              detected_at: DateTime.utc_now(),
              status: :unresolved
            }]
        end
      end)

    if length(violations) > 0 do
      ExecutiveMemory.record_decision(
        "evidence_validation_#{DateTime.utc_now() |> DateTime.to_unix()}",
        :evidence_violations_detected,
        %{violations: violations}
      )

      EventBus.publish("world.evidence.violations_detected", %{count: length(violations)})
    end

    new_state = %{state |
      active_violations: violations,
      validations_run: state.validations_run + 1,
      last_validation_at: DateTime.utc_now()
    }

    schedule_validation()
    {:reply, {:ok, violations}, new_state}
  end

  @impl true
  def handle_call({:validate_entity, entity_id}, _from, state) do
    result =
      case UnifiedWorldModel.get_entity(entity_id) do
        {:ok, entity} -> validate_entity_evidence_internal(entity)
        _ -> {:error, :not_found}
      end
    {:reply, result, state}
  end

  @impl true
  def handle_call(:violations, _from, state) do
    {:reply, state.active_violations, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:validate_all, state) do
    {:reply, _, new_state} = handle_call(:validate_all, nil, state)
    {:noreply, new_state}
  end

  # ---------- Private: Validation Logic ----------

  defp validate_entity_evidence_internal(entity) do
    case ProvenanceEngine.reconstruct_lineage(entity.id, entity) do
      {:ok, lineage} ->
        evidence_count = count_evidence_in_lineage(lineage)

        cond do
          evidence_count == 0 and entity.confidence >= @high_confidence_threshold ->
            {:error, "High confidence (#{entity.confidence}) with zero evidence in provenance chain"}

          has_circular_provenance?(lineage) ->
            {:error, "Circular provenance detected; evidence chain is invalid"}

          true ->
            {:ok, :valid}
        end

      {:error, _} ->
        if entity.confidence >= @high_confidence_threshold do
          {:error, "High confidence entity missing provenance record entirely"}
        else
          {:ok, :valid}
        end
    end
  end

  defp count_evidence_in_lineage(lineage) do
    direct = length(Map.get(lineage, :evidence, []))
    contributor_evidence =
      lineage
      |> Map.get(:contributors, [])
      |> Enum.map(&count_evidence_in_lineage/1)
      |> Enum.sum()
    direct + contributor_evidence
  end

  defp has_circular_provenance?(lineage) do
    root_id = Map.get(lineage, :entity_id)
    contributors = Map.get(lineage, :contributors, [])

    Enum.any?(contributors, fn c ->
      Map.get(c, :entity_id) == root_id or has_circular_provenance?(c)
    end)
  end

  defp schedule_validation do
    Process.send_after(self(), :validate_all, @validation_interval)
  end
end
