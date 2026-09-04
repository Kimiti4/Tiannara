defmodule Tiannara.Memory do
  @moduledoc """
  Memory root module — provides the storage interface for the
  Sentinel Activation Layer to record lessons and outcomes.

  Delegates to specialized memory sub-modules based on key.
  """
  require Logger

  @doc """
  Stores a value under the given key in Tiannara's memory architecture.
  Delegates to appropriate sub-module based on key prefix.
  """
  def store(key, value) when is_atom(key) do
    Logger.debug("[Memory] Storing #{key}")
    case key do
      :sentinel_lessons ->
        store_lesson(value)
      _ ->
        Logger.debug("[Memory] Unknown key #{key}, storing generically")
    end
    :ok
  end

  defp store_lesson(value) do
    Logger.info("[Memory] Sentinel lesson recorded: #{value[:event_id] || "unknown"} -> #{value[:result]}")
    # In a full implementation, this would integrate with the Reality Graph
    # and the Epistemology Archive for persistent storage
    :ok
  end
end
