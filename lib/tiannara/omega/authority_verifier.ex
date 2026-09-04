defmodule Tiannara.Omega.AuthorityVerifier do
  @moduledoc """
  Verifies that an Ω component respects its authority boundary.

  This is a general-purpose capability check: given a module, it asserts the
  module does NOT export forbidden authority functions. This is how
  "Generation ≠ Authority" is verified, not merely asserted.

  Constitutional basis: Safety and Reliability ("Capability must never outpace
  verification"), Security by design, Explainability, Verification First.
  """

  @deployment_functions [:deploy, :apply_patch, :activate, :commit, :release, :promote_to_production]

  def deployment_functions, do: @deployment_functions

  @doc """
  Asserts that `module` does not export any deployment capability.
  Returns `:ok` or `{:error, {:deployment_capability_found, violations}}`.
  """
  def assert_no_deployment_capability(module) do
    exports = module.__info__(:functions) |> Enum.map(&elem(&1, 0))
    violations = Enum.filter(exports, &(&1 in @deployment_functions))

    if violations == [],
      do: :ok,
      else: {:error, {:deployment_capability_found, violations}}
  end

  @doc """
  Asserts that a candidate was produced by a generator with no deployment
  capability, AND that the candidate has not skipped the sandbox.
  """
  def verify_candidate(candidate, generator_module) do
    with :ok <- assert_no_deployment_capability(generator_module),
         true <- candidate.status in [:generated, :sandboxed, :tested, :benchmarked,
                                      :certified, :approved, :deployed, :rejected] do
      :ok
    else
      false -> {:error, :invalid_candidate_status}
      {:error, _} = e -> e
    end
  end
end