defmodule Tiannara.ASC.Core.EventBus do
  @moduledoc """
  Cross-subsystem signal plane over the duplicate PubSub registry.

  Pure wrapper around `Registry` — no process of its own. Subscribers
  register per-topic; publishers dispatch to all subscribers of a topic.
  """

  @registry Tiannara.ASC.Core.PubSub

  def subscribe(topic) do
    Registry.register(@registry, topic, [])
    :ok
  end

  def publish(topic, event) do
    Registry.dispatch(@registry, topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:asc_event, topic, event})
    end)

    :ok
  end
end