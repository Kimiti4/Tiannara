defmodule ObservationBus.CIL.RiskAnalyzer do
  @moduledoc """
  Computes constitutional risk levels across all domains.

  Combines severity, probability, and impact to produce a risk matrix.
  Used by Mission Control to prioritize attention and resources.
  """

  use GenServer

  @domains ~w(runtime knowledge science engineering evolution governance certification security)a

  defstruct [:risk_matrix, :total_assessments, :last_assessment]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    matrix = Enum.into(@domains, %{}, fn d -> {d, default_risk()} end)
    {:ok, %__MODULE__{
      risk_matrix: matrix,
      total_assessments: 0,
      last_assessment: nil
    }}
  end

  @doc "Assess risk for a domain based on evidence."
  @spec assess(atom(), map()) :: {:ok, map()}
  def assess(domain, evidence \\ %{}) when domain in @domains do
    GenServer.call(__MODULE__, {:assess, domain, evidence})
  end

  @doc "Return current risk matrix."
  @spec risk_matrix() :: %{atom() => map()}
  def risk_matrix do
    GenServer.call(__MODULE__, :matrix)
  end

  @doc "Return highest-risk items."
  @spec top_risks(pos_integer()) :: [map()]
  def top_risks(count \\ 5) do
    GenServer.call(__MODULE__, {:top, count})
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:assess, domain, evidence}, _from, state) do
    severity = Map.get(evidence, :severity, 3)
    probability = Map.get(evidence, :probability, 0.5)
    impact = Map.get(evidence, :impact, 3)

    risk_score = severity * probability * impact
    risk_level = risk_level(risk_score)

    assessment = %{
      domain: domain,
      severity: severity,
      probability: probability,
      impact: impact,
      risk_score: risk_score,
      risk_level: risk_level,
      assessed_at: DateTime.utc_now(),
      evidence: evidence
    }

    matrix = Map.put(state.risk_matrix, domain, assessment)
    {:reply, {:ok, assessment},
     %{state | risk_matrix: matrix, total_assessments: state.total_assessments + 1,
               last_assessment: DateTime.utc_now()}}
  end

  def handle_call(:matrix, _from, state) do
    {:reply, state.risk_matrix, state}
  end

  def handle_call({:top, count}, _from, state) do
    state.risk_matrix
    |> Map.values()
    |> Enum.sort_by(& &1.risk_score, :desc)
    |> Enum.take(count)
    |> then(&{:reply, &1, state})
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      domains_assessed: Map.keys(state.risk_matrix),
      total_assessments: state.total_assessments,
      last_assessment: state.last_assessment
    }, state}
  end

  defp risk_level(score) do
    cond do
      score >= 20 -> :critical
      score >= 10 -> :high
      score >= 5 -> :medium
      score >= 2 -> :low
      true -> :negligible
    end
  end

  defp default_risk do
    %{domain: nil, severity: 0, probability: 0.0, impact: 0,
      risk_score: 0, risk_level: :unknown, assessed_at: nil, evidence: %{}}
  end
end
