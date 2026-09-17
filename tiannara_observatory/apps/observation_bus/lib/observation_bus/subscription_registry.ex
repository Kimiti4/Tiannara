defmodule ObservationBus.SubscriptionRegistry do
  @moduledoc """
  Manages subscriber registrations for constitutional topics.

  Subscribers are processes (pids) that register interest in topic patterns.
  Wildcard `:*:` matches any segment.

  Uses Elixir's built-in `Registry` for OTP-integrated subscriber management.
  """

  @doc """
  Starts the subscription registry.
  """
  def start_link(_opts \\ []) do
    Registry.start_link(
      keys: :duplicate,
      name: __MODULE__,
      metadata: fn {pid, topic_pattern} -> %{pid: pid, topic: topic_pattern, subscribed_at: DateTime.utc_now()} end
    )
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

  @doc """
  Subscribes a pid to a topic pattern.
  """
  @spec subscribe(pid(), String.t(), keyword()) :: :ok
  def subscribe(pid, topic_pattern, _opts \\ []) do
    Registry.register(__MODULE__, topic_pattern, {pid, topic_pattern})
    :ok
  end

  @doc """
  Unsubscribes a pid from a topic pattern.
  """
  @spec unsubscribe(pid(), String.t()) :: :ok
  def unsubscribe(_pid, topic_pattern) do
    Registry.unregister(__MODULE__, topic_pattern)
    :ok
  end

  @doc """
  Finds all subscribers whose registered patterns match the given topic.
  """
  @spec subscribers_for(String.t()) :: list(pid())
  def subscribers_for(topic) do
    __MODULE__
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.filter(fn {pattern, _pid, _value} -> ObservationBus.TopicRegistry.match?(topic, pattern) end)
    |> Enum.map(fn {_pattern, _pid, {sub_pid, _topic_pattern}} -> sub_pid end)
    |> Enum.uniq()
  end

  @doc """
  Returns all active subscriptions for diagnostics.
  """
  @spec list() :: list(map())
  def list do
    __MODULE__
    |> Registry.select([{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
    |> Enum.map(fn {pattern, _pid, {sub_pid, _topic_pattern}} ->
      %{
        pid: sub_pid,
        topic: pattern,
        subscribed_at: DateTime.utc_now(),
        alive: Process.alive?(sub_pid)
      }
    end)
  end

  @doc """
  Returns subscriber count for a topic.
  """
  @spec subscriber_count(String.t()) :: non_neg_integer()
  def subscriber_count(topic) do
    subscribers_for(topic) |> length()
  end

  @doc """
  Returns total unique subscriber count.
  """
  @spec total_subscribers() :: non_neg_integer()
  def total_subscribers do
    list()
    |> Enum.map(fn s -> s.pid end)
    |> Enum.uniq()
    |> length()
  end
end
