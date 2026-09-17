defmodule Tiannara.Phase15.SMCP.RuleEvolution do
  @moduledoc """
  Bounded consensus parameter proposal engine.
  Generates candidate adjustments based on live federation metrics.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase15.SMCP.SafetyVerifier

  @max_adaptation_delta 0.15
  @proposal_ttl_ms 3000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], active_proposals: %{}}}
  end

  @doc "Propose parameter adjustment based on current metrics"
  @spec propose_adjustment(params :: map(), metrics :: map()) :: {:ok, String.t()} | {:error, String.t()}
  def propose_adjustment(params, metrics), do: GenServer.call(__MODULE__, {:propose, params, metrics})

  @impl true
  def handle_call({:propose, params, metrics}, _from, state) do
    proposal_id = generate_proposal_id()
    candidate = compute_candidate(params, metrics)
    
    case SafetyVerifier.verify(candidate) do
      :valid ->
        Gnat.pub(state.conn_name, "tiannara.smcp.propose.#{proposal_id}",
                 Jason.encode!(%{proposal_id: proposal_id, params: candidate, timestamp: System.system_time()}))
        Process.send_after(self(), {:expire_proposal, proposal_id}, @proposal_ttl_ms)
        {:reply, {:ok, proposal_id}, %{state | active_proposals: Map.put(state.active_proposals, proposal_id, candidate)}}
      {:error, reason} ->
        {:reply, {:error, "safety_verification_failed: #{reason}"}, state}
    end
  end

  defp compute_candidate(params, %{latency_ms: lat, equivocation_rate: eq, finality_rate: fr}) do
    # Heuristic bounded adjustment
    lat_factor = if lat > 800, do: 1.0 + @max_adaptation_delta * 0.5, else: 1.0
    eq_factor = if eq > 0.02, do: 1.0 + @max_adaptation_delta, else: 1.0
    fr_factor = if fr < 0.95, do: 1.0 - @max_adaptation_delta * 0.3, else: 1.0
    
    %{
      quorum_fraction: clamp(params.quorum_fraction * eq_factor, 0.667, 0.85),
      view_timeout_ms: clamp(params.view_timeout_ms * lat_factor, 200, 5000),
      commit_timeout_ms: clamp(params.commit_timeout_ms * fr_factor, 100, 3000),
      leader_weight: clamp(params.leader_weight * (1.0 / eq_factor), 0.5, 2.0)
    }
  end

  defp clamp(x, min, max), do: max(min, min(max, x))
  defp generate_proposal_id(), do: "smcp_prop_#{System.system_time() |> rem(10_000)}"
end