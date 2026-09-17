defmodule Tiannara.Phase15.SMCP.AdaptationEngine do
  @moduledoc """
  EMA smoothing & distributed rule application layer.
  Applies approved parameters gradually to prevent consensus oscillation.
  """
  use GenServer
  require Logger

  @ema_alpha 0.25
  @rounds_to_full_adoption 5

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      current_params: %{quorum_fraction: 0.667, view_timeout_ms: 2000, commit_timeout_ms: 1000, leader_weight: 1.0},
      active_transitions: %{}
    }}
  end

  @doc "Apply verified proposal via EMA smoothing across federation"
  @spec apply_proposal(proposal_id :: String.t(), candidate_params :: map()) :: :ok
  def apply_proposal(id, params), do: GenServer.cast(__MODULE__, {:apply, id, params})

  @impl true
  def handle_cast({:apply, id, target}, state) do
    transition = %{
      id: id,
      target: target,
      current: state.current_params,
      round: 0,
      acks: %{}
    }
    
    Gnat.pub(state.conn_name, "tiannara.smcp.applied.#{id}",
             Jason.encode!(%{proposal_id: id, target_params: target, round: 0}))
             
    {:noreply, %{state | active_transitions: Map.put(state.active_transitions, id, transition)}}
  end

  @impl true
  def handle_info({:advance_round, id}, state) do
    case Map.fetch(state.active_transitions, id) do
      {:ok, t} ->
        next_round = t.round + 1
        blended = blend_params(t.current, t.target, @ema_alpha, next_round)
        
        Gnat.pub(state.conn_name, "tiannara.smcp.applied.#{id}",
                 Jason.encode!(%{proposal_id: id, target_params: blended, round: next_round}))
                 
        if next_round >= @rounds_to_full_adoption do
          Logger.info("✅ SMCP: Adaptation #{id} fully adopted. Parameters locked.")
          {:noreply, %{state | active_transitions: Map.delete(state.active_transitions, id), current_params: t.target}}
        else
          Process.send_after(self(), {:advance_round, id}, 5000)
          {:noreply, %{state | active_transitions: Map.put(state.active_transitions, id, %{t | current: blended, round: next_round})}}
        end
      :error -> {:noreply, state}
    end
  end

  defp blend_params(current, target, alpha, round) do
    factor = 1.0 - :math.pow(1.0 - alpha, round)
    Map.new(current, fn {k, v} -> {k, v + (target[k] - v) * factor} end)
  end
end