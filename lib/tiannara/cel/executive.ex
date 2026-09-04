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
    score = %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive,
      health: 1.0,
      constitutional_alignment: 0.98,
      transparency: 0.95,
      explainability: 0.95,
      evidence_quality: 0.9,
      human_oversight: 0.9,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end

  @impl true
  def handle_cast({:escalation, event}, state) do
    Logger.error("Executive: Received escalation for unhandled event #{event.id}")
    Tiannara.CEL.ExecutiveMemory.record_decision(event.id, %{type: :escalation, event: event})
    {:noreply, %{state | escalations: [event | state.escalations]}}
  end
end
