defmodule Tiannara.Test.Phase3Helpers do
  import ExUnit.Assertions

  alias Tiannara.World.{
    UnifiedWorldModel,
    UnifiedRealityGraph,
    WorldMutationEngine,
    ProvenanceEngine,
    VersionManager,
    ConflictResolutionEngine,
    KnowledgeCoordinator,
    CanonicalWorldState,
    BeliefState,
    SnapshotManager,
    OntologyManager
  }

  def unique_id(prefix \\ "test") do
    "#{prefix}_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  def fresh_provenance(origin \\ :test_suite) do
    %{
      origin: origin,
      produced_by: :test_process,
      produced_at: DateTime.utc_now(),
      produced_at_unix: System.system_time(:second)
    }
  end

  def build_entity_spec(domain, type, subtype, attrs \\ %{}, opts \\ []) do
    confidence = Keyword.get(opts, :confidence, 0.5)

    %{
      id: Keyword.get(opts, :id, unique_id("entity")),
      domain: domain,
      type: type,
      subtype: subtype,
      attributes: attrs,
      confidence: confidence,
      uncertainty: 1.0 - confidence,
      provenance: Keyword.get(opts, :provenance, fresh_provenance()),
      owner_subsystem: Keyword.get(opts, :owner, :test_suite),
      version: 1,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      status: :active
    }
  end

  def assert_entity_exists(entity_id) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} -> entity
      {:error, reason} -> flunk("Expected entity #{entity_id} to exist, got: #{inspect(reason)}")
    end
  end

  @doc """
  Mints, registers and one-shot binds a machine-class authorization for a
  governed `UnifiedWorldModel.delete_entity/2` call: obtains a real council
  decision, wraps it (M2), registry-records the mint (M7) and binds it to the
  entity's canonical effect descriptor (M3). Fails loudly (MatchError) if any
  step is refused — tests must never fall back to an ungated delete.
  """
  def mint_delete_authorization(entity_id) do
    decision =
      Tiannara.Council.authorize(
        :world_mutation,
        %{
          mutation_type: :delete_entity,
          mutation_spec: %{id: entity_id},
          context: nil,
          evidence: [%{source: :world_model_test}],
          actor: :phase3_test,
          coherent_with_mission: true,
          degradation_handled: true
        },
        nil
      )

    {:ok, authorization} =
      Tiannara.Council.MachineAuthorization.mint(decision, decision_type: :delete_entity)

    {:ok, bound} =
      Tiannara.Council.MachineAuthorization.bind_effect(
        authorization,
        UnifiedWorldModel.effect_descriptor(entity_id)
      )

    bound
  end

  def refute_entity_exists(entity_id) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:error, _} ->
        :ok

      {:ok, entity} ->
        flunk("Expected entity #{entity_id} to not exist, found: #{inspect(entity)}")
    end
  end

  def wait_for_event(topic, timeout_ms \\ 2000) do
    receive do
      {:executive_bus_message, %{topic: ^topic} = msg} -> msg
    after
      timeout_ms -> flunk("Timed out waiting for event on topic #{topic}")
    end
  end
end
