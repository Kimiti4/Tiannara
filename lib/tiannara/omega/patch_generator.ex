defmodule Tiannara.Omega.PatchGenerator.SpecB do
  @moduledoc """
  Specialized patch generator for Spec B.

  This module extends the reference PatchGenerator to provide behavior
  specific to Spec B, such as custom candidate type selection and change building.
  """

  alias Tiannara.Omega.ExperimentSpec
  alias Tiannara.Omega.PatchGenerator.Candidate
  alias Tiannara.Omega.PatchGenerator

  @behaviour PatchGenerator

  @doc """
  Generates a candidate based on Spec B logic.

  See `Tiannara.Omega.PatchGenerator.generate/2` for full details.
  """
  def generate(%ExperimentSpec{} = spec, context \\ %{}) do
    PatchGenerator.generate(spec, context)
  end

  @doc """
  Custom candidate type selection logic for Spec B.
  """
  def choose_candidate_type(%ExperimentSpec{method: method}) do
    case method do
      :analyze_performance_profile -> :performance_optimization
      :validate_data_flow -> :code_patch
      _ -> :config_change
    end
  end

  @doc """
  Custom change builder for Spec B.
  """
  def build_change(spec, :performance_optimization) do
    %{kind: :performance_tuning, target: spec.hypothesis_id, strategy: :parallelize}
  end

  def build_change(spec, :code_patch) do
    %{kind: :code_modification, target: spec.hypothesis_id, intent: spec.prediction}
  end

  def build_change(spec, :config_change) do
    %{kind: :configuration_change, target: spec.hypothesis_id, intent: spec.prediction}
  end
end
defmodule Tiannara.Omega.PatchGenerator do
  @moduledoc """
  Generates concrete improvement candidates from experiment specifications.

  AUTHORITY BOUNDARY (constitutional): this module GENERATES candidates; it
  cannot deploy, apply, activate, commit, or release them. It can only produce
  candidates with status `:generated`. This is enforced structurally (the
  Candidate state machine only permits `:generated → :sandboxed`) and verified
  by `Tiannara.Omega.AuthorityVerifier`.

  Generation ≠ Authority. The generator proposes; governance disposes.

  Constitutional basis: "Capability must never outpace verification",
  Verification First, Safety and Reliability, augmentation clause.
  """

  alias Tiannara.Omega.ExperimentSpec
  alias Tiannara.Omega.PatchGenerator.Candidate

  @callback generate(spec :: ExperimentSpec.t(), context :: map()) ::
              {:ok, Candidate.t()} | {:error, term()}

  @doc """
  Reference implementation: generates a candidate from an experiment spec.

  In production this is backed by a code-synthesis engine or LLM. The reference
  implementation produces a structured candidate whose `content` encodes the
  intended change, so the sandbox can validate it.
  """
  def generate(%ExperimentSpec{} = spec, _context \\ %{}) do
    type = choose_candidate_type(spec)

    content = %{
      target: spec.hypothesis_id,
      method: spec.method,
      prediction: spec.prediction,
      falsifier: spec.falsifier,
      success_criteria: spec.success_criteria,
      # Reference payload: a structured change descriptor.
      change: build_change(spec, type)
    }

    {:ok,
     Candidate.new(type, spec.proposal_id, content,
       experiment_id: spec.id,
       lineage: spec.lineage ++ [spec.id],
       provenance: [generator: __MODULE__, spec_id: spec.id]
     )}
  end

  defp choose_candidate_type(%ExperimentSpec{method: method}) do
    case method do
      :benchmark_before_after -> :algorithm_parameter
      :measure_memory_delta -> :algorithm_parameter
      :run_test_suite -> :code_patch
      _ -> :config_change
    end
  end

  defp build_change(spec, :algorithm_parameter) do
    %{kind: :parameter_adjustment, parameter: spec.hypothesis_id, direction: :tune}
  end

  defp build_change(spec, :code_patch) do
    %{kind: :code_modification, target: spec.hypothesis_id, intent: spec.prediction}
  end

  defp build_change(spec, :config_change) do
    %{kind: :configuration_change, target: spec.hypothesis_id, intent: spec.prediction}
  end
end