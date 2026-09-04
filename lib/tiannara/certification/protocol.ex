defmodule Tiannara.Certification.Protocol do
  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run_full_certification do
    start_time = System.monotonic_time(:millisecond)

    tier1 = Tiannara.Certification.Tier1Cognitive.run_all()
    tier2 = Tiannara.Certification.Tier2Scientific.run_all()
    tier3 = Tiannara.Certification.Tier3Constitutional.run_all()
    tier4 = Tiannara.Certification.Tier4Civilizational.run_all()
    tier5 = Tiannara.Certification.Tier5AutonomousRuntime.run_all()
    tier6 = Tiannara.Certification.Tier6Discovery.run_all()

    duration = System.monotonic_time(:millisecond) - start_time

    scores = [tier1.score, tier2.score, tier3.score, tier4.score, tier5.score, tier6.score]
    avg = Enum.sum(scores) / 6
    status = cond do avg >= 0.9 -> :passing; avg >= 0.7 -> :degraded; true -> :failing end

    total_exercises = tier1.exercises_completed + tier2.exercises_completed +
      tier3.exercises_completed + tier4.exercises_completed +
      tier5.exercises_completed + tier6.exercises_completed

    total_passed = tier1.exercises_passed + tier2.exercises_passed +
      tier3.exercises_passed + tier4.exercises_passed +
      tier5.exercises_passed + tier6.exercises_passed

    report = %{
      overall_status: status,
      overall_score: avg,
      tier_scores: %{
        cognitive: tier1.score,
        scientific: tier2.score,
        constitutional: tier3.score,
        civilizational: tier4.score,
        autonomous_runtime: tier5.score,
        discovery: tier6.score
      },
      total_exercises: total_exercises,
      total_passed: total_passed,
      duration_ms: duration,
      timestamp: DateTime.utc_now(),
      details: %{
        tier1: tier1, tier2: tier2, tier3: tier3,
        tier4: tier4, tier5: tier5, tier6: tier6
      }
    }

    Logger.info("[TCCP] Full certification: #{report.overall_status} — #{total_passed}/#{total_exercises} (#{Float.round(report.overall_score * 100, 1)}%)")

    GenServer.cast(__MODULE__, {:store_report, report})
    report
  end

  def run_tier(:cognitive), do: Tiannara.Certification.Tier1Cognitive.run_all()
  def run_tier(:scientific), do: Tiannara.Certification.Tier2Scientific.run_all()
  def run_tier(:constitutional), do: Tiannara.Certification.Tier3Constitutional.run_all()
  def run_tier(:civilizational), do: Tiannara.Certification.Tier4Civilizational.run_all()
  def run_tier(:autonomous_runtime), do: Tiannara.Certification.Tier5AutonomousRuntime.run_all()
  def run_tier(:discovery), do: Tiannara.Certification.Tier6Discovery.run_all()

  def last_report, do: GenServer.call(__MODULE__, :last_report)

  @impl true
  def init(_opts) do
    {:ok, %{last_certification: nil, history: []}}
  end

  @impl true
  def handle_cast({:store_report, report}, state) do
    {:noreply, %{state | last_certification: report, history: [report | state.history] |> Enum.take(100)}}
  end

  @impl true
  def handle_call(:last_report, _from, state) do
    {:reply, state.last_certification, state}
  end
end
