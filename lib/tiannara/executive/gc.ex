defmodule Tiannara.Executive.GC do
  @moduledoc """
  Memory lifecycle management for Executive Memory.

  Lifecycle: active → dormant → archived → historical → archaeology
  - Volatile/working records expire after TTL
  - Dormant records demoted after inactivity
  - Archived/historical records preserved
  - Archaeology records never collected
  """

  require Logger

  alias Tiannara.Executive.{DetsStore, ETSCache, Telemetry}

  @doc "Runs garbage collection on the DETS store."
  def run(name, ref) do
    Logger.info("[ExecutiveMemory] Running GC for #{name}")
    now = DateTime.utc_now()
    state = %{deleted: 0, kept: 0}

    result = DetsStore.fold(ref, state, fn {key, value}, acc ->
      case classify(key, value, now) do
        :delete ->
          DetsStore.delete(ref, key)
          ETSCache.delete(name, key)
          %{acc | deleted: acc.deleted + 1}
        :keep ->
          %{acc | kept: acc.kept + 1}
      end
    end)

    Telemetry.emit_gc(name)
    Logger.info("[ExecutiveMemory] GC complete: deleted #{result.deleted}, kept #{result.kept}")
    result
  end

  defp classify(_key, value, now) do
    class = memory_class(value)
    expiry = ttl_for(class)

    case expiry do
      :never -> :keep
      ttl when is_integer(ttl) ->
        last_access = Map.get(value, :accessed_at, now)
        age = DateTime.diff(now, last_access, :millisecond)
        if age > ttl, do: :delete, else: :keep
    end
  end

  defp memory_class(value) when is_map(value) do
    Map.get(value, :class, :operational)
  end

  defp memory_class(_), do: :operational

  defp ttl_for(:archaeological), do: :never
  defp ttl_for(:constitutional), do: :never
  defp ttl_for(:historical), do: :never
  defp ttl_for(:scientific), do: 7_776_000_000
  defp ttl_for(:operational), do: 86_400_000
  defp ttl_for(:volatile), do: 3_600_000
  defp ttl_for(_), do: 86_400_000
end
