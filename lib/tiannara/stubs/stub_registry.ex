defmodule Tiannara.StubRegistry do
  @moduledoc """
  Constitutional stub registry.

  Tracks all constitutional stubs: which subsystem they represent,
  which capability they provide, what phase they target for replacement,
  and how often they are called.

  Every stub call emits telemetry and is recorded here.
  """

  use GenServer

  require Logger

  defstruct entries: %{}

  @type entry :: %{
          subsystem: atom(),
          capability: atom(),
          phase: binary() | nil,
          status: :stub | :planned | :deprecated,
          first_call: integer(),
          last_call: integer(),
          call_count: non_neg_integer(),
          priority: :low | :medium | :high | :critical,
          replacement_module: module() | nil,
          module: module(),
          function: atom(),
          arity: non_neg_integer()
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{entries: %{}}}
  end

  @spec record_call(module(), atom(), non_neg_integer(), keyword()) :: :ok
  def record_call(module, function, arity, opts \\ []) do
    GenServer.cast(__MODULE__, {:record_call, module, function, arity, opts})
  end

  @spec list_stubs() :: list(entry())
  def list_stubs do
    GenServer.call(__MODULE__, :list_stubs)
  end

  @spec get_stub(module(), atom(), non_neg_integer()) :: entry() | nil
  def get_stub(module, function, arity) do
    GenServer.call(__MODULE__, {:get_stub, module, function, arity})
  end

  @spec stub_count() :: non_neg_integer()
  def stub_count do
    GenServer.call(__MODULE__, :stub_count)
  end

  @spec total_call_count() :: non_neg_integer()
  def total_call_count do
    GenServer.call(__MODULE__, :total_call_count)
  end

  @spec report() :: map()
  def report do
    GenServer.call(__MODULE__, :report)
  end

  @impl true
  def handle_cast({:record_call, module, function, arity, opts}, state) do
    key = {module, function, arity}
    now = System.monotonic_time(:millisecond)

    entry =
      case Map.get(state.entries, key) do
        nil ->
          %{
            subsystem: Keyword.get(opts, :subsystem, infer_subsystem(module)),
            capability: function,
            phase: Keyword.get(opts, :phase, nil),
            status: Keyword.get(opts, :status, :stub),
            first_call: now,
            last_call: now,
            call_count: 1,
            priority: Keyword.get(opts, :priority, :medium),
            replacement_module: Keyword.get(opts, :replacement_module, nil),
            module: module,
            function: function,
            arity: arity
          }

        existing ->
          %{existing | last_call: now, call_count: existing.call_count + 1}
      end

    :telemetry.execute(
      [:tiannara, :stub, :called],
      %{count: 1},
      %{
        module: module,
        function: function,
        arity: arity,
        subsystem: entry.subsystem,
        capability: entry.capability,
        phase: entry.phase
      }
    )

    {:noreply, %{state | entries: Map.put(state.entries, key, entry)}}
  end

  @impl true
  def handle_call(:list_stubs, _from, state) do
    {:reply, Map.values(state.entries), state}
  end

  @impl true
  def handle_call({:get_stub, module, function, arity}, _from, state) do
    {:reply, Map.get(state.entries, {module, function, arity}), state}
  end

  @impl true
  def handle_call(:stub_count, _from, state) do
    {:reply, map_size(state.entries), state}
  end

  @impl true
  def handle_call(:total_call_count, _from, state) do
    total =
      state.entries
      |> Map.values()
      |> Enum.reduce(0, &(&1.call_count + &2))

    {:reply, total, state}
  end

  @impl true
  def handle_call(:report, _from, state) do
    entries = Map.values(state.entries)

    report = %{
      total_stubs: length(entries),
      total_calls: Enum.reduce(entries, 0, &(&1.call_count + &2)),
      by_status: Enum.group_by(entries, & &1.status) |> Map.new(fn {k, v} -> {k, length(v)} end),
      by_priority:
        Enum.group_by(entries, & &1.priority) |> Map.new(fn {k, v} -> {k, length(v)} end),
      by_subsystem:
        Enum.group_by(entries, & &1.subsystem) |> Map.new(fn {k, v} -> {k, length(v)} end),
      stubs:
        entries
        |> Enum.sort_by(& &1.call_count, :desc)
        |> Enum.map(fn e ->
          %{
            module: e.module,
            function: e.function,
            arity: e.arity,
            subsystem: e.subsystem,
            phase: e.phase,
            status: e.status,
            priority: e.priority,
            calls: e.call_count
          }
        end)
    }

    {:reply, report, state}
  end

  defp infer_subsystem(module) do
    module
    |> Module.split()
    |> Enum.drop(1)
    |> Enum.take(1)
    |> case do
      [subsystem] -> String.to_atom(String.downcase(subsystem))
      _ -> :unknown
    end
  end
end
