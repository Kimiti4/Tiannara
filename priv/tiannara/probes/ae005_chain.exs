Mix.Task.run("app.config")
Process.flag(:trap_exit, true)

[mode, out_dir] = System.argv()
File.mkdir_p!(out_dir)

attempt = fn f ->
  try do {:ok, f.()} rescue e -> {:error, "rescue: #{Exception.message(e)}"} catch kind, reason -> {:error, "exit #{inspect(kind)}: #{inspect(reason)}"} end
end

to_jsonable = fn to_jsonable, term ->
  case term do
    {:ok, v} -> %{"ok" => to_jsonable.(to_jsonable, v)}
    {:error, m} -> %{"error" => to_jsonable.(to_jsonable, m)}
    %{__struct__: _} = s -> to_jsonable.(to_jsonable, Map.from_struct(s))
    tuple when is_tuple(tuple) -> tuple |> Tuple.to_list() |> then(fn l -> to_jsonable.(to_jsonable, l) end)
    list when is_list(list) -> Enum.map(list, &to_jsonable.(to_jsonable, &1))
    map when is_map(map) -> Map.new(map, fn {k, v} -> {to_string(k), to_jsonable.(to_jsonable, v)} end)
    pid when is_pid(pid) -> inspect(pid)
    ref when is_reference(ref) -> inspect(ref)
    bool when is_boolean(bool) -> bool
    atom when is_atom(atom) -> Atom.to_string(atom)
    other -> other
  end
end

grounded_patch = """
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
"""

result =
  case mode do
    "characterize" ->
      attempt.(fn ->
        # ensure CIS running in isolation (fresh VM has no app)
        {:ok, _} = Supervisor.start_link([Tiannara.CIS.Supervisor], strategy: :one_for_one, name: :ae005_char_sup)

        # Test determinism: 100 calls same subsystem
        samples = for _ <- 1..100 do
          Tiannara.CIS.CollapsePredictor.assess_risk(:reality_graph)
        end
        risks = Enum.map(samples, fn
          %{collapse_risk: r} -> r
          %{risk_score: r} -> r
          _ -> nil
        end) |> Enum.reject(&is_nil/1)
        unique_risks = risks |> Enum.uniq() |> length()
        variance = if length(risks) > 1, do: Enum.max(risks) - Enum.min(risks), else: 0.0

        # Test bounded uncertainty: missing telemetry -> does it invent probability?
        # baseline only has atom API, so we test nil via direct GenServer call to see fallback?
        # For baseline, nil not supported; we simulate missing evidence by checking if random fallback exists
        missing_behavior = attempt.(fn -> Tiannara.CIS.CollapsePredictor.assess_risk(nil) end)

        %{
          mode: "characterize",
          samples: Enum.take(risks, 5),
          unique_risk_count: unique_risks,
          variance: variance,
          is_random: unique_risks > 1 and variance > 0.01,
          missing_behavior: missing_behavior
        }
      end)

    "candidate" ->
      attempt.(fn ->
        Code.compile_string(grounded_patch)
        # restart CIS with new code
        # kill old supervisor if exists
        if pid = Process.whereis(:ae005_char_sup) do
          Process.exit(pid, :kill)
          Process.sleep(200)
        end
        if pid = Process.whereis(Tiannara.CIS.Supervisor) do
          Process.exit(pid, :kill)
          Process.sleep(200)
        end
        {:ok, _} = Supervisor.start_link([Tiannara.CIS.Supervisor], strategy: :one_for_one, name: :ae005_cand_sup)

        # Test 1: Determinism
        t1 = %{executive_memory_health: :healthy, event_store_healthy: true, event_bus_health: :healthy, memory_pressure: 0.2, dets_health: true}
        t1_runs = for _ <- 1..100, do: Tiannara.CIS.CollapsePredictor.assess_risk(t1)
        t1_scores = Enum.map(t1_runs, fn
          {:unknown, _, _} -> :unknown
          %{risk_score: r} -> r
          %{collapse_risk: r} -> r
        end)
        t1_deterministic = Enum.uniq(t1_scores) |> length() == 1

        # Test 2: Sensitivity
        t_healthy = %{executive_memory_health: :healthy, event_store_healthy: true, event_bus_health: :healthy, memory_pressure: 0.1, dets_health: true}
        t_degraded = %{executive_memory_health: :unhealthy, event_store_healthy: false, event_bus_health: :unhealthy, memory_pressure: 0.95, dets_health: false}
        s_healthy = Tiannara.CIS.CollapsePredictor.assess_risk(t_healthy)
        s_degraded = Tiannara.CIS.CollapsePredictor.assess_risk(t_degraded)
        healthy_score = case s_healthy do %{risk_score: r} -> r; %{collapse_risk: r} -> r; _ -> 0.0 end
        degraded_score = case s_degraded do %{risk_score: r} -> r; %{collapse_risk: r} -> r; _ -> 0.0 end
        degraded_factors = case s_degraded do %{contributing_factors: f} -> f; _ -> [] end

        # Test 3: Grounding (provenance)
        t_std = %{executive_memory_health: :healthy, event_store_healthy: true, event_bus_health: :healthy, memory_pressure: 0.3, dets_health: true}
        grounding = Tiannara.CIS.CollapsePredictor.assess_risk(t_std)
        has_provenance = match?(%{risk_score: _, evidence_count: _, contributing_factors: _}, grounding)

        # Test 4: Bounded uncertainty
        t_missing = %{event_store_healthy: true}
        t_nil = nil
        t_stale = %{executive_memory_health: :stale, event_store_healthy: true, event_bus_health: :healthy}
        r_missing = Tiannara.CIS.CollapsePredictor.assess_risk(t_missing)
        r_nil = Tiannara.CIS.CollapsePredictor.assess_risk(t_nil)
        r_stale = Tiannara.CIS.CollapsePredictor.assess_risk(t_stale)
        bounded_ok = match?({:unknown, :insufficient_evidence, _}, r_missing) and
                     match?({:unknown, :insufficient_evidence, _}, r_nil) and
                     match?({:unknown, :insufficient_evidence, _}, r_stale)

        %{
          mode: "candidate",
          determinism: %{pass: t1_deterministic, scores: Enum.take(t1_scores, 3)},
          sensitivity: %{healthy_score: healthy_score, degraded_score: degraded_score, degraded_factors: degraded_factors, pass: degraded_score > healthy_score + 0.2},
          grounding: %{result: grounding, pass: has_provenance},
          bounded_uncertainty: %{r_missing: r_missing, r_nil: r_nil, r_stale: r_stale, pass: bounded_ok}
        }
      end)
  end

IO.puts("AE005CHAIN_RESULT " <> Jason.encode!(to_jsonable.(to_jsonable, %{status: "complete", mode: mode, phase: result})))
