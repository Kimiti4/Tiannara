defmodule Tiannara.ASC.Repair.RootCauseAnalyzer do
  @moduledoc """
  Matches incoming anomaly reports against known failure signatures in
  `KnowledgeArchive`. Returns a `root_cause` atom and a `strategy` atom
  guiding `PatchGenerator`.

  ## Current Status: Phase H stub.
  """

  @spec analyze(map()) :: {:ok, map()}
  def analyze(_anomaly), do: {:error, :root_cause_analysis_backend_unavailable}
end

defmodule Tiannara.ASC.Repair.PatchGenerator do
  @moduledoc "Generates a candidate patch using Implementation sub-civilization. Phase H stub."
  @spec generate(map(), map()) :: {:ok, map()}
  def generate(_project, _root_cause_analysis), do: {:error, :patch_generation_backend_unavailable}
end

defmodule Tiannara.ASC.Repair.SandboxValidator do
  @moduledoc "Runs the patch through Testing + Crucible in an isolated sandbox. Truthful: no real sandbox is wired — reports unavailability."
  @spec validate(map(), map()) :: {:error, :unavailable}
  def validate(_project, _patch), do: {:error, :unavailable}
end

defmodule Tiannara.ASC.Repair.CanaryReleaser do
  @moduledoc "Deploys the validated patch to 5% of traffic. Truthful: no real canary path is wired — reports unavailability."
  @spec release(map(), map()) :: {:error, :unavailable}
  def release(_project, _patch), do: {:error, :unavailable}
end

defmodule Tiannara.ASC.Repair.ProductionRollout do
  @moduledoc "Rolls out canary to 100% if metrics hold for the configured window. Truthful: no real rollout path is wired — reports unavailability."
  @spec rollout(map()) :: {:error, :unavailable}
  def rollout(_project), do: {:error, :unavailable}
end
