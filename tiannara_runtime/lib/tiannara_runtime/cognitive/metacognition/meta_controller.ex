defmodule TiannaraRuntime.Cognitive.Metacognition.MetaController do
  @moduledoc "Phase 18.8 — Meta-cognitive session controller"

  def initialize_session(config) do
    id = "mc_#{:erlang.unique_integer([:positive])}"
    {:ok, %{session_id: id, status: :initialized, monitors: [], confidence_estimates: [], uncertainty_estimates: [], health_assessments: [], escalations: [], introspections: [], config: config, created_at: :erlang.unique_integer([:positive]), completed_at: nil}}
  end

  def record_step(session, step_type, step_data) do
    list_key = case step_type do
      :monitor -> :monitors
      :confidence -> :confidence_estimates
      :uncertainty -> :uncertainty_estimates
      :health -> :health_assessments
      :escalation -> :escalations
      :introspection -> :introspections
    end
    current = Map.get(session, list_key, [])
    {:ok, %{session | list_key => current ++ [step_data]}}
  end

  def finalize(session) do
    {:ok, %{session | status: :completed, completed_at: :erlang.unique_integer([:positive])}}
  end

  def summarize(session) do
    {:ok, %{monitor_count: length(Map.get(session, :monitors, [])), confidence_count: length(Map.get(session, :confidence_estimates, [])), uncertainty_count: length(Map.get(session, :uncertainty_estimates, [])), health_count: length(Map.get(session, :health_assessments, [])), escalation_count: length(Map.get(session, :escalations, [])), introspection_count: length(Map.get(session, :introspections, [])), status: Map.get(session, :status)}}
  end
end
