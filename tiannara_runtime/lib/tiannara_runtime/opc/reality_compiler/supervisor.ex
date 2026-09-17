defmodule Tiannara.OPC.RealityCompiler.Supervisor do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Schedule periodic compilation ticks
    Process.send_after(self(), :compile_tick, 5000)  # Every 5 seconds
    
    {:ok, %{buffer: [], compiled_rules: []}}
  end

  def handle_cast({:ingest_event, event}, state) do
    new_buffer = [event | state.buffer]

    {:noreply, %{state | buffer: new_buffer}}
  end

  def handle_info(:compile_tick, state) do
    rules =
      state.buffer
      |> Tiannara.OPC.RealityCompiler.CausalSegmenter.segment()
      |> Tiannara.OPC.RealityCompiler.PatternEngine.extract()
      |> Tiannara.OPC.RealityCompiler.RuleCompiler.compile()

    Tiannara.OPC.RealityCompiler.InjectionEngine.inject(rules)

    # Schedule next tick
    Process.send_after(self(), :compile_tick, 5000)

    {:noreply, %{state | buffer: [], compiled_rules: rules}}
  end

  # Define child_spec for supervisor compatibility
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
