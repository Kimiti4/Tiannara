defmodule Tiannara.Research.KnowledgeIntegratorTest do
  use ExUnit.Case, async: false

  alias Tiannara.Research.KnowledgeIntegrator

  describe "KnowledgeIntegrator" do
    test "integrate rejects low confidence evidence" do
      experiment = %{id: "e1", hypothesis: %{id: "h1", title: "test", domain: :memory, signal: :total_memory, statement: "test"}}
      evidence = %{id: "ev1", confidence: 0.3, reproducibility: 0.2, effect_size: 0.1, consistency: 0.1, falsification_attempted: false, rationale: "low", observations: []}
      assert {:error, :insufficient_confidence} = KnowledgeIntegrator.integrate(experiment, evidence, execution_mode: :real_execution)
    end

    test "integrate rejects execution_mode not real_execution" do
      experiment = %{id: "e_sim", hypothesis: %{id: "h_sim", title: "sim", domain: :test, signal: :sim, statement: "sim"}}
      evidence = %{id: "ev_sim", confidence: 0.9, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "sim", observations: []}
      assert {:error, :execution_mode_not_real} = KnowledgeIntegrator.integrate(experiment, evidence, execution_mode: :simulation)
      assert {:error, :execution_mode_not_real} = KnowledgeIntegrator.integrate(experiment, evidence)
    end

    test "integrate accepts real_execution mode with high confidence" do
      experiment = %{id: "e2", hypothesis: %{id: "h2", title: "test", domain: :memory, signal: :total_memory, statement: "test"}}
      evidence = %{id: "ev2", confidence: 0.85, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "good evidence", observations: []}
      assert :ok = KnowledgeIntegrator.integrate(experiment, evidence, execution_mode: :real_execution)
    end

    test "real_knowledge returns only non-quarantined real_execution items" do
      _sim = KnowledgeIntegrator.integrate(
        %{id: "e_sim2", hypothesis: %{id: "hs", title: "s", domain: :test, signal: :s, statement: "s"}},
        %{id: "ev_s", confidence: 0.9, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :simulation
      )
      _real = KnowledgeIntegrator.integrate(
        %{id: "e_real", hypothesis: %{id: "hr", title: "r", domain: :test, signal: :r, statement: "r"}},
        %{id: "ev_r", confidence: 0.9, reproducibility: 0.8, effect_size: 0.7, consistency: 0.75, falsification_attempted: true, rationale: "r", observations: []},
        execution_mode: :real_execution
      )
      real_knowledge = KnowledgeIntegrator.real_knowledge(50)
      assert Enum.all?(real_knowledge, &(&1.execution_mode == :real_execution and not Map.get(&1, :quarantined, false)))
      assert Enum.any?(real_knowledge, &(&1.experiment_id == "e_real"))
      refute Enum.any?(real_knowledge, &(&1.experiment_id == "e_sim2"))
    end

    test "recent returns integrated knowledge" do
      knowledge = KnowledgeIntegrator.recent(10)
      assert is_list(knowledge)
    end

    test "total_integrated returns count" do
      assert is_integer(KnowledgeIntegrator.total_integrated())
    end

    test "status returns integrator info" do
      status = KnowledgeIntegrator.status()
      assert Map.has_key?(status, :total_integrated)
      assert Map.has_key?(status, :total_rejected)
      assert Map.has_key?(status, :last_integration_at)
      assert Map.has_key?(status, :recent_domains)
    end
  end
end
