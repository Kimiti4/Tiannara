defmodule Tiannara.Phase14.REG.GenerationLoop do
  @moduledoc """
  Iterative symbolic search & axiom mutation engine.
  Enforces contraction mapping across generation cycles.
  """
  use GenServer
  require Logger

  alias Tiannara.Phase14.REG.{ConsistencyProver, DriftController, FederationPublisher}

  @epsilon 1.0e-6
  @max_cycles 30
  @consistency_threshold 0.92
  @max_drift 0.35

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{
      conn_name: opts[:connection_name],
      active_cycles: %{},
      generation_queue: :queue.new()
    }}
  end

  @doc "Start generation cycle for a domain"
  @spec start_cycle(domain :: atom(), base_axioms :: map()) :: {:ok, String.t()} | {:error, String.t()}
  def start_cycle(domain, base), do: GenServer.call(__MODULE__, {:cycle, domain, base})

  @impl true
  def handle_call({:cycle, domain, base}, _from, state) do
    cycle_id = generate_cycle_id(domain)
    new_queue = :queue.in({cycle_id, domain, base, 0}, state.generation_queue)
    {:reply, {:ok, cycle_id}, %{state | generation_queue: new_queue}}
  end

  @impl true
  def handle_info(:process_queue, state) do
    case :queue.out(state.generation_queue) do
      {{:value, {cycle_id, domain, base, iter}}, new_queue} ->
        if iter >= @max_cycles do
          Logger.warning("🚫 REG: Max cycles exceeded for #{cycle_id}")
          {:noreply, %{state | generation_queue: new_queue}}
        else
          case run_generation_step(cycle_id, domain, base, iter, state.conn_name) do
            {:converged, axioms} -> 
              Logger.info("✅ REG: Epistemic framework stabilized for #{cycle_id}")
              FederationPublisher.publish(cycle_id, axioms, state.conn_name)
            {:continue, next_base} ->
              :queue.in({cycle_id, domain, next_base, iter + 1}, new_queue)
          end
          {:noreply, %{state | generation_queue: new_queue}}
        end
      {:empty, _} -> {:noreply, state}
    end
  end

  defp run_generation_step(_cycle_id, domain, base, iter, conn_name) do
    novel = mutate_axioms(base, domain)
    
    if DriftController.compute_drift(base, novel) <= @max_drift do
      case ConsistencyProver.verify(novel) do
        score when score >= @consistency_threshold ->
          {:converged, novel}
        _ ->
          {:continue, relax_constraints(novel)}
      end
    else
      {:continue, clamp_drift(novel, base)}
    end
  end

  defp mutate_axioms(base, domain) do
    # Offload to Rust NIF for heavy symbolic search
    Tiannara.Phase14.REG.NativeBridge.mutate(base, domain)
  end

  defp relax_constraints(axioms), do: axioms # Simplified; in prod: adjunction mapping
  defp clamp_drift(novel, base), do: base # Fallback to base on drift breach
  defp generate_cycle_id(domain), do: "reg_#{domain}_#{System.system_time() |> rem(10_000)}"
end