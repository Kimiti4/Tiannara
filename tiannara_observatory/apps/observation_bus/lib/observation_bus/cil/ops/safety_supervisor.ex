defmodule ObservationBus.CIL.Ops.SafetySupervisor do
  use GenServer, restart: :permanent
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: opts[:name] || __MODULE__)
  end

  def status, do: GenServer.call(__MODULE__, :status)
  def halt(reason), do: GenServer.cast(__MODULE__, {:halt, reason})
  def resume, do: GenServer.cast(__MODULE__, :resume)

  @impl true
  def init(_opts) do
    state = %{
      mode: :monitoring,
      halted: false,
      halt_reason: nil,
      safety_triggers: [],
      interventions: [
        %{id: "si_1", type: :runaway_automation, detected: false, threshold: 0.95, current_value: 0.72},
        %{id: "si_2", type: :cascading_failure, detected: false, threshold: 0.8, current_value: 0.45},
        %{id: "si_3", type: :constitutional_violation, detected: false, threshold: 1.0, current_value: 0.12},
        %{id: "si_4", type: :resource_exhaustion, detected: false, threshold: 0.9, current_value: 0.76},
      ],
      halted_at: nil,
      resumed_at: nil
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:status, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast({:halt, reason}, state) do
    {:noreply, %{state | halted: true, halt_reason: reason, mode: :halted, halted_at: DateTime.utc_now()}}
  end

  def handle_cast(:resume, state) do
    {:noreply, %{state | halted: false, halt_reason: nil, mode: :monitoring, resumed_at: DateTime.utc_now()}}
  end
end
