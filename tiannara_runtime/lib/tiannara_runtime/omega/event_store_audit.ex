defmodule TiannaraRuntime.Omega.EventStoreAudit do
  @moduledoc """
  Audits event persistence surfaces for silent failure indicators.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{FailureObservatory, SafeCPL, SentinelEventBus}

  @default_interval 30_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def audit_now, do: GenServer.call(__MODULE__, :audit_now)
  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(opts) do
    state = %{
      interval: Keyword.get(opts, :interval, @default_interval),
      audits: 0,
      last_audit: nil
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
  def handle_call(:status, _from, state), do: {:reply, Map.drop(state, [:interval]), state}

  @impl true
  def handle_info(:audit, state) do
    {_reply, state} = run_audit(state)
    schedule(state.interval)
    {:noreply, state}
  end

  defp run_audit(state) do
    audit = %{
      timestamp: System.system_time(:millisecond),
      cpl: audit_cpl(),
      multi_world_event_store: audit_multi_world_event_store()
    }

    if audit.cpl.status == :healthy do
      publish(:event_store_audit_passed, audit)
    else
      FailureObservatory.record_failure(:event_store_audit, audit.cpl)
      publish(:event_store_audit_failed, audit)
    end

    {{:ok, audit}, %{state | audits: state.audits + 1, last_audit: audit}}
  end

  defp audit_cpl do
    case SafeCPL.recovery_stats() do
      {:ok, stats} ->
        status = if Map.get(stats, :hash_chain_intact, false), do: :healthy, else: :degraded
        Map.put(stats, :status, status)

      {:error, reason} ->
        %{status: :unavailable, reason: inspect(reason)}
    end
  end

  defp audit_multi_world_event_store do
    module = TiannaraRuntime.MultiWorld.Events.EventStore

    cond do
      Process.whereis(module) ->
        %{status: :healthy, event_count: module.get_event_count()}

      :ets.whereis(:cis_event_store) != :undefined ->
        %{status: :ets_only, event_count: :ets.info(:cis_event_store, :size)}

      true ->
        %{status: :not_started, event_count: 0}
    end
  rescue
    error -> %{status: :degraded, reason: inspect(error)}
  end

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end

  defp schedule(interval), do: Process.send_after(self(), :audit, interval)
end
