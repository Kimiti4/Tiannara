defmodule Tiannara.Core.WorldModel.Timeline do
  @moduledoc """
  Temporal representation - Past, Present, Future, and Counterfactual states.

  Connects directly to the Temporal Domain.
  Supports branching histories and alternative timelines.

  Structure:
    - past: Historical states
    - present: Current state snapshot
    - future: Predicted scenarios
    - counterfactual: Alternative branches
  """

  defstruct [
    :past_events,
    :present_state,
    :future_scenarios,
    :counterfactual_branches,
    :active_epoch
  ]

  @doc "Create a new timeline."
  def new do
    %__MODULE__{
      past_events: [],
      present_state: %{},
      future_scenarios: [],
      counterfactual_branches: [],
      active_epoch: DateTime.utc_now()
    }
  end

  @doc "Record a historical event."
  def record_event(timeline, event) do
    %{timeline | past_events: [event | timeline.past_events]}
  end

  @doc "Update present state."
  def update_present(timeline, state_update) do
    new_present = Map.merge(timeline.present_state, state_update)
    %{timeline | present_state: new_present, active_epoch: DateTime.utc_now()}
  end

  @doc "Add a future scenario."
  def add_scenario(timeline, scenario_id, probability, forecast) do
    scenario = {scenario_id, probability, forecast}
    %{timeline | future_scenarios: [scenario | timeline.future_scenarios]}
  end

  @doc "Add a counterfactual branch."
  def branch_counterfactual(timeline, branch_name, hypothetical_state) do
    branch = {branch_name, hypothetical_state}
    %{timeline | counterfactual_branches: [branch | timeline.counterfactual_branches]}
  end
end
