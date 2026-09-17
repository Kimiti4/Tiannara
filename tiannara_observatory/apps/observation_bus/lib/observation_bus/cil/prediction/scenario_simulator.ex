defmodule ObservationBus.CIL.Prediction.ScenarioSimulator do
  @moduledoc """
  Creates multiple future scenarios by adjusting constitutional parameters.

  Supports scenario types: increase compute, reduce experiments, ontology
  expansion, runtime upgrade, new scientific domain, hardware failure.

  Produces comparative outcomes for each scenario against the baseline.
  """

  use GenServer

  @scenario_types ~w(increase_compute reduce_experiments ontology_expansion
                     runtime_upgrade new_domain hardware_failure)a

  defstruct [:scenarios, :total_simulations, :last_simulation]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{scenarios: %{}, total_simulations: 0, last_simulation: nil}}
  end

  @doc "Run a scenario simulation."
  @spec simulate(atom(), keyword()) :: {:ok, map()}
  def simulate(scenario_type, params \\ []) when scenario_type in @scenario_types do
    GenServer.call(__MODULE__, {:simulate, scenario_type, params})
  end

  @doc "Compare multiple scenarios."
  @spec compare([atom()]) :: [map()]
  def compare(scenario_types) do
    GenServer.call(__MODULE__, {:compare, scenario_types})
  end

  @doc "List all stored scenarios."
  @spec list_scenarios() :: %{atom() => map()}
  def list_scenarios do
    GenServer.call(__MODULE__, :list)
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:simulate, scenario_type, params}, _from, state) do
    baseline = %{
      discovery_rate: 10.0, knowledge_growth: 5.0, theory_evolution: 3.0,
      resource_usage: 0.6, queue_growth: 100.0, certification_progress: 0.3,
      runtime_load: 0.5
    }
    outcome = apply_scenario(baseline, scenario_type, params)

    result = %{
      scenario: scenario_type,
      baseline: baseline,
      outcome: outcome,
      deltas: compute_deltas(baseline, outcome),
      simulated_at: DateTime.utc_now(),
      params: params
    }

    scenarios = Map.put(state.scenarios, scenario_type, result)
    {:reply, {:ok, result},
     %{state | scenarios: scenarios, total_simulations: state.total_simulations + 1,
               last_simulation: DateTime.utc_now()}}
  end

  def handle_call({:compare, scenario_types}, _from, state) do
    results = Enum.map(scenario_types, fn st ->
      Map.get(state.scenarios, st, %{scenario: st, error: "not yet simulated"})
    end)
    {:reply, results, state}
  end

  def handle_call(:list, _from, state) do
    {:reply, state.scenarios, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_simulations: state.total_simulations,
      scenarios_available: Map.keys(state.scenarios),
      last_simulation: state.last_simulation
    }, state}
  end

  defp apply_scenario(baseline, :increase_compute, _params) do
    %{baseline |
      discovery_rate: baseline.discovery_rate * 1.3,
      resource_usage: baseline.resource_usage * 1.5,
      runtime_load: baseline.runtime_load * 1.2
    }
  end

  defp apply_scenario(baseline, :reduce_experiments, _params) do
    %{baseline |
      discovery_rate: baseline.discovery_rate * 0.7,
      queue_growth: baseline.queue_growth * 0.4,
      resource_usage: baseline.resource_usage * 0.8
    }
  end

  defp apply_scenario(baseline, :ontology_expansion, _params) do
    %{baseline |
      knowledge_growth: baseline.knowledge_growth * 1.5,
      theory_evolution: baseline.theory_evolution * 1.2
    }
  end

  defp apply_scenario(baseline, :runtime_upgrade, _params) do
    %{baseline |
      runtime_load: baseline.runtime_load * 0.6,
      resource_usage: baseline.resource_usage * 0.8,
      certification_progress: baseline.certification_progress * 1.3
    }
  end

  defp apply_scenario(baseline, :new_domain, _params) do
    %{baseline |
      discovery_rate: baseline.discovery_rate * 1.2,
      knowledge_growth: baseline.knowledge_growth * 1.1,
      theory_evolution: baseline.theory_evolution * 1.3
    }
  end

  defp apply_scenario(baseline, :hardware_failure, _params) do
    %{baseline |
      discovery_rate: baseline.discovery_rate * 0.3,
      resource_usage: baseline.resource_usage * 0.2,
      runtime_load: baseline.runtime_load * 2.0,
      queue_growth: baseline.queue_growth * 3.0
    }
  end

  defp compute_deltas(baseline, outcome) do
    Map.merge(baseline, outcome, fn _k, b, o -> o - b end)
  end
end
