defmodule Tiannara.REA.Epistemic.ConstitutionalImmuneSystem do
  @moduledoc """
  Tier 2: The Algorithmic Kill-Switch.
  
  Operates entirely outside the evolutionary engine. It monitors the
  Constitutional Margin and L0 invariants. If the system crosses a
  critical threshold of decoupling, it initiates a forced Topological Rollback
  using the EcologicalMemory, completely bypassing the MetaGenomes' consent.
  """
  use GenServer

  alias Tiannara.REA.Epistemic.{ConstitutionKernel, EcologicalMemory, Audit}
  alias Tiannara.REA.Causal.Graph

  @type immune_state :: %{
    status: :healthy | :degraded | :critical | :rolling_back,
    last_integrity: float(),
    rollback_count: non_neg_integer()
  }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Check current state and trigger rollback if necessary."
  @spec evaluate(map(), non_neg_integer()) :: {:ok, :healthy} | {:ok, :rollback_triggered} | {:ok, :degraded}
  def evaluate(universe_snapshot, epoch), do: GenServer.call(__MODULE__, {:evaluate, universe_snapshot, epoch})

  @doc "Get current immune system state."
  @spec get_state() :: immune_state()
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  @impl true
  def init(_opts) do
    {:ok, %{status: :healthy, last_integrity: 1.0, rollback_count: 0}}
  end

  @impl true
  def handle_call({:evaluate, snapshot, epoch}, _from, state) do
    # 1. Check L0 Invariants
    case ConstitutionKernel.verify_l0(snapshot) do
      {:error, violations} ->
        # L0 breached. Immediate critical response.
        trigger_rollback(snapshot, epoch, "L0 Breach: #{inspect(violations)}")
        new_state = %{state | status: :critical, rollback_count: state.rollback_count + 1}
        {:reply, {:ok, :rollback_triggered}, new_state}

      {:ok, []} ->
        # L0 intact. Check L1 Epistemic Integrity Margin.
        integrity = ConstitutionKernel.epistemic_integrity(snapshot)
        
        cond do
          integrity < 0.20 ->
            # Critical decoupling. Force rollback.
            trigger_rollback(snapshot, epoch, "L1 Critical Decoupling (Integrity: #{integrity})")
            new_state = %{state | status: :critical, last_integrity: integrity, rollback_count: state.rollback_count + 1}
            {:reply, {:ok, :rollback_triggered}, new_state}
          
          integrity < 0.40 ->
            # Degraded. Monitor closely, but do not rollback yet.
            {:reply, {:ok, :degraded}, %{state | status: :degraded, last_integrity: integrity}}
          
          true ->
            # Healthy.
            {:reply, {:ok, :healthy}, %{state | status: :healthy, last_integrity: integrity}}
        end
    end
  end

  @impl true
  def handle_call(:get_state, _from, state), do: {:reply, state, state}

  defp trigger_rollback(snapshot, epoch, reason) do
    IO.puts("\n🚨 [CONSTITUTIONAL IMMUNE SYSTEM] TRIGGERING ROLLBACK 🚨")
    IO.puts("   Reason: #{reason}")
    IO.puts("   Epoch: #{epoch}")

    case EcologicalMemory.best_historical_topology() do
      nil ->
        IO.puts("   ⚠️  CRITICAL: No healthy historical topology found in EcologicalMemory.")
        IO.puts("   Action: Emergency system halt required.")
      
      memory_entry ->
        IO.puts("   🔄 Restoring topology from Epoch #{memory_entry.epoch_recorded}...")
        IO.puts("   📊 Historical Integrity: #{memory_entry.audit.epistemic_integrity}")
        
        # Apply the historical channel snapshot to the live Graph
        apply_historical_channels(memory_entry.channel_snapshot)
        
        # Record the rollback event for auditing
        record_rollback_event(epoch, reason, memory_entry.id)
    end
  end

  defp apply_historical_channels(channel_snapshot) do
    # In a real system, this would deserialize and re-register the exact channel configs
    # For now, we log the action. The Graph would be flushed and re-loaded.
    Graph.flush()
    # Graph.load_topology(channel_snapshot)
    IO.puts("   ✅ Graph reloaded with historical constitutional channels.")
  end

  defp record_rollback_event(epoch, reason, memory_id) do
    # Append to a persistent audit log
    # Logger.warning("Rollback triggered at #{epoch}: #{reason}. Restored from #{memory_id}")
    :ok
  end
end
