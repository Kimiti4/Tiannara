defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Behaviours.ResearchBehaviour do
  @moduledoc """
  Defines the contract for managing the lifecycle of an autonomous research program.
  Implementations are responsible for starting, pausing, terminating programs,
  and reporting their current status.
  """

  @callback start_program(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()} | {:error, term()}

  @callback pause_program(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()} | {:error, term()}

  @callback terminate_program(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()} | {:error, term()}

  @callback get_status(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, atom()} | {:error, term()}
end
