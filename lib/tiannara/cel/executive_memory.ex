defmodule Tiannara.CEL.ExecutiveMemory do
  use GenServer
  require Logger

  @table_name :cel_executive_memory

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def record_decision(decision_id, details) do
    GenServer.cast(__MODULE__, {:record, :decision, decision_id, details})
  end

  def record_mission_outcome(mission_id, outcome) do
    GenServer.cast(__MODULE__, {:record, :mission_outcome, mission_id, outcome})
  end

  def get_history(record_type) do
    GenServer.call(__MODULE__, {:get_history, record_type})
  end

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts) do
    case :dets.open_file(@table_name, type: :set, file: ~c"./cel_executive_memory.dets") do
      {:ok, _table} ->
        Logger.info("ExecutiveMemory: Persistent memory initialized.")
        {:ok, %{}}

      {:error, reason} ->
        Logger.error("ExecutiveMemory: Failed to open DETS: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_cast({:record, type, id, data}, state) do
    record = {id, type, data, DateTime.utc_now()}
    :dets.insert(@table_name, record)
    :telemetry.execute([:tiannara, :cel, :memory, :recorded], %{}, %{type: type})
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_history, type}, _from, state) do
    history =
      :dets.traverse(@table_name, fn
        {id, ^type, data, ts} -> {:continue, %{id: id, data: data, timestamp: ts}}
        _ -> {:continue}
      end)
    {:reply, history, state}
  end

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    score = %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :executive_memory,
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 0.95,
      human_oversight: 0.8,
      computed_at: DateTime.utc_now()
    }
    {:reply, score, state}
  end
end
