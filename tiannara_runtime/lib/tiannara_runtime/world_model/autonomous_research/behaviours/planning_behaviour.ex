defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Behaviours.PlanningBehaviour do
  @moduledoc """
  Defines the contract for planning and validating research experiments.
  Implementations handle experiment design, plan validation, and cost estimation.
  """

  @callback plan_experiment(map(), keyword()) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentPortfolio.t()} | {:error, term()}

  @callback validate_plan(TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentPortfolio.t()) ::
              {:ok, boolean()} | {:error, term()}

  @callback estimate_cost(TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentPortfolio.t()) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentBudget.t()} | {:error, term()}
end
