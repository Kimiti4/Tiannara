defmodule Tiannara.CIS.Supervisor do
  @moduledoc "Cognitive Immune System — coordinates immune response, collapse prediction, and regulation"
  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.CIS.CISRegistry,
      Tiannara.CIS.CollapsePredictor,
      {Tiannara.CIS.ImmuneDecisionEngine, []},
      {Tiannara.CIS.RegulationExecutor, []}
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Tiannara.CIS.CollapsePredictor do
  use GenServer
  require Logger

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_) do
    Logger.info("[CIS] CollapsePredictor initialized (grounded)")
    {:ok, %{threat_level: 0.0, active_threats: []}}
  end

  # API: nil/missing -> unknown first (nil is an atom in Elixir)
  def assess_risk(nil), do: {:unknown, :insufficient_evidence, [missing_fields: [:telemetry]]}
  def assess_risk(telemetry) when is_map(telemetry) do
    GenServer.call(__MODULE__, {:assess_telemetry, telemetry})
  end
  def assess_risk(subsystem) when is_atom(subsystem) do
    case gather_live_telemetry() do
      {:ok, telemetry} -> GenServer.call(__MODULE__, {:assess, subsystem, telemetry})
      {:unknown, reason, fields} -> {:unknown, reason, [missing_fields: fields]}
      other -> other
    end
  end
  def assess_risk(_), do: {:unknown, :insufficient_evidence, [missing_fields: [:telemetry]]}

  @impl true
  def handle_call({:assess, subsystem, telemetry}, _from, state) do
    case validate_telemetry(telemetry) do
      {:ok, _} ->
        result = compute_grounded_risk(subsystem, telemetry)
        {:reply, result, %{state | threat_level: result.risk_score, active_threats: result.contributing_factors}}
      {:unknown, reason, fields} ->
        {:reply, {:unknown, reason, [missing_fields: fields]}, state}
    end
  end
  def handle_call({:assess_telemetry, telemetry}, _from, state) do
    case validate_telemetry(telemetry) do
      {:ok, _} ->
        result = compute_grounded_risk(:telemetry_map, telemetry)
        {:reply, result, %{state | threat_level: result.risk_score, active_threats: result.contributing_factors}}
      {:unknown, reason, fields} ->
        {:reply, {:unknown, reason, [missing_fields: fields]}, state}
    end
  end

  defp gather_live_telemetry do
    results = [
      {:executive_memory_health, attempt_health(fn -> Tiannara.CEL.Services.ExecutiveMemory.health() end)},
      {:event_store_healthy, attempt_health(fn -> Tiannara.CEL.Services.EventStore.healthy?() end)},
      {:event_bus_health, attempt_health(fn -> Tiannara.CEL.Services.EventBus.health() end)}
    ]
    missing = for {k, {:error, _}} <- results, do: k
    if missing == [] do
      telemetry = Map.new(results, fn {k, {:ok, v}} -> {k, v} end)
        |> Map.merge(%{memory_pressure: 0.0, dets_health: true})
      {:ok, telemetry}
    else
      {:unknown, :insufficient_evidence, missing}
    end
  end

  defp attempt_health(fun) do
    try do {:ok, fun.()} catch _, _ -> {:error, :unavailable} end
  rescue _ -> {:error, :unavailable}
  end

  defp validate_telemetry(nil), do: {:unknown, :insufficient_evidence, [:telemetry]}
  defp validate_telemetry(telemetry) when not is_map(telemetry), do: {:unknown, :insufficient_evidence, [:telemetry]}
  defp validate_telemetry(telemetry) when is_map(telemetry) do
    required = [:executive_memory_health, :event_store_healthy, :event_bus_health]
    missing = Enum.filter(required, fn k ->
      not Map.has_key?(telemetry, k) or Map.get(telemetry, k) in [nil, :stale, :unknown]
    end)
    if missing == [], do: {:ok, telemetry}, else: {:unknown, :insufficient_evidence, missing}
  end

  defp compute_grounded_risk(subsystem, telemetry) do
    base = 0.05
    {risk1, f1} = if telemetry[:executive_memory_health] != :healthy do
      {0.35, [{:executive_memory_health, telemetry[:executive_memory_health], [weight: 0.35]}]}
    else {0.0, []} end
    {risk2, f2} = if telemetry[:event_store_healthy] == false do
      {0.35, [{:event_store_healthy, false, [weight: 0.35]}]}
    else {0.0, []} end
    {risk3, f3} = if telemetry[:event_bus_health] != :healthy do
      {0.15, [{:event_bus_health, telemetry[:event_bus_health], [weight: 0.15]}]}
    else {0.0, []} end
    mem_pressure = Map.get(telemetry, :memory_pressure, 0.0)
    {risk4, f4} = if is_number(mem_pressure) and mem_pressure > 0.8 do
      v = (mem_pressure - 0.8) * 1.5
      {v, [{:memory_pressure, mem_pressure, [weight: v]}]}
    else {0.0, []} end
    dets_health = Map.get(telemetry, :dets_health, true)
    {risk5, f5} = if dets_health == false do
      {0.25, [{:dets_health, false, [weight: 0.25]}]}
    else {0.0, []} end

    total = base + risk1 + risk2 + risk3 + risk4 + risk5
    risk_score = total |> max(0.0) |> min(1.0) |> Float.round(4)
    factors = f1 ++ f2 ++ f3 ++ f4 ++ f5
    evidence_count = map_size(telemetry)

    %{
      subsystem: subsystem,
      risk_score: risk_score,
      collapse_risk: risk_score,
      evidence_count: evidence_count,
      contributing_factors: factors,
      timestamp: DateTime.utc_now()
    }
  end
end

defmodule Tiannara.CIS.ImmuneDecisionEngine do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[CIS] ImmuneDecisionEngine initialized")
    {:ok, %{response_plan: :monitor, active_responses: %{}}}
  end
  def evaluate(pathogen, severity), do: GenServer.call(__MODULE__, {:evaluate, pathogen, severity})
  @impl true
  def handle_call({:evaluate, pathogen, severity}, _from, state) do
    plan = if severity > 0.7, do: :quarantine, else: :monitor
    {:reply, %{pathogen: pathogen, severity: severity, response: plan}, %{state | response_plan: plan}}
  end
end

defmodule Tiannara.CIS.RegulationExecutor do
  use GenServer
  require Logger
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_) do
    Logger.info("[CIS] RegulationExecutor initialized")
    {:ok, %{executed_actions: [], backoff: 0}}
  end
  def execute(action, target), do: GenServer.call(__MODULE__, {:execute, action, target})
  @impl true
  def handle_call({:execute, action, target}, _from, state) do
    Logger.info("[CIS] Executing #{action} on #{target}")
    {:reply, :ok, %{state | executed_actions: [{action, target, DateTime.utc_now()} | state.executed_actions]}}
  end
end
