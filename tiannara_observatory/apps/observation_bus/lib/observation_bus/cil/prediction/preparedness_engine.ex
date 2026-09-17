defmodule ObservationBus.CIL.Prediction.PreparednessEngine do
  @moduledoc """
  Computes constitutional readiness across all mission dimensions.

  Tracks runtime ready, research ready, certification ready, planetary ready,
  civilization ready, and mission ready status.
  """

  use GenServer

  @readiness_dims ~w(runtime_ready research_ready certification_ready
                      planetary_ready civilization_ready mission_ready)a

  defstruct [:readiness, :last_assessment]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    dims = Enum.into(@readiness_dims, %{}, fn d -> {d, default_readiness(d)} end)
    {:ok, %__MODULE__{readiness: dims, last_assessment: nil}}
  end

  @doc "Assess readiness for a specific dimension."
  @spec assess(atom()) :: {:ok, map()}
  def assess(dimension) when dimension in @readiness_dims do
    GenServer.call(__MODULE__, {:assess, dimension})
  end

  @doc "Assess all readiness dimensions."
  @spec assess_all() :: map()
  def assess_all do
    GenServer.call(__MODULE__, :assess_all)
  end

  @doc "Get comprehensive readiness report."
  @spec report() :: map()
  def report do
    GenServer.call(__MODULE__, :report)
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:assess, dimension}, _from, state) do
    readiness = state.readiness[dimension] || default_readiness(dimension)
    assessment = build_assessment(dimension, readiness)
    updated = put_in(state, [:readiness, dimension], assessment)
    {:reply, {:ok, assessment}, %{updated | last_assessment: DateTime.utc_now()}}
  end

  def handle_call(:assess_all, _from, state) do
    results = Enum.map(@readiness_dims, fn d ->
      readiness = state.readiness[d] || default_readiness(d)
      build_assessment(d, readiness)
    end)
    dashboard = %{
      dimensions: results,
      overall_readiness: compute_overall(results),
      timestamp: DateTime.utc_now()
    }
    {:reply, dashboard, state}
  end

  def handle_call(:report, _from, state) do
    {:reply, %{
      readiness: state.readiness,
      last_assessed: state.last_assessment,
      dims: @readiness_dims
    }, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      last_assessment: state.last_assessment,
      dimensions: @readiness_dims
    }, state}
  end

  defp build_assessment(dimension, readiness) do
    score = compute_score(dimension, readiness)
    %{
      dimension: dimension,
      score: score,
      status: status_label(score),
      requirements: requirements(dimension),
      gaps: gaps(dimension, score),
      assessed_at: DateTime.utc_now()
    }
  end

  defp compute_score(:runtime_ready, _), do: 0.75
  defp compute_score(:research_ready, _), do: 0.55
  defp compute_score(:certification_ready, _), do: 0.30
  defp compute_score(:planetary_ready, _), do: 0.20
  defp compute_score(:civilization_ready, _), do: 0.10
  defp compute_score(:mission_ready, readiness), do: readiness.current * 0.01

  defp status_label(score) when score >= 0.8, do: :ready
  defp status_label(score) when score >= 0.5, do: :progressing
  defp status_label(score) when score >= 0.2, do: :developing
  defp status_label(_), do: :nascent

  defp requirements(:runtime_ready), do: ["Stable OTP", "Resource monitoring", "Auto-recovery", "Load balancing"]
  defp requirements(:research_ready), do: ["Discovery pipeline", "Experiment framework", "Hypothesis engine"]
  defp requirements(:certification_ready), do: ["Certification pipeline", "Evidence tracking", "Audit trail"]
  defp requirements(:planetary_ready), do: ["Planetary model", "Climate simulation", "Energy tracking"]
  defp requirements(:civilization_ready), do: ["Civilization model", "Kardashev tracking", "Innovation metrics"]
  defp requirements(:mission_ready), do: ["All dimensions ≥ 0.8", "Constitutional health ≥ 0.9", "Risk exposure < 0.3"]

  defp gaps(:runtime_ready, score) when score < 0.8, do: ["Auto-recovery not fully implemented"]
  defp gaps(:research_ready, score) when score < 0.8, do: ["Hypothesis engine incomplete"]
  defp gaps(:certification_ready, score) when score < 0.8, do: ["Automated certification pipeline pending"]
  defp gaps(:planetary_ready, score) when score < 0.8, do: ["Climate simulation fidelity low"]
  defp gaps(:civilization_ready, score) when score < 0.8, do: ["Kardashev tracking not established"]
  defp gaps(:mission_ready, score) when score < 0.8, do: ["Multiple dimensions below threshold"]
  defp gaps(_, _), do: []

  defp compute_overall(results) do
    scores = Enum.map(results, & &1.score)
    if length(scores) > 0, do: Enum.sum(scores) / length(scores), else: 0.0
  end

  defp default_readiness(_), do: %{current: 0.0, trend: :stable}
end
