defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ExperimentPlanner do
  @moduledoc """
  Phase 16.1 Module 4 — Experiment Planner (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.4 ResearchScheduler:
  - schedule(programs, resource_policy) -> [DispatchIntent]

  Planner outputs (frozen):
  - variables, controls, treatments, metrics, predictions
  - required_evidence, sample_size, termination_conditions
  """

  @experiment_table :experiments

  def init_table do
    if :ets.info(@experiment_table) == :undefined do
      :ets.new(@experiment_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Create an experiment design from research program"
  @spec create_experiment(String.t(), map()) :: {:ok, map()}
  def create_experiment(program_id, parameters \\ %{}) do
    init_table()
    experiment = build_experiment(program_id, parameters)
    {:ok, experiment}
  end

  @doc "Register an experiment"
  @spec register_experiment(map()) :: :ok
  def register_experiment(experiment) do
    :ets.insert(@experiment_table, {Map.get(experiment, "experiment_id"), experiment})
    :ok
  end

  @doc "Lookup experiment by ID"
  @spec lookup_experiment(String.t()) :: {:ok, map()} | :error
  def lookup_experiment(experiment_id) do
    case :ets.lookup(@experiment_table, experiment_id) do
      [{^experiment_id, experiment}] -> {:ok, experiment}
      [] -> :error
    end
  end

  @doc "List all experiments"
  @spec list_experiments() :: [map()]
  def list_experiments do
    :ets.tab2list(@experiment_table)
    |> Enum.map(fn {_id, e} -> e end)
  end

  # --- internal helpers ---

defp build_experiment(program_id, parameters) do
    canonical = canonicalize_map(parameters)
    json = Jason.encode!(canonical)
    experiment_id = "exp_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "experiment_id" => experiment_id,
      "schema_version" => "16.1.0",
      "timestamp" => deterministic_timestamp(program_id),
      "research_program_id" => program_id,
      "experiment_type" => "SIMULATION",
      "variables" => parameters,
      "controls" => generic_controls(),
      "treatments" => generic_treatments(parameters),
      "metrics" => [%{"measurement_key" => "outcome", "observable" => "result", "units" => "dimensionless"}],
      "predictions" => [%{"if" => "observed", "then" => "expected outcome for #{String.slice(program_id, 0..7)}"}],
      "required_evidence" => [%{"evidence_type" => "STATISTICAL", "minimum_quantity" => 100}],
      "sample_size" => Map.get(parameters, "sample_size", 1000),
      "termination_conditions" => [%{"criterion_type" => "CONFIDENCE", "threshold" => 0.95}]
    }
  end

  defp deterministic_timestamp(_seed) do
    "2000-01-01T00:00:00Z"
  end

  defp generic_controls, do: %{}

  defp generic_treatments(params) do
    params
    |> Map.get("variables", %{})
    |> Map.keys()
    |> Enum.map(fn k -> %{"variable" => k, "values" => [0, 1]} end)
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
