defmodule Tiannara.Certification.Protocol do
  use GenServer
  require Logger

  @statuses [:passing, :failing, :inconclusive]
  @tier_keys [:cognitive, :scientific, :constitutional, :civilizational, :autonomous_runtime, :discovery]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run_full_certification do
    start_time = System.monotonic_time(:millisecond)

    tiers = %{
      cognitive: Tiannara.Certification.Tier1Cognitive.run_all(),
      scientific: Tiannara.Certification.Tier2Scientific.run_all(),
      constitutional: Tiannara.Certification.Tier3Constitutional.run_all(),
      civilizational: Tiannara.Certification.Tier4Civilizational.run_all(),
      autonomous_runtime: Tiannara.Certification.Tier5AutonomousRuntime.run_all(),
      discovery: Tiannara.Certification.Tier6Discovery.run_all()
    }

    duration = System.monotonic_time(:millisecond) - start_time
    all_results = Enum.flat_map(tiers, fn {_key, tier} -> Map.get(tier, :details, []) end)
    unknown_count = Enum.count(all_results, &(Map.get(&1, :status) == :unknown))
    failed_count = Enum.count(all_results, &(Map.get(&1, :status) == :error or Map.get(&1, :passed) == false))

    status =
      cond do
        unknown_count > 0 -> :inconclusive
        failed_count == 0 -> :passing
        true -> :failing
      end

    report = %{
      overall_status: status,
      tier_statuses: Map.new(tiers, fn {k, v} -> {k, Map.get(v, :status, :inconclusive)} end),
      tier_scores: Map.new(tiers, fn {k, v} -> {k, Map.get(v, :score, 0.0)} end),
      total_exercises: Enum.sum(Enum.map(tiers, fn {_k, v} -> Map.get(v, :exercises_completed, 0) end)),
      total_passed: Enum.sum(Enum.map(tiers, fn {_k, v} -> Map.get(v, :exercises_passed, 0) end)),
      unknown_exercises: unknown_count,
      failed_exercises: failed_count,
      duration_ms: duration,
      timestamp: DateTime.utc_now(),
      details: tiers
    }

    Logger.info("[TCCP] Full certification: #{report.overall_status} — #{report.total_passed} passed, #{unknown_count} unknown, #{failed_count} failed")
    case GenServer.call(__MODULE__, {:store_report, report}) do
      :ok -> report
      {:error, reason} -> Map.put(report, :overall_status, :inconclusive) |> Map.put(:persistence_error, reason)
    end
  end

  def run_tier(:cognitive), do: Tiannara.Certification.Tier1Cognitive.run_all()
  def run_tier(:scientific), do: Tiannara.Certification.Tier2Scientific.run_all()
  def run_tier(:constitutional), do: Tiannara.Certification.Tier3Constitutional.run_all()
  def run_tier(:civilizational), do: Tiannara.Certification.Tier4Civilizational.run_all()
  def run_tier(:autonomous_runtime), do: Tiannara.Certification.Tier5AutonomousRuntime.run_all()
  def run_tier(:discovery), do: Tiannara.Certification.Tier6Discovery.run_all()

  def last_report, do: GenServer.call(__MODULE__, :last_report)

  @impl true
  def init(_opts), do: {:ok, %{last_certification: nil, history: []}}

  @impl true
  def handle_call({:store_report, report}, _from, state) do
    case persist_report(report) do
      :ok -> {:reply, :ok, %{state | last_certification: report, history: [report | state.history] |> Enum.take(100)}}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:last_report, _from, state), do: {:reply, state.last_certification, state}

  defp persist_report(report) do
    path = System.get_env("TIANNARA_CERTIFICATION_REPORT") || "tmp/certification/latest.json"
    dir = Path.dirname(path)

    with :ok <- File.mkdir_p(dir),
         json <- Jason.encode!(report, pretty: true),
         :ok <- File.write(path, json) do
      :ok
    end
  rescue
    error -> {:error, Exception.message(error)}
  end
end
