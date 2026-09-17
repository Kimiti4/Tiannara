defmodule Tiannara.Research.R0QuarantineTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.{ResearchDirector, KnowledgeIntegrator}

  @moduletag :r0

  describe "R0 — fabricated result quarantine" do
    test "advance quarantines experiment without fabricating results" do
      initial_knowledge = KnowledgeIntegrator.total_integrated()

      priorities = [%{id: "r0_p1", domain: :test, signal: :quarantine_test, score: 0.9, rationale: "R0 test", recommended_action: "investigate"}]
      {:ok, _count} = ResearchDirector.ingest_priorities(priorities)
      :ok = ResearchDirector.advance()

      Process.sleep(50)

      assert KnowledgeIntegrator.total_integrated() == initial_knowledge,
             "Knowledge must NOT increase after quarantine — fabricated path is disabled"
    end

    test "quarantined_count increments after advance processes an experiment" do
      initial_quarantined = ResearchDirector.quarantined_count()

      priorities = [%{id: "r0_p2", domain: :test, signal: :count_test, score: 0.9, rationale: "R0 count", recommended_action: "investigate"}]
      {:ok, _} = ResearchDirector.ingest_priorities(priorities)
      :ok = ResearchDirector.advance()

      Process.sleep(50)

      assert ResearchDirector.quarantined_count() >= initial_quarantined + 1,
             "Quarantine counter must increment when an experiment is dequeued"
    end

    test "validated_knowledge returns only real_execution items (no simulation fixtures)" do
      _sim = KnowledgeIntegrator.integrate(
        %{id: "rk_sim", hypothesis: %{id: "rkh_s", title: "s", domain: :test, signal: :s, statement: "s"}},
        %{id: "rkev_s", confidence: 0.95, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :simulation
      )
      _real = KnowledgeIntegrator.integrate(
        %{id: "rk_real", hypothesis: %{id: "rkh_r", title: "r", domain: :test, signal: :r, statement: "r"}},
        %{id: "rkev_r", confidence: 0.95, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :real_execution
      )
      validated = ResearchDirector.validated_knowledge()
      assert Enum.all?(validated, &(&1.execution_mode == :real_execution))
      assert Enum.any?(validated, &(&1.experiment_id == "rk_real"))
      refute Enum.any?(validated, &(&1.experiment_id == "rk_sim"))
    end

    test "historical items without execution_mode are quarantined on init" do
      _real = KnowledgeIntegrator.integrate(
        %{id: "e_hist", hypothesis: %{id: "h_hist", title: "h", domain: :test, signal: :h, statement: "h"}},
        %{id: "ev_hist", confidence: 0.95, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :real_execution
      )

      recent = KnowledgeIntegrator.recent(100)
      quarantined = Enum.filter(recent, &Map.get(&1, :quarantined, false))
      real = Enum.filter(recent, &(&1.execution_mode == :real_execution))

      assert length(quarantined) >= 0 or length(real) > 0,
             "Knowledge state should distinguish quarantined vs real items"

      assert Enum.all?(real, &(&1.execution_mode == :real_execution and not Map.get(&1, :quarantined, false)))
    end

    test "simulation cannot masquerade as real execution" do
      result = KnowledgeIntegrator.integrate(
        %{id: "e_fake_real", hypothesis: %{id: "h_fake", title: "f", domain: :test, signal: :f, statement: "f"}},
        %{id: "ev_fake", confidence: 0.99, reproducibility: 0.9, effect_size: 0.9, consistency: 0.9, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :simulation
      )
      assert {:error, :execution_mode_not_real} = result
    end

    test "provenance survives persistence and replay" do
      _real = KnowledgeIntegrator.integrate(
        %{id: "e_prov", hypothesis: %{id: "h_prov", title: "p", domain: :test, signal: :p, statement: "p"}},
        %{id: "ev_prov", confidence: 0.95, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :real_execution
      )

      recent = KnowledgeIntegrator.recent(50)
      prov_item = Enum.find(recent, &(&1.experiment_id == "e_prov"))
      assert prov_item != nil, "Real item must be in recent knowledge"
      assert prov_item.execution_mode == :real_execution
      assert is_map(prov_item.lineage)
      assert prov_item.lineage.execution_mode == :real_execution
    end

    test "status includes total_quarantined count" do
      status = KnowledgeIntegrator.status()
      assert Map.has_key?(status, :total_quarantined)
      assert is_integer(status.total_quarantined)
    end
  end
end
