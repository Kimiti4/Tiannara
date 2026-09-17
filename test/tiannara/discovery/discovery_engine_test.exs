defmodule Tiannara.Discovery.DiscoveryEngineTest do
  use ExUnit.Case, async: false
  alias Tiannara.Discovery.DiscoveryEngine
  alias Tiannara.Discovery.Domain.KnowledgeGap

  setup do
    case Process.whereis(DiscoveryEngine) do
      nil ->
        {:ok, pid} = DiscoveryEngine.start_link([])
        on_exit(fn -> Process.unlink(pid); Process.exit(pid, :normal) end)
      _pid ->
        :ok
    end
    :ok
  end

  describe "create_discovery/1 and get_discovery/1" do
    test "creates and returns discovery" do
      gap = KnowledgeGap.new(domain: :test, description: "engine test")
      {:ok, disc} = DiscoveryEngine.create_discovery(gap)
      {:ok, returned} = DiscoveryEngine.get_discovery(disc.id)
      assert returned.id == disc.id
      assert returned.status == :question_formulated
    end
  end

  describe "route_evidence/2" do
    test "routes evidence to a discovery" do
      gap = KnowledgeGap.new(domain: :test, description: "evidence test")
      {:ok, disc} = DiscoveryEngine.create_discovery(gap)
      evidence = [%{type: :test_result, confidence_delta: 0.3}]
      {:ok, result} = DiscoveryEngine.route_evidence(disc.id, evidence)
      assert length(result.discovery.evidence) == 1
      assert length(result.evaluations) == 1
      assert result.integrity == :ok
    end
  end

  describe "get_stats/0" do
    test "returns stats" do
      stats = DiscoveryEngine.get_stats()
      assert is_map(stats)
      assert stats.total_discoveries >= 0
    end
  end
end
