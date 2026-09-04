defmodule Tiannara.SelfImprovement.Sandbox.Backend do
  @moduledoc """
  Contract for real-code sandbox backends.

  A backend materializes a baseline codebase in an ISOLATED environment, applies
  a patch, builds, runs real tests and benchmarks, and tears down. It must never
  mutate the original baseline or touch production.

  Constitutional basis: "Security by design", "Fault tolerance", "Preserve
  previous stable states", Replaceability (Local / Container / CI behind one
  interface), "Capability must never outpace verification".
  """

  @type env :: term()

  @callback prepare(baseline :: term(), opts :: keyword()) ::
              {:ok, env :: term()} | {:error, term()}
  @callback apply_patch(env :: term(), patch :: term()) ::
              {:ok, env} | {:error, term()}
  @callback build(env :: term(), spec :: term()) :: {:ok, term()} | {:error, term()}
  @callback run_tests(env :: term(), spec :: term()) :: {:ok, term()} | {:error, term()}
  @callback run_benchmark(env :: term(), spec :: term()) :: {:ok, term()} | {:error, term()}
  @callback teardown(env :: term()) :: :ok
end

defmodule Tiannara.SelfImprovement.Sandbox.CodePatch do
  @moduledoc """
  A real-code patch: either an explicit file map or a unified diff. Carries
  provenance so every modification remains traceable.
  """
  @enforce_keys [:id]
  defstruct [:id, :description, :diff, :files, :provenance, targets: []]
end

defmodule Tiannara.SelfImprovement.Sandbox.BuildSpec do
  @moduledoc "Build/compile command. `nil` command means skip the build step."
  defstruct [:command, :args, timeout: 120_000]
end

defmodule Tiannara.SelfImprovement.Sandbox.TestSpec do
  @moduledoc """
  Real test-suite spec: a command to run and how to read its output. Exit code 0
  is required; `pass_pattern` (string or regex) is an additional output check.
  """
  @enforce_keys [:command, :args]
  defstruct [:command, :args, :pass_pattern, timeout: 120_000]
end

defmodule Tiannara.SelfImprovement.Sandbox.BenchmarkSpec do
  @moduledoc """
  Real benchmark spec: a command whose output is parsed into a numeric metric.
  `direction` is `:lower_better` or `:higher_better`.
  """
  @enforce_keys [:command, :args, :metric, :direction, :parse]
  defstruct [:command, :args, :metric, :direction, :parse, tolerance: 0.1, timeout: 120_000, iterations: 1, warmup: 0]
end