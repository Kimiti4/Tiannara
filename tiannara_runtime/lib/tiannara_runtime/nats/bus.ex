defmodule TiannaraRuntime.NATS.Bus do
  @registry :tiannara_nats_bus

  def start_link(_opts) do
    Registry.start_link(keys: :unique, name: @registry)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end

  def publish(subject, payload) when is_binary(subject) do
    encoded = if is_map(payload) or is_list(payload), do: Jason.encode!(payload), else: payload
    subscribers = Registry.lookup(@registry, :all)
    Enum.each(subscribers, fn {pid, _} ->
      send(pid, {:nats_message, subject, encoded})
    end)
    pattern_subscribers = Registry.lookup(@registry, :pattern)
    Enum.each(pattern_subscribers, fn {pid, patterns} ->
      if subject_matches_any?(subject, patterns) do
        send(pid, {:nats_message, subject, encoded})
      end
    end)
    :ok
  end

  def subscribe(subject) do
    Registry.register(@registry, :pattern, [subject])
    {:ok, subject}
  end

  def subscribe_all do
    Registry.register(@registry, :all, true)
    :ok
  end

  def unsubscribe(_subject) do
    Registry.unregister(@registry, :pattern)
    :ok
  end

  def subject_matches_any?(subject, patterns) when is_list(patterns) do
    Enum.any?(patterns, fn pattern -> subject_matches?(subject, pattern) end)
  end

  def subject_matches?(subject, pattern) do
    subject_parts = String.split(subject, ".")
    pattern_parts = String.split(pattern, ".")
    do_match(subject_parts, pattern_parts)
  end

  defp do_match(_, [">"]), do: true
  defp do_match([], []), do: true
  defp do_match([_ | _], []), do: false
  defp do_match([], [_ | _]), do: false
  defp do_match([_sh | st], ["*" | rp]) do
    do_match(st, rp)
  end
  defp do_match([h | st], [h | rp]) do
    do_match(st, rp)
  end
  defp do_match([_ | _], [_ | _]), do: false
end
