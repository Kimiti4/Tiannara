defmodule Tiannara.OPC.Runtime.ExecutionRuntime do
  @moduledoc """
  Phase 5F.6 — OPC Execution Runtime
  
  Manages compiled observer kernels and their execution.
  Integrates with MSCL for budget checking and OLEF for load allocation.

  Stage 3 (Council-authorized): execution identity is authority-MINTED and
  lifecycle-normalized through `TiannaraOS.Provenance.Producer` instead of a
  producer-local `System.unique_integer`. The producer has no local authority
  over `execution_id`; the minted canonical id is a `forward_exec_v1` binary.
  """
  
  use GenServer
  require Logger

  alias TiannaraOS.Provenance.Producer

  @producer "Tiannara.OPC.Runtime.ExecutionRuntime"

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc """
  Execute a compiled shader for an observer.
  """
  def execute(observer_id, shader) do
    GenServer.call(__MODULE__, {:execute, observer_id, shader})
  end

  @doc """
  Get active kernel information.
  """
  def get_active_kernels do
    GenServer.call(__MODULE__, :get_active_kernels)
  end

  @impl true
  def init(_opts) do
    state = %{
      active_kernels: %{},
      execution_count: 0
    }
    
    Logger.info("🚀 OPC ExecutionRuntime initialized")
    {:ok, state}
  end

  @impl true
  def handle_call({:execute, observer_id, shader}, _from, state) do
    Logger.info("⚙️ Executing observer kernel #{observer_id}")
    
    # Check MSCL budget (placeholder - integrate with actual MSCL)
    budget_check = check_mscl_budget(observer_id)
    
    case budget_check do
      :ok ->
        # Allocate via OLEF (placeholder - integrate with actual OLEF)
        allocation = allocate_olef_load(observer_id)

        case Producer.begin(@producer, %{"observer_id" => observer_id}) do
          {:ok, execution_id, _record, lifecycle} ->
            result = %{
              observer: observer_id,
              execution_id: execution_id,
              shader_length: byte_size(shader),
              allocated_node: allocation,
              status: :executed
            }

            case Producer.complete(@producer, execution_id, lifecycle, %{
                   "observer_id" => observer_id,
                   "status" => "executed"
                 }) do
              {:ok, _normalized, _lifecycle2} ->
                :ok

              {:error, reason, culprit} ->
                Logger.warning("OPC lifecycle completion rejected for #{execution_id}: #{inspect(reason)}")
                Logger.warning("OPC lifecycle culprit: #{inspect(culprit)}")
            end

            new_kernels = Map.put(state.active_kernels, execution_id, result)

            {:reply, {:ok, result},
             %{state | active_kernels: new_kernels, execution_count: state.execution_count + 1}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
      
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_active_kernels, _from, state) do
    {:reply, {:ok, state.active_kernels}, state}
  end

  # Placeholder functions - integrate with actual MSCL/OLEF
  defp check_mscl_budget(_observer_id) do
    # TODO: Integrate with Tiannara.MSCL.BudgetTracker
    :ok
  end

  defp allocate_olef_load(_observer_id) do
    # TODO: Integrate with Tiannara.OLEF.GradientRouter
    "node_default"
  end
end
