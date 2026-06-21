defmodule Tiannara.ASC.Crucible.Observation do
  @moduledoc """
  Crucible Observation — unified format for all crucible telemetry.

  Consolidates observations from Builder, Validator, Breaker, Attacker, and Repairer
  into a single format for law discovery consumption.

  This prevents law discovery from having to parse five incompatible telemetry streams.

  ## Example

      iex> obs = %Tiannara.ASC.Crucible.Observation{
      ...>   source: :breaker,
      ...>   observation_type: :failure,
      ...>   severity: :critical,
      ...>   origin: :architecture,
      ...>   reproducible: true,
      ...>   confidence: 0.85
      ...> }

  """

  @derive Jason.Encoder
  defstruct [
    # Identity
    id: nil,                    # Unique observation identifier
    project_id: nil,            # Project being observed
    genome_id: nil,             # Source genome ID

    # Source
    source: nil,                # :builder | :validator | :breaker | :attacker | :repairer

    # Observation Type
    observation_type: nil,      # :failure | :exploit | :repair | :recovery | :regression

    # Classification
    severity: nil,              # :critical | :high | :medium | :low
    origin: nil,                # :requirements | :architecture | :interface | :implementation | :deployment | :operations
    
    # Phase 5C.4 - Ecological Domain Tracking
    failure_domain: nil,        # :security | :data | :concurrency | :performance | :dependency | :interface | :logic | :resource | :consistency | :state | :unknown

    # Quality Metrics
    reproducible: false,        # Can this observation be reproduced?
    confidence: 0.0,            # Confidence in observation (0.0-1.0)

    # Evidence
    evidence: [],               # Supporting evidence (error messages, stack traces, etc.)

    # Engineering Genome Fingerprint
    engineering_fingerprint: nil,  # %{architecture_style, protocol_family, contract_count, dependency_density, invariant_count}

    # Metadata
    timestamp: nil,             # When observation was recorded
    generation: 0               # Evolution generation number
  ]

  @typedoc "Crucible observation record"
  @type t :: %__MODULE__{
          id: String.t() | nil,
          project_id: String.t() | nil,
          genome_id: String.t() | nil,
          source: atom() | nil,
          observation_type: atom() | nil,
          severity: atom() | nil,
          origin: atom() | nil,
          failure_domain: atom() | nil,
          reproducible: boolean(),
          confidence: float(),
          evidence: [any()],
          timestamp: DateTime.t() | nil,
          generation: non_neg_integer()
        }

  @doc """
  Create a new observation from Builder result.
  """
  def from_builder_result(build_result, project_id, genome_id, generation \\ 0) do
    %__MODULE__{
      id: generate_id(),
      project_id: project_id,
      genome_id: genome_id,
      source: :builder,
      observation_type: if(build_result.success?, do: :success, else: :failure),
      severity: classify_build_severity(build_result),
      origin: :implementation,
      reproducible: build_result.artifact_hash != nil,
      confidence: if(build_result.success?, do: 0.9, else: 0.7),
      evidence: [build_result.error_message],
      timestamp: DateTime.utc_now(),
      generation: generation
    }
  end

  @doc """
  Create a new observation from Validator result.
  """
  def from_validator_result(validation_result, project_id, genome_id, generation \\ 0) do
    %__MODULE__{
      id: generate_id(),
      project_id: project_id,
      genome_id: genome_id,
      source: :validator,
      observation_type: if(validation_result.valid?, do: :validation_pass, else: :failure),
      severity: classify_validation_severity(validation_result),
      origin: determine_violation_origin(validation_result),
      reproducible: true,
      confidence: validation_result.confidence_score,
      evidence: validation_result.invariant_violations ++ validation_result.constraint_violations,
      timestamp: DateTime.utc_now(),
      generation: generation
    }
  end

  @doc """
  Create a new observation from Breaker result.
  """
  def from_breaker_result(break_result, project_id, genome_id, generation \\ 0) do
    %__MODULE__{
      id: generate_id(),
      project_id: project_id,
      genome_id: genome_id,
      source: :breaker,
      observation_type: :failure,
      severity: break_result.failure_severity,
      origin: classify_failure_origin(break_result),
      failure_domain: break_result.failure_type || :unknown,  # Phase 5C.4 - Track ecological domain
      reproducible: break_result.failure_discovered?,
      confidence: if(break_result.failure_discovered?, do: 0.8, else: 0.5),
      evidence: [break_result.failure_description],
      timestamp: DateTime.utc_now(),
      generation: generation
    }
  end

  @doc """
  Create a new observation from Attacker result.
  """
  def from_attacker_result(attack_result, project_id, genome_id, generation \\ 0) do
    %__MODULE__{
      id: generate_id(),
      project_id: project_id,
      genome_id: genome_id,
      source: :attacker,
      observation_type: :exploit,
      severity: attack_result.exploit_severity,
      origin: :implementation,
      reproducible: attack_result.reproducible_exploits > 0,
      confidence: if(attack_result.exploit_found?, do: 0.85, else: 0.6),
      evidence: [attack_result.exploit_description],
      timestamp: DateTime.utc_now(),
      generation: generation
    }
  end

  @doc """
  Create a new observation from Repairer result.
  """
  def from_repairer_result(repair_result, project_id, genome_id, generation \\ 0) do
    %__MODULE__{
      id: generate_id(),
      project_id: project_id,
      genome_id: genome_id,
      source: :repairer,
      observation_type: if(repair_result.repair_successful?, do: :repair, else: :regression),
      severity: repair_result.repair_severity,
      origin: :implementation,
      reproducible: repair_result.patch_stable?,
      confidence: if(repair_result.repair_successful?, do: 0.75, else: 0.5),
      evidence: [repair_result.repair_description],
      timestamp: DateTime.utc_now(),
      generation: generation
    }
  end

  @doc """
  Filter observations by source.
  """
  def filter_by_source(observations, source) do
    Enum.filter(observations, & &1.source == source)
  end

  @doc """
  Filter observations by severity.
  """
  def filter_by_severity(observations, severity) do
    Enum.filter(observations, & &1.severity == severity)
  end

  @doc """
  Filter observations by origin.
  """
  def filter_by_origin(observations, origin) do
    Enum.filter(observations, & &1.origin == origin)
  end

  @doc """
  Calculate observation confidence distribution.
  """
  def confidence_distribution(observations) do
    if length(observations) == 0 do
      %{min: 0.0, max: 0.0, mean: 0.0}
    else
      confidences = Enum.map(observations, & &1.confidence)
      %{
        min: Enum.min(confidences),
        max: Enum.max(confidences),
        mean: Enum.sum(confidences) / length(confidences)
      }
    end
  end

  @doc """
  Group observations by type for pattern analysis.
  """
  def group_by_type(observations) do
    Enum.group_by(observations, & &1.observation_type)
  end

  # Private helpers

  defp generate_id do
    "obs_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
  end

  defp classify_build_severity(build_result) do
    case build_result.error_type do
      :syntax -> :medium
      :dependency -> :low
      :type -> :high
      :configuration -> :medium
      :resource -> :high
      _ -> :low
    end
  end

  defp classify_validation_severity(validation_result) do
    if length(validation_result.invariant_violations) > 0 do
      :critical
    else
      if length(validation_result.constraint_violations) > 0 do
        :high
      else
        :low
      end
    end
  end

  defp determine_violation_origin(validation_result) do
    # Heuristic: determine where violation originated
    if length(validation_result.invariant_violations) > 0 do
      :requirements  # Invariants come from requirements
    else
      if length(validation_result.contract_violations) > 0 do
        :interface     # Contract violations are interface issues
      else
        :implementation
      end
    end
  end

  defp classify_failure_origin(break_result) do
    # Classify failure origin based on failure type
    case break_result.failure_type do
      :consistency -> :architecture
      :state -> :implementation
      :resource -> :deployment
      :logic -> :implementation
      :performance -> :architecture
      _ -> :implementation
    end
  end
end
