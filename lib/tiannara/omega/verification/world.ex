defmodule Tiannara.Omega.Verification.World do
  @moduledoc """
  An isolated verification world. Each scenario gets its own world with its own
  lineage, correlation, and deployment registries, so one attack cannot
  contaminate another.

  Constitutional basis: "Independent testing", Modularity, "Preserve previous
  stable states."
  """

  defstruct [:world_id, :base, :lineage_path, :registry_path, :deployment_registry_path]

  def create do
    world_id = System.unique_integer([:positive, :monotonic])
    base = Path.join(System.tmp_dir!(), "omega_verify_#{world_id}")

    %__MODULE__{
      world_id: world_id,
      base: base,
      lineage_path: Path.join(base, "lineage.log"),
      registry_path: Path.join(base, "correlation.log"),
      deployment_registry_path: Path.join(base, "deployments.log")
    }
  end

  def discard(%__MODULE__{base: base}), do: File.rm_rf!(base)
end