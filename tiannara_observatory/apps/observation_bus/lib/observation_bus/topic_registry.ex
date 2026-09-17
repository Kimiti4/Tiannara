defmodule ObservationBus.TopicRegistry do
  @moduledoc """
  Strongly-typed constitutional topic registry.

  Topics follow the pattern `constitution.<domain>.<action>`.

  Examples:
    - `constitution.runtime.health`
    - `constitution.discovery.created`
    - `constitution.experiment.completed`
    - `constitution.knowledge.updated`
    - `constitution.evolution.deployed`
    - `constitution.certification.failed`
  """

  use GenServer

  alias ObservationBus.Event

  @doc """
  Registers a topic with its metadata.

  Topics are auto-registered when first used, but can be pre-registered
  with documentation and schema hints.
  """
  @spec register(String.t(), keyword()) :: :ok
  def register(topic, opts \\ []) do
    GenServer.call(__MODULE__, {:register, topic, opts})
  end

  @doc """
  Returns all registered topics.
  """
  @spec list() :: list(map())
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @doc """
  Returns the derived topic for an event.
  """
  def topic_for(%Event{domain: domain}, action) do
    "constitution.#{domain}.#{action}"
  end

  @doc """
  Validates that a topic string is well-formed.
  """
  def valid?(topic) when is_binary(topic) do
    String.starts_with?(topic, "constitution.") &&
      String.split(topic, ".") |> length() >= 3
  end

  def valid?(_), do: false

  @doc """
  Matches a topic against a pattern with `:*:` wildcard support.
  """
  def match?(topic, pattern) do
    t_parts = String.split(topic, ".")
    p_parts = String.split(pattern, ".")

    Enum.zip(t_parts, p_parts)
    |> Enum.all?(fn {t, p} -> p == ":*:" || t == p end) &&
      length(t_parts) == length(p_parts)
  end

  # GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{topics: %{}, topic_list: []}}
  end

  @impl true
  def handle_call({:register, topic, opts}, _from, state) do
    if Map.has_key?(state.topics, topic) do
      {:reply, :ok, state}
    else
      entry = %{
        topic: topic,
        registered_at: DateTime.utc_now(),
        description: Keyword.get(opts, :description, ""),
        schema: Keyword.get(opts, :schema, :any)
      }
      new_topics = Map.put(state.topics, topic, entry)
      {:reply, :ok, %{state | topics: new_topics, topic_list: [entry | state.topic_list]}}
    end
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, state.topic_list, state}
  end
end
