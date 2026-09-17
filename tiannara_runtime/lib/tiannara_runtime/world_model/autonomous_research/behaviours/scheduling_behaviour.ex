defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Behaviours.SchedulingBehaviour do
  @moduledoc """
  Defines the contract for scheduling and managing experiment execution timelines.
  Implementations handle initial scheduling, rescheduling, and schedule retrieval.
  """

  @callback schedule(
              TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentSchedule.t(),
              keyword()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentSchedule.t()} | {:error, term()}

  @callback reschedule(
              TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentSchedule.t(),
              keyword()
            ) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentSchedule.t()} | {:error, term()}

  @callback get_schedule(TiannaraRuntime.WorldModel.AutonomousResearch.ExperimentSchedule.t()) ::
              {:ok, map()} | {:error, term()}
end
