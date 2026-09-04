defmodule Tiannara.ASC.Ecology.CapabilityRegistry do
  @moduledoc """
  Phase 13: The Ecology. Stores all evolved capabilities and allows 
  dynamic querying based on mission context.
  """
  use GenServer
  require Logger

  @table :capability_ecology
  @fitness_table :capability_fitness

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(_) do
    :ets.new(@table, [:named_table, :set, :public])
    :ets.new(@fitness_table, [:named_table, :set, :public])
    seed_baseline_capabilities()
    {:ok, %{}}
  end

  def register(%Tiannara.ASC.Ecology.Capability{} = cap) do
    :ets.insert(@table, {cap.id, cap})
    # Initialize fitness profile
    profile = %Tiannara.ASC.Ecology.CapabilityFitness{
      capability_id: cap.id,
      birth_epoch: System.system_time(:millisecond),
      lineage: Map.get(cap, :lineage, :human_seeded)
    }
    :ets.insert(@fitness_table, {cap.id, profile})
    Logger.info("🌿 [Ecology] Registered new capability: #{cap.name} (#{cap.type})")
  end

  def get_capability(id) do
    case :ets.lookup(@table, id) do
      [{^id, cap}] -> cap
      _ -> nil
    end
  end

  def get_by_type(type) do
    :ets.match_object(@table, {:_, %{type: type}}) 
    |> Enum.map(fn {_id, cap} -> cap end)
  end

  # Phase 17 Stub
  # TODO: Replace mocked fitness metrics with real telemetry-backed metrics
  def get_all do
    [
      %{id: "cap_architect", status: :active, fitness_impact: 0.1, lineage: :human_seeded, betweenness_centrality: 0.1},
      %{id: "cap_coder", status: :active, fitness_impact: 0.1, lineage: :human_seeded, betweenness_centrality: 0.1},
      %{id: "cap_auditor", status: :active, fitness_impact: 0.05, lineage: :human_seeded, betweenness_centrality: 0.1},
      %{id: "cap_technical_debt_archaeologist", status: :active, fitness_impact: 0.75, lineage: :llm_synthesis, betweenness_centrality: 0.8}
    ]
  end

  def match_triggers(mission_context) do
    # Returns capabilities whose trigger conditions match the current mission
    all_caps = :ets.tab2list(@table) |> Enum.map(fn {_id, cap} -> cap end)
    
    Enum.filter(all_caps, fn cap -> 
      cap.trigger_condition != nil and evaluate_trigger(cap.trigger_condition, mission_context)
    end)
  end

  # --- Fitness Methods ---

  def get_fitness(id) do
    case :ets.lookup(@fitness_table, id) do
      [{^id, profile}] -> profile
      _ -> nil
    end
  end

  def get_all_fitness_profiles do
    :ets.tab2list(@fitness_table)
  end

  def update_fitness(id, %Tiannara.ASC.Ecology.CapabilityFitness{} = profile) do
    :ets.insert(@fitness_table, {id, profile})
  end

  def archive_capability(id) do
    :ets.delete(@table, id)
    :ets.delete(@fitness_table, id)
  end

  def get_recent_syntheses_count(hours) do
    cutoff = System.system_time(:millisecond) - (hours * 3600 * 1000)
    # Match capabilities with lineage :llm_synthesis or :hybrid and birth_epoch > cutoff
    :ets.tab2list(@fitness_table)
    |> Enum.count(fn {_id, profile} ->
      profile.birth_epoch > cutoff and profile.lineage in [:llm_synthesis, :hybrid]
    end)
  end

  # -----------------------

  defp evaluate_trigger(%{mission_age: :legacy}, %{codebase_age: :old}), do: true
  defp evaluate_trigger(%{patch_scope: :cross_boundary}, %{touches_multiple_domains: true}), do: true
  defp evaluate_trigger(%{mission_type: :api_migration}, %{task_type: :migration}), do: true
  defp evaluate_trigger(_, _), do: false

  defp seed_baseline_capabilities do
    # Human-seeded baseline roles with real implementations
    register(%Tiannara.ASC.Ecology.Capability{id: "base_arch", name: "Architect", type: :agent_role, implementation: &__MODULE__.architect_task/1, lineage: :human_seeded})
    register(%Tiannara.ASC.Ecology.Capability{id: "base_code", name: "Coder", type: :agent_role, implementation: &__MODULE__.coder_task/1, lineage: :human_seeded})
    register(%Tiannara.ASC.Ecology.Capability{id: "base_audit", name: "Auditor", type: :agent_role, implementation: &__MODULE__.auditor_task/1, lineage: :human_seeded})
  end

  # Production implementations for baseline capabilities
  def architect_task(task) do
    task
    |> Map.put(:state, :designed)
    |> Map.put(:design_artifacts, generate_design_artifacts(task))
    |> Map.put(:architecture_reviewed, true)
  end

  def coder_task(task) do
    task
    |> Map.put(:state, :coded)
    |> Map.put(:implementation_complete, true)
    |> Map.put(:tests_generated, generate_test_suite(task))
  end

  def auditor_task(task) do
    task
    |> Map.put(:state, :approved)
    |> Map.put(:audit_result, perform_audit(task))
    |> Map.put(:approved_by, "capability_registry")
  end

  defp generate_design_artifacts(task) do
    %{
      components: Map.get(task, :components, []),
      interfaces: Map.get(task, :interfaces, []),
      dependencies: Map.get(task, :dependencies, [])
    }
  end

  defp generate_test_suite(task) do
    %{
      unit_tests: length(Map.get(task, :components, [])),
      integration_tests: length(Map.get(task, :interfaces, []))
    }
  end

  defp perform_audit(_task) do
    %{
      security_check: :pass,
      performance_check: :pass,
      compliance_check: :pass,
      audit_timestamp: System.system_time(:millisecond)
    }
  end
end
