defmodule Tiannara.Phase16.REA.ArbitrationLoop do
  @moduledoc """
  Recursive fixed-point harmonization engine.
  Iteratively resolves cross-domain constraints until $\|\mathcal{A}^{(n+1)} - \mathcal{A}^{(n)}\| < \epsilon$.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase16.REA.{ConstraintUnifier, ConflictResolver, ConvergenceMonitor}

  @epsilon 1.0e-6
  @max_rounds 25
  @harmonization_threshold 0.40

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      active_harmonizations: %{},
      arbitration_queue: :queue.new()
    }}
  end

  @doc "Start cross-domain harmonization cycle"
  @spec start_harmonization(domains :: [atom()], axioms :: map()) :: {:ok, String.t()} | {:error, String.t()}
  def start_harmonization(domains, axioms), do: GenServer.call(__MODULE__, {:harmonize, domains, axioms})

  @impl true
  def handle_call({:harmonize, domains, axioms}, _from, state) do
    harm_id = generate_harmonization_id(domains)
    new_queue = :queue.in({harm_id, domains, axioms, 0, nil}, state.arbitration_queue)
    {:reply, {:ok, harm_id}, %{state | arbitration_queue: new_queue}}
  end

  @impl true
  def handle_info(:process_queue, state) do
    case :queue.out(state.arbitration_queue) do
      {{:value, {harm_id, domains, axioms, round, prev_state}}, new_queue} ->
        cond do
          round >= @max_rounds ->
            Logger.warning("🚫 REA: Max rounds exceeded for #{harm_id}")
            {:noreply, %{state | arbitration_queue: new_queue}}
          
          true ->
            case run_arbitration_step(harm_id, domains, axioms, prev_state, state.conn_name) do
              {:converged, unified} ->
                Logger.info("✅ REA: Harmonization converged for #{harm_id}")
                publish_harmonized(harm_id, unified, state.conn_name)
              {:continue, next_axioms} ->
                :queue.in({harm_id, domains, next_axioms, round + 1, axioms}, new_queue)
            end
            {:noreply, %{state | arbitration_queue: new_queue}}
        end
      {:empty, _} -> {:noreply, state}
    end
  end

  defp run_arbitration_step(harm_id, domains, axioms, prev, conn_name) do
    overlap = Tiannara.Phase16.REA.DomainRegistry.compute_domain_overlap(domains)
    unified = ConstraintUnifier.map_to_hypergraph(axioms, domains)
    conflict = ConflictResolver.compute_density(unified)
    
    h_rea = compute_harmonization_score(overlap, unified.consistency, conflict, length(domains))
    ConvergenceMonitor.record_step(harm_id, h_rea, prev)
    
    cond do
      h_rea < @harmonization_threshold -> {:error, :harmonization_below_threshold}
      ConvergenceMonitor.converged?(harm_id) -> {:converged, unified}
      true -> {:continue, ConflictResolver.relax(axioms, unified)}
    end
  end

  defp compute_harmonization_score(overlap, consistency, conflict, recursion_depth) do
    numerator = overlap * consistency
    denominator = conflict + (recursion_depth * 0.05) + 1.0e-6
    min(1.0, numerator / denominator)
  end

  defp publish_harmonized(harm_id, unified, conn_name) do
    Gnat.pub(conn_name, "tiannara.phase16.rea.harmonized.#{harm_id}",
             Jason.encode!(%{harmonization_id: harm_id, unified_constraints: unified, timestamp: System.system_time()}))
  end

  defp generate_harmonization_id(domains), do: "rea_#{Enum.join(domains, "_")}_#{System.system_time() |> rem(10_000)}"
end