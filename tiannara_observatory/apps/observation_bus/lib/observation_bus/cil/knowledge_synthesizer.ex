defmodule ObservationBus.CIL.KnowledgeSynthesizer do
  @moduledoc """
  Combines multiple observations into higher-order constitutional knowledge.

  Rather than displaying three unrelated dashboards, the synthesizer infers
  compound diagnoses like "Scientific Throughput Bottleneck" from
  correlated runtime instability + experiment congestion + knowledge slowdown.
  """

  use GenServer

  defstruct [:syntheses, :total_syntheses, :last_synthesis]

  @rules [
    %{
      name: :scientific_throughput_bottleneck,
      conditions: [:runtime_instability, :experiment_congestion, :knowledge_slowdown],
      description: "Scientific Throughput Bottleneck — runtime, experiment, and knowledge subsystems are all underperforming",
      severity: :high,
      confidence_threshold: 0.6
    },
    %{
      name: :engineering_acceleration_risk,
      conditions: [:engineering_acceleration, :certification_backlog],
      description: "Engineering Acceleration Risk — rapid engineering changes may outpace certification capacity",
      severity: :medium,
      confidence_threshold: 0.5
    },
    %{
      name: :discovery_exhaustion,
      conditions: [:discovery_decline, :knowledge_stagnation],
      description: "Discovery Exhaustion — declining discovery rate combined with knowledge stagnation suggests paradigm exhaustion",
      severity: :high,
      confidence_threshold: 0.5
    },
    %{
      name: :resource_health_crisis,
      conditions: [:resource_starvation, :runtime_instability],
      description: "Resource Health Crisis — resource starvation is causing runtime instability across the ecosystem",
      severity: :critical,
      confidence_threshold: 0.4
    },
    %{
      name: :certification_bottleneck,
      conditions: [:certification_regression, :engineering_acceleration],
      description: "Certification Bottleneck — engineering is outpacing certification, creating a quality bottleneck",
      severity: :medium,
      confidence_threshold: 0.5
    },
    %{
      name: :evolutionary_stagnation,
      conditions: [:knowledge_stagnation, :discovery_decline, :experiment_bottleneck],
      description: "Evolutionary Stagnation — combined knowledge, discovery, and experiment stagnation hindering evolution",
      severity: :high,
      confidence_threshold: 0.6
    },
    %{
      name: :governance_stress,
      conditions: [:certification_regression, :security_concern],
      description: "Governance Stress — certification regressions and security concerns indicate governance system under strain",
      severity: :high,
      confidence_threshold: 0.5
    }
  ]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{
      syntheses: [],
      total_syntheses: 0,
      last_synthesis: nil
    }}
  end

  @doc "Feed detected active indicators into the synthesizer."
  @spec synthesize([atom()]) :: [map()]
  def synthesize(active_indicators) do
    GenServer.call(__MODULE__, {:synthesize, active_indicators}, :infinity)
  end

  @doc "Return current syntheses."
  @spec list_syntheses() :: [map()]
  def list_syntheses do
    GenServer.call(__MODULE__, :list)
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:synthesize, active_indicators}, _from, state) do
    active_set = MapSet.new(active_indicators)
    now = DateTime.utc_now()

    results = Enum.map(@rules, fn rule ->
      matched = Enum.filter(rule.conditions, &MapSet.member?(active_set, &1))
      match_ratio = length(matched) / max(length(rule.conditions), 1)

      if match_ratio >= rule.confidence_threshold do
        %{
          id: :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower),
          name: rule.name,
          description: rule.description,
          severity: rule.severity,
          confidence: match_ratio,
          matched_indicators: matched,
          total_conditions: length(rule.conditions),
          synthesized_at: now
        }
      end
    end)
    |> Enum.filter(& &1)

    all_syntheses = results ++ state.syntheses
    all_syntheses = Enum.take(all_syntheses, 100)

    {:reply, results, %{state |
      syntheses: all_syntheses,
      total_syntheses: state.total_syntheses + length(results),
      last_synthesis: now
    }}
  end

  def handle_call(:list, _from, state) do
    {:reply, state.syntheses, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_syntheses: state.total_syntheses,
      active_syntheses: length(state.syntheses),
      last_synthesis: state.last_synthesis
    }, state}
  end
end
