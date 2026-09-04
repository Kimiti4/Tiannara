defmodule Tiannara.Architecture.Reconciliation do
  def scan(opts \\ []) do
    source_root = Keyword.get(opts, :source_root, "lib/")
    known_subsystems = discover_subsystems(source_root)
    %{
      timestamp: DateTime.utc_now(), subsystems: known_subsystems,
      duplicates: detect_duplicates(known_subsystems),
      orphans: detect_orphans(known_subsystems, source_root),
      recommendations: generate_recommendations(known_subsystems)
    }
  end

  def check_proposal(proposed_module, proposed_responsibilities) do
    existing = find_overlapping(proposed_responsibilities)
    if existing == [] do
      {:ok, "No overlap detected. Safe to create #{proposed_module}."}
    else
      {:overlap, "Proposed module #{proposed_module} overlaps with:\n#{Enum.map_join(existing, "\n", fn {mod, overlap} -> "  - #{mod} (shared: #{Enum.join(overlap, ", ")})" end)}\n\nRecommendation: Extend existing module(s) instead."}
    end
  end

  @known_capabilities %{
    "Tiannara.Observatory" => [:runtime_metrics, :health_monitoring, :performance_tracking, :reporting],
    "Tiannara.Executive.Scheduler" => [:task_scheduling, :priority_management, :load_balancing],
    "Tiannara.WorkflowEngine" => [:workflow_execution, :experiment_running, :pipeline_orchestration],
    "Tiannara.EventBus" => [:event_publishing, :event_subscription, :event_durability, :event_replay],
    "Tiannara.ExecutiveMemory" => [:memory_storage, :memory_replay, :memory_persistence],
    "Tiannara.ConstitutionalScorePipeline" => [:constitutional_scoring, :invariant_verification],
    "Tiannara.WorldModel" => [:world_state, :entity_tracking, :consistency_checking],
    "Tiannara.ControlCenter" => [:ui_dashboard, :api_endpoints, :system_control],
    "Tiannara.ASC" => [:knowledge_graph, :concept_linking, :semantic_reasoning],
    "Tiannara.CSS" => [:cognitive_state, :attention_management],
    "Tiannara.MissionDirector" => [:mission_planning, :goal_tracking, :priority_alignment]
  }

  defp discover_subsystems(_source_root), do: @known_capabilities

  defp detect_duplicates(subsystems) do
    all_caps = Enum.flat_map(subsystems, fn {mod, caps} -> Enum.map(caps, fn cap -> {cap, mod} end) end)
    all_caps
    |> Enum.group_by(fn {cap, _} -> cap end, fn {_, mod} -> mod end)
    |> Enum.filter(fn {_, mods} -> length(mods) > 1 end)
    |> Enum.map(fn {cap, mods} -> %{capability: cap, duplicated_in: mods} end)
  end

  defp detect_orphans(_subsystems, _source_root), do: []

  defp find_overlapping(proposed_responsibilities) do
    Enum.flat_map(@known_capabilities, fn {mod, existing_caps} ->
      overlap = Enum.filter(proposed_responsibilities, fn r -> r in existing_caps end)
      if overlap == [], do: [], else: [{mod, overlap}]
    end)
  end

  defp generate_recommendations(subsystems) do
    [
      %{priority: :high, finding: "Validation capabilities should live under Observatory", action: "Use Tiannara.Observatory.ValidationCampaign instead of standalone engines"},
      %{priority: :medium, finding: "#{map_size(subsystems)} top-level subsystems detected", action: "Review for further consolidation opportunities as the system evolves"}
    ]
  end
end
