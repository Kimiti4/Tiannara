defmodule TiannaraRuntime.Omega.CheckpointReliability do
  @moduledoc """
  Periodically verifies checkpoint progress and forces executive-memory snapshots.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{ExecutiveMemory, FailureObservatory, SafeCPL, SentinelEventBus}

  @default_interval 30_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def audit_now do
    GenServer.call(__MODULE__, :audit_now)
  end

  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(opts) do
    state = %{
      interval: Keyword.get(opts, :interval, @default_interval),
      audits: 0,
      failures: 0,
      last_audit: nil,
      last_error: nil
    }

    schedule(state.interval)
    {:ok, state}
  end

  @impl true
  def handle_call(:audit_now, _from, state) do
    {reply, state} = run_audit(state)
    {:reply, reply, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, Map.drop(state, [:interval]), state}
  end

  @impl true
  def handle_info(:audit, state) do
    {_reply, state} = run_audit(state)
    schedule(state.interval)
    {:noreply, state}
  end

  defp run_audit(state) do
    with {:ok, memory_checkpoint} <- checkpoint_memory(),
         {:ok, stats} <- SafeCPL.recovery_stats(),
         true <- Map.get(stats, :hash_chain_intact, false) do
      audit = %{
        timestamp: System.system_time(:millisecond),
        memory_checkpoint: memory_checkpoint,
        cpl_stats: stats
      }

      publish(:checkpoint_audit_passed, audit)
      {{:ok, audit}, %{state | audits: state.audits + 1, last_audit: audit, last_error: nil}}
    else
      false ->
        record_failure(state, :hash_chain_failed)

      {:error, reason} ->
        record_failure(state, reason)
    end
  end

  defp checkpoint_memory do
    if Process.whereis(ExecutiveMemory) do
      ExecutiveMemory.checkpoint()
    else
      {:error, :executive_memory_unavailable}
    end
  end

  defp record_failure(state, reason) do
    FailureObservatory.record_failure(:checkpoint_reliability, reason)
    publish(:checkpoint_failure, %{reason: inspect(reason)})

    {{:error, reason},
     %{
       state
       | audits: state.audits + 1,
         failures: state.failures + 1,
         last_error: inspect(reason),
         last_audit: %{timestamp: System.system_time(:millisecond), status: :failed}
     }}
  end

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end

  defp schedule(interval), do: Process.send_after(self(), :audit, interval)
end
