defmodule Tiannara.Phase18.RRM.RuleEvolution do
  @moduledoc """
  Bounded mutation engine for execution lowering rules.
  Enforces $\|\Delta \theta\| \leq \kappa_{meta}$ and equivalence verification before deployment.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase18.RRM.{EquivalenceVerifier, AdaptationController}

  @kappa_meta 0.12
  @performance_threshold 0.60

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], active_proposals: %{}}}
  end

  @doc "Propose rule evolution based on runtime metrics"
  @spec propose_evolution(surface_id :: String.t(), rules :: map(), metrics :: map()) :: {:ok, String.t()} | {:error, String.t()}
  def propose_evolution(id, rules, metrics), do: GenServer.call(__MODULE__, {:evolve, id, rules, metrics})

  @impl true
  def handle_call({:evolve, id, rules, metrics}, _from, state) do
    proposal_id = "rrm_prop_#{id}_#{System.system_time() |> rem(10_000)}"
    candidate = mutate_rules(rules, metrics)
    
    if AdaptationController.within_drift_bound?(rules, candidate, @kappa_meta) do
      case EquivalenceVerifier.verify(proposal_id, rules, candidate) do
        {:ok, _score} ->
          Gnat.pub(state.conn_name, "tiannara.phase18.rrm.propose.#{proposal_id}",
                   Jason.encode!(%{proposal_id: proposal_id, surface: id, rules: candidate}))
          Process.send_after(self(), {:expire_proposal, proposal_id}, 3000)
          {:reply, {:ok, proposal_id}, %{state | active_proposals: Map.put(state.active_proposals, proposal_id, candidate)}}

        {:error, :divergence_detected} ->
          {:reply, {:error, :divergence_detected}, state}
      end
    else
      {:reply, {:error, :drift_bound_exceeded}, state}
    end
  end


  @doc """
  Pure gate applied to a candidate rule set before it is proposed.

  A candidate is accepted only when it stays inside the drift bound *and*
  preserves semantics. Scheduling-only changes are preserved; a change that
  alters the computed value is refused as a semantic divergence.
  """
  @spec evaluate_candidate(old_rules :: map(), candidate :: map()) ::
          {:ok, equiv_score :: float()} | {:error, :drift_bound_exceeded | :divergence_detected}
  def evaluate_candidate(rules, candidate) do
    with true <- AdaptationController.within_drift_bound?(rules, candidate, @kappa_meta),
         {:ok, score} <- EquivalenceVerifier.verify("candidate", rules, candidate) do
      {:ok, score}
    else
      false -> {:error, :drift_bound_exceeded}
      {:error, reason} -> {:error, reason}
    end
  end
  defp mutate_rules(rules, %{latency_ms: lat, throughput: tput}) do
    # Bounded heuristic adjustment
    lat_factor = if lat > 150, do: 1.0 + @kappa_meta, else: 1.0
    tput_factor = if tput < 0.8, do: 1.0 - @kappa_meta * 0.5, else: 1.0
    
    Map.new(rules, fn {k, v} ->
      case k do
        :unroll_factor -> {k, clamp(v * lat_factor, 1, 8)}
        :precision     -> {k, (if tput_factor < 1.0, do: :f16, else: v)}
        _              -> {k, v}
      end
    end)
  end

  defp clamp(x, min, max), do: max(min, min(max, x))
end