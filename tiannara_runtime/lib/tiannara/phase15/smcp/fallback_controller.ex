defmodule Tiannara.Phase15.SMCP.FallbackController do
  @moduledoc """
  Instability detection & baseline rollback layer.
  Reverts to safe parameters if consensus stability metric drops below threshold.
  """
  use GenServer
  require Logger

  @stability_threshold 0.70
  @rollback_timeout_ms 10000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], baseline: %{quorum_fraction: 0.667, view_timeout_ms: 2000, commit_timeout_ms: 1000, leader_weight: 1.0}}}
  end

  @doc "Monitor post-adaptation stability & trigger rollback if breached"
  @spec monitor_stability(proposal_id :: String.t(), stability_score :: float()) :: :ok
  def monitor_stability(id, score), do: GenServer.cast(__MODULE__, {:check, id, score})

  @impl true
  def handle_cast({:check, id, score}, state) do
    if score < @stability_threshold do
      Logger.warning("🔄 SMCP: Stability breach for #{id} (score=#{score}). Triggering baseline rollback.")
      Gnat.pub(state.conn_name, "tiannara.smcp.rollback.#{id}",
               Jason.encode!(%{proposal_id: id, fallback_params: state.baseline}))
    end
    {:noreply, state}
  end
end