defmodule Tiannara.ASC.Repair.RootCauseAnalyzer do
  @moduledoc """
  Matches incoming anomaly reports against known failure signatures.

  ## Current Status: fail-closed (Phase H stub remediated).

  Previously returned a success-shaped stub (`{:ok, %{confidence: 0.5}}`)
  with a hardcoded 4-branch case on metric name — capability ledger finding
  C5 (HIGH): "outer shape is success, so a `{:ok, X}` caller proceeds."
  Now reports unavailability. The real signature-matching path is
  `Tiannara.ASC.Crucible.RepairReuseEngine.repair_failure/3` over
  `RepairLibrary` (18,016 persisted patterns).
  """

  @spec analyze(map()) :: {:error, :unavailable}
  def analyze(_anomaly) do
    {:error, :unavailable}
  end
end

defmodule Tiannara.ASC.Repair.PatchGenerator do
  @moduledoc """
  Generates a candidate patch.

  ## Current Status: fail-closed (Phase H stub remediated).

  Previously returned `{:ok, %{type: :stub}}` — a success-shaped stub
  (capability ledger C5). Now reports unavailability. No real patch
  generator is wired; the repair path that exists is `RepairReuseEngine`.
  """

  @spec generate(map(), map()) :: {:error, :unavailable}
  def generate(_project, _root_cause_analysis) do
    {:error, :unavailable}
  end
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
