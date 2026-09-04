defmodule Tiannara.CEL.Services.EventBus.Safe do
  @moduledoc """
  Safe wrapper around EventBus for graceful degradation.

  All publish/subscribe operations are wrapped in try/rescue so that
  a failing EventBus never crashes the caller.
  """
  alias Tiannara.CEL.Services.EventBus

  def publish(topic, payload, opts \\ []) do
    try do
      EventBus.publish(topic, payload, opts)
    rescue
      _ -> {:error, :event_bus_unavailable}
    catch
      :exit, _ -> {:error, :event_bus_unavailable}
    end
  end

  def subscribe(topic, handler_pid \\ self()) do
    try do
      EventBus.subscribe(topic, handler_pid)
    rescue
      _ -> {:error, :event_bus_unavailable}
    catch
      :exit, _ -> {:error, :event_bus_unavailable}
    end
  end

  def unsubscribe(topic, handler_pid) do
    try do
      EventBus.unsubscribe(topic, handler_pid)
    rescue
      _ -> {:error, :event_bus_unavailable}
    catch
      :exit, _ -> {:error, :event_bus_unavailable}
    end
  end

  def replay(topic, since_offset \\ 0) do
    try do
      EventBus.replay(topic, since_offset)
    rescue
      _ -> {:error, :event_bus_unavailable}
    catch
      :exit, _ -> {:error, :event_bus_unavailable}
    end
  end

  def healthy? do
    try do
      EventBus.healthy?()
    rescue
      _ -> false
    catch
      :exit, _ -> false
    end
  end
end
