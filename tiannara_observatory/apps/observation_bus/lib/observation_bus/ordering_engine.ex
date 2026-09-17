defmodule ObservationBus.OrderingEngine do
  @moduledoc """
  Global deterministic ordering engine.

  Every event receives four levels of sequencing:
    1. **Global Sequence** — monotonically increasing across the entire bus
    2. **Local Sequence** — monotonically increasing per source/domain
    3. **Replay Sequence** — deterministic ordering for replay
    4. **Causal Sequence** — Lamport-clock-style causal ordering
  """

  use GenServer

  alias ObservationBus.Event

  @doc """
  Assigns ordering sequences to an event.
  """
  @spec order(Event.t()) :: Event.t()
  def order(%Event{} = event) do
    GenServer.call(__MODULE__, {:order, event})
  end

  @doc """
  Returns the current global counter value.
  """
  @spec global_counter() :: non_neg_integer()
  def global_counter do
    GenServer.call(__MODULE__, :global_counter)
  end

  @doc """
  Returns the current local counter for a domain.
  """
  @spec local_counter(String.t()) :: non_neg_integer()
  def local_counter(domain) do
    GenServer.call(__MODULE__, {:local_counter, domain})
  end

  # GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{global: 0, locals: %{}, replay: 0, causal: 0}}
  end

  @impl true
  def handle_call({:order, %Event{domain: domain} = event}, _from, state) do
    global = state.global + 1
    local = Map.get(state.locals, domain, 0) + 1
    replay = state.replay + 1
    causal = state.causal + 1

    ordered = %{
      event
      | global_sequence: global,
        local_sequence: local,
        replay_sequence: replay,
        causal_sequence: causal
    }

    new_state = %{
      state
      | global: global,
        locals: Map.put(state.locals, domain, local),
        replay: replay,
        causal: causal
    }

    {:reply, ordered, new_state}
  end

  @impl true
  def handle_call(:global_counter, _from, state) do
    {:reply, state.global, state}
  end

  @impl true
  def handle_call({:local_counter, domain}, _from, state) do
    {:reply, Map.get(state.locals, domain, 0), state}
  end
end
