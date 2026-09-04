defmodule Tiannara.CEL.MissionDirector do
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def create_mission(mission_id, objective_id, scope) do
    GenServer.call(__MODULE__, {:create, mission_id, objective_id, scope})
  end

  def update_mission_status(mission_id, status) do
    GenServer.cast(__MODULE__, {:update_status, mission_id, status})
  end

  def get_mission(mission_id), do: GenServer.call(__MODULE__, {:get, mission_id})

  def list_missions, do: GenServer.call(__MODULE__, :list)

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts), do: {:ok, %{missions: %{}}}

  @impl true
  def handle_call({:create, id, obj_id, scope}, _from, state) do
    mission = %{
      id: id, objective_id: obj_id, scope: scope,
      status: :planning, created_at: DateTime.utc_now()
    }
    new_state = put_in(state, [:missions, id], mission)
    Tiannara.CEL.ExecutiveMemory.record_decision(id, %{type: :mission_created, scope: scope})
    {:reply, {:ok, mission}, new_state}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, Map.get(state.missions, id, {:error, :not_found}), state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, Map.values(state.missions), state}
  end

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    score = %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :mission_director,
      health: 1.0,
      constitutional_alignment: 0.95,
      transparency: 0.85,
      explainability: 0.8,
      evidence_quality: 0.85,
      human_oversight: 0.75,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end

  @impl true
  def handle_cast({:update_status, id, status}, state) do
    if Map.has_key?(state.missions, id) do
      new_state = put_in(state, [:missions, id, :status], status)

      if status == :completed do
        Logger.info("MissionDirector: Mission #{id} completed. Triggering knowledge preservation.")
        Tiannara.CEL.ExecutiveMemory.record_mission_outcome(id, %{status: :completed, completed_at: DateTime.utc_now()})
      end

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end
end
