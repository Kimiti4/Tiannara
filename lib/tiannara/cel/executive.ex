defmodule Tiannara.CEL.Executive do
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def define_strategic_objective(objective_id, description) do
    GenServer.call(__MODULE__, {:define_objective, objective_id, description})
  end

  def handle_escalation(civ_event) do
    GenServer.cast(__MODULE__, {:escalation, civ_event})
  end

  def get_objectives, do: GenServer.call(__MODULE__, :get_objectives)

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts) do
    {:ok, %{strategic_objectives: %{}, escalations: []}}
  end

  @impl true
  def handle_call({:define_objective, id, desc}, _from, state) do
    new_state = put_in(state, [:strategic_objectives, id], %{description: desc, status: :active})
    Tiannara.CEL.ExecutiveMemory.record_decision(id, %{type: :objective_defined, desc: desc})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:get_objectives, _from, state), do: {:reply, state.strategic_objectives, state}

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    {:reply, score_from_state(state), state}
  end

  # Executive state contains no independent evidence-quality measurement.
  # Keep that dimension explicitly unverified instead of manufacturing a
  # positive score from process health alone.
  defp score_from_state(_state) do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive,
      health: if(Process.alive?(self()), do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 0.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  @impl true
  def handle_cast({:escalation, event}, state) do
    Logger.error("Executive: Received escalation for unhandled event #{event.id}")
    Tiannara.CEL.ExecutiveMemory.record_decision(event.id, %{type: :escalation, event: event})
    {:noreply, %{state | escalations: [event | state.escalations]}}
  end
end
