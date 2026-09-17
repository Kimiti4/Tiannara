defmodule TiannaraRuntime.WorldModel.AutonomousResearch.Behaviours.ReplayBehaviour do
  @moduledoc """
  Defines the contract for replay verification of autonomous research programs.
  Implementations verify replay integrity, compute deterministic fingerprints,
  and retrieve the archaeology root for lineage tracing.
  """

  @callback verify_replay(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, boolean()} | {:error, term()}

  @callback compute_fingerprint(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, String.t()} | {:error, term()}

  @callback get_replay_root(TiannaraRuntime.WorldModel.AutonomousResearch.ResearchProgram.t()) ::
              {:ok, String.t()} | {:error, term()}
end
