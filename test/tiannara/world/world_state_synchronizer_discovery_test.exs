defmodule Tiannara.World.WorldStateSynchronizerDiscoveryTest do
  use ExUnit.Case, async: false

  alias Tiannara.CEL.Services.EventBus
  alias Tiannara.Discovery.Topics
  alias Tiannara.World.{UnifiedRealityGraph, UnifiedWorldModel, WorldStateSynchronizer}

  setup do
    Application.ensure_all_started(:tiannara)

    case Tiannara.ControlCenter.start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, _} -> :ok
    end

    wait_until(fn -> Process.whereis(WorldStateSynchronizer) != nil end)
    :ok
  end

  describe "discovery.completed consumer edge" do
    test "a real-world discovery materializes a world entity with discovery provenance" do
      before = UnifiedWorldModel.stats().entity_count
      discovery_id = "wire_#{System.unique_integer([:positive])}"

      EventBus.publish(Topics.discovery_completed(), %{
        discovery_id: discovery_id,
        data: %{
          statement: "Wiring test discovery",
          evidence_count: 1
        },
        confidence: 0.8,
        evidence: [%{outcome: :supported, confidence: 0.7}]
      })

      entity_id = "discovery_#{discovery_id}"
      wait_until(fn -> entity_present?(entity_id) end)

      assert {:ok, entity} = UnifiedRealityGraph.get_entity(entity_id)
      assert entity.type == :scientific_entity
      assert entity.subtype == :discovery
      assert entity.provenance.origin == :discovery_engine
      assert entity.provenance.discovery_id == discovery_id
      assert length(entity.provenance.evidence) == 1

      assert UnifiedWorldModel.stats().entity_count >= before + 1
      assert WorldStateSynchronizer.stats().processed_events >= 1
    end

    test "the bus envelope is the real CivilizationalEvent and still integrates" do
      discovery_id = "wire_envelope_#{System.unique_integer([:positive])}"

      EventBus.publish(Topics.discovery_completed(), %{
        discovery_id: discovery_id,
        data: %{statement: "Envelope contract check"},
        confidence: 0.75,
        evidence: []
      })

      entity_id = "discovery_#{discovery_id}"
      wait_until(fn -> entity_present?(entity_id) end)

      assert {:ok, %{type: :scientific_entity}} = UnifiedRealityGraph.get_entity(entity_id)
    end
  end

  defp entity_present?(id) do
    case UnifiedRealityGraph.get_entity(id) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp wait_until(fun, timeout_ms \\ 15_000) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms

    retry = fn retry ->
      if fun.() do
        :ok
      else
        if System.monotonic_time(:millisecond) > deadline do
          flunk("timed out waiting for condition")
        else
          Process.sleep(100)
          retry.(retry)
        end
      end
    end

    retry.(retry)
  end
end