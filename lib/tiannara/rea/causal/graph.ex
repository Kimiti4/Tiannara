defmodule Tiannara.REA.Causal.Graph do
  @moduledoc """
  Registry of all causal channels in Tiannara.
  
  This is the single source of truth for cross-level causality.
  Sentinel queries this to understand how scales are coupled.
  The UniversalEvolutionEngine reads it to compute pressure fields.
  """
  use GenServer
  
  alias Tiannara.REA.Causal.{Channel, Signal}
  
  @type inflight :: %{
    channel_id: binary(),
    signal: Signal.t(),
    arrives_at: non_neg_integer()
  }
  
  @max_history 1000
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  # --- Client API ---
  
  @spec register(Channel.t()) :: :ok
  def register(%Channel{} = ch), do: GenServer.call(__MODULE__, {:register, ch})
  
  @spec load_topology([Channel.t()]) :: :ok
  def load_topology(channels) when is_list(channels) do
    Enum.each(channels, &register/1)
    :ok
  end
  
  @spec set_enabled(binary(), boolean()) :: :ok
  def set_enabled(id, enabled?), do: GenServer.call(__MODULE__, {:set_enabled, id, enabled?})
  
  @spec incoming(atom()) :: [Channel.t()]
  def incoming(population), do: GenServer.call(__MODULE__, {:incoming, population})
  
  @spec outgoing(atom()) :: [Channel.t()]
  def outgoing(population), do: GenServer.call(__MODULE__, {:outgoing, population})
  
  @spec all() :: [Channel.t()]
  def all, do: GenServer.call(__MODULE__, :all)
  
  @spec emit(Signal.t()) :: :ok
  def emit(%Signal{} = sig), do: GenServer.cast(__MODULE__, {:emit, sig})
  
  @spec collect_pressures(atom(), non_neg_integer()) :: %{Signal.signal_type() => float()}
  def collect_pressures(target_population, epoch) do
    GenServer.call(__MODULE__, {:collect, target_population, epoch}, :infinity)
  end
  
  @spec flush() :: :ok
  def flush, do: GenServer.call(__MODULE__, :flush)
  
  # NEW: Observe actual signal propagation for a channel
  @spec observe_channel(binary()) :: %{
    signal_avg: float(),
    delivered_pressure: float(),
    sample_count: integer(),
    last_epoch: non_neg_integer()
  } | nil
  def observe_channel(channel_id), do: GenServer.call(__MODULE__, {:observe, channel_id})
  
  # NEW: Get full history for a channel (for path analysis)
  @spec channel_history(binary()) :: [%{epoch: non_neg_integer(), signal_avg: float(), delivered_pressure: float()}]
  def channel_history(channel_id), do: GenServer.call(__MODULE__, {:history, channel_id})
  
  # NEW: Get all channel histories (for bulk analysis)
  @spec all_channel_histories() :: %{binary() => [%{epoch: non_neg_integer(), signal_avg: float(), delivered_pressure: float()}]}
  def all_channel_histories, do: GenServer.call(__MODULE__, :all_histories)
  
  # --- Server ---
  
  @impl true
  def init(_opts) do
    state = %{
      channels: %{},              # id -> Channel
      by_target: %{},             # population -> [channel_id]
      by_source: %{},             # population -> [channel_id]
      inflight: [],               # [%{channel_id, signal, arrives_at}]
      pending_signals: %{},       # channel_id -> [Signal.t()] for current epoch
      channel_signals: %{},       # channel_id -> [Signal.t()] for current epoch
      channel_history: %{}        # channel_id -> [%{epoch, signal_avg, delivered_pressure}]
    }
    {:ok, state}
  end
  
  @impl true
  def handle_call({:register, ch}, _from, state) do
    new_channels = Map.put(state.channels, ch.id, ch)
    new_by_target = Map.update(state.by_target, ch.target.population, [ch.id], &[ch.id | &1])
    new_by_source = Map.update(state.by_source, ch.source.population, [ch.id], &[ch.id | &1])
    {:reply, :ok, %{state |
      channels: new_channels,
      by_target: new_by_target,
      by_source: new_by_source
    }}
  end
  
  @impl true
  def handle_call({:set_enabled, id, enabled?}, _from, state) do
    case Map.get(state.channels, id) do
      nil -> {:reply, :ok, state}
      ch ->
        updated = %{ch | enabled: enabled?}
        {:reply, :ok, %{state | channels: Map.put(state.channels, id, updated)}}
    end
  end
  
  @impl true
  def handle_call({:incoming, pop}, _from, state) do
    result =
      state.by_target
      |> Map.get(pop, [])
      |> Enum.map(&Map.get(state.channels, &1))
      |> Enum.filter(& &1.enabled)
    {:reply, result, state}
  end
  
  @impl true
  def handle_call({:outgoing, pop}, _from, state) do
    result =
      state.by_source
      |> Map.get(pop, [])
      |> Enum.map(&Map.get(state.channels, &1))
      |> Enum.filter(& &1.enabled)
    {:reply, result, state}
  end
  
  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.values(state.channels), state}
  end
  
  @impl true
  def handle_call({:collect, target_pop, epoch}, _from, state) do
    channels =
      state.by_target
      |> Map.get(target_pop, [])
      |> Enum.map(&Map.get(state.channels, &1))
      |> Enum.filter(& &1.enabled)
      
    target_channel_ids = Enum.map(channels, & &1.id)
    
    # Only extract arriving signals for THIS target population's channels
    {arriving, other_inflight} = Enum.split_with(state.inflight, fn item -> 
      item.arrives_at <= epoch and item.channel_id in target_channel_ids
    end)
    
    # Prevent memory leaks from extinct populations: purge signals strictly in the past
    cleaned_inflight = Enum.reject(other_inflight, &(&1.arrives_at < epoch))
    
    by_channel = Enum.group_by(arriving, & &1.channel_id, & &1.signal)
    
    pressures =
      channels
      |> Enum.map(fn ch ->
        arrived = Map.get(by_channel, ch.id, [])
        decayed = Enum.map(arrived, fn sig ->
          age = epoch - sig.emitted_epoch
          %{sig | value: sig.value * :math.pow(ch.decay, max(age - ch.delay, 0))}
        end)
        signal_avg = Channel.mean(decayed)
        value = signal_avg * ch.weight
        
        # Record actual propagation for observation
        history_entry = %{epoch: epoch, signal_avg: signal_avg, delivered_pressure: value}
        new_history = [history_entry | Map.get(state.channel_history, ch.id, [])] |> Enum.take(@max_history)
        
        {ch.target.signal, value, ch.id, new_history}
      end)
      |> Enum.reduce({%{}, state.channel_history}, fn {signal_type, value, ch_id, hist}, {press_acc, hist_acc} ->
        press = Map.update(press_acc, signal_type, value, &(&1 + value))
        hist_acc = Map.put(hist_acc, ch_id, hist)
        {press, hist_acc}
      end)
    
    # State update sets inflight to cleaned_inflight
    {:reply, elem(pressures, 0), %{state | inflight: cleaned_inflight, channel_history: elem(pressures, 1), channel_signals: %{}}}
  end
  
  @impl true
  def handle_call({:observe, ch_id}, _from, state) do
    history = Map.get(state.channel_history, ch_id, [])
    result = case history do
      [] -> nil
      entries ->
        latest = hd(entries)
        %{
          signal_avg: latest.signal_avg,
          delivered_pressure: latest.delivered_pressure,
          sample_count: length(entries),
          last_epoch: latest.epoch
        }
    end
    {:reply, result, state}
  end
  
  @impl true
  def handle_call({:history, ch_id}, _from, state) do
    history = Map.get(state.channel_history, ch_id, []) |> Enum.reverse()
    {:reply, history, state}
  end
  
  @impl true
  def handle_call(:all_histories, _from, state) do
    {:reply, state.channel_history, state}
  end
  
  @impl true
  def handle_call(:flush, _from, _state) do
    {:reply, :ok, %{channels: %{}, by_target: %{}, by_source: %{}, inflight: [], pending_signals: %{}, channel_signals: %{}, channel_history: %{}}}
  end
  
  @impl true
  def handle_cast({:emit, sig}, state) do
    matching_channels =
      state.by_source
      |> Map.get(sig.source_population, [])
      |> Enum.map(&Map.get(state.channels, &1))
      |> Enum.filter(&(&1.enabled && &1.source.signal == sig.type))
    
    new_inflight =
      Enum.map(matching_channels, fn ch ->
        %{channel_id: ch.id, signal: sig, arrives_at: sig.emitted_epoch + ch.delay}
      end)
    
    # Track signals per channel for observation
    new_channel_signals =
      Enum.reduce(matching_channels, state.channel_signals, fn ch, acc ->
        Map.update(acc, ch.id, [sig], &[sig | &1])
      end)
    
    {:noreply, %{state | inflight: state.inflight ++ new_inflight, channel_signals: new_channel_signals}}
  end
end
