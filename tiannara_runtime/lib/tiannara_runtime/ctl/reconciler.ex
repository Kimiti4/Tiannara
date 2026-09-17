defmodule TiannaraRuntime.CTL.Reconciler do
  @moduledoc """
  Phase 5F.6 — CTL Reconciliation Engine

  Resolves causal tension by selecting one of fork, compress, or quarantine
  actions when the CTL graph exceeds safe stress bounds.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{history: []}}
  end

  @doc "Resolve instability in a causal graph given a stress map."
  def resolve(graph, stress_map) do
    high_stress =
      Enum.filter(stress_map, fn {_event_id, stress} -> stress > 0.9 end)

    Enum.each(high_stress, fn {event_id, _stress} ->
      Logger.warning("[CTL] resolving event #{inspect(event_id)}")

      case decide_resolution(event_id, graph) do
        :fork ->
          fork_branch(event_id)

        :compress ->
          compress_history(event_id)

        :quarantine ->
          quarantine_branch(event_id)
      end
    end)

    :ok
  end

  defp decide_resolution(event_id, _graph) do
    case :erlang.phash2(event_id, 3) do
      0 -> :fork
      1 -> :compress
      _ -> :quarantine
    end
  end

  defp fork_branch(event_id) do
    target_cast(TiannaraRuntime.OLAF.Branch, {:fork, event_id})
  end

  defp compress_history(event_id) do
    target_cast(TiannaraRuntime.HSV.Archiver, {:compress, event_id})
  end

  defp quarantine_branch(event_id) do
    target_cast(TiannaraRuntime.OSL.Sandbox, {:isolate, event_id})
  end

  defp target_cast(target, message) do
    case Process.whereis(target) do
      nil ->
        Logger.warning("[CTL] target #{inspect(target)} unavailable for #{inspect(message)}")

      pid ->
        GenServer.cast(pid, message)
    end

    :ok
  end
end
