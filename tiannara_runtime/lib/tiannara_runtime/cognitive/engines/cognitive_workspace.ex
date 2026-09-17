defmodule TiannaraRuntime.Cognitive.Engines.CognitiveWorkspace do
  @moduledoc "Phase 18.3 — Cognitive Workspace"

  alias TiannaraRuntime.Cognitive.Engines.WorkingMemory

  def create(mission, attention_state) do
    wm = WorkingMemory.create()
    %{
      working_memory: wm,
      attention_state: attention_state,
      mission_state: mission,
      task_graph: %{},
      evidence_refs: [],
      replay_refs: [],
      archaeology_refs: [],
      created_at: :erlang.unique_integer([:positive])
    }
  end

  def add_task(workspace, task) do
    {:ok, %{workspace | task_graph: Map.put(workspace.task_graph, task.id, task)}}
  end

  def add_evidence(workspace, evidence_ref) do
    {:ok, %{workspace | evidence_refs: workspace.evidence_refs ++ [evidence_ref]}}
  end

  def add_replay(workspace, replay_ref) do
    {:ok, %{workspace | replay_refs: workspace.replay_refs ++ [replay_ref]}}
  end

  def add_archaeology(workspace, archaeology_ref) do
    {:ok, %{workspace | archaeology_refs: workspace.archaeology_refs ++ [archaeology_ref]}}
  end

  def destroy(workspace) do
    {:ok, %{workspace | status: :destroyed}}
  end
end
