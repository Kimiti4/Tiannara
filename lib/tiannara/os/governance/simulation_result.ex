defmodule TiannaraOS.Governance.SimulationResult do
  @moduledoc """
  SimulationResult - Immutable record of simulation execution
  
  Captures the outcome of a single mandatory simulation test.
  All fields are immutable once created (content-addressed).
  
  ## Owner
  GovernanceValidationLaboratory (existing, frozen)
  
  ## Guarantees
  - Immutable after creation
  - Content-addressed evidence artifacts
  - Certificate linkage for verification
  - Pass/fail determination is final
  
  ## Usage
      iex> result = SimulationResult.create(:safety, "proposal_001", :pass, metrics)
      iex> SimulationResult.passed?(result)
      true
  """

  @typedoc """
  Simulation result structure with all immutable fields.
  """
  @type t :: %__MODULE__{
    simulation_type: simulation_type(),
    proposal_id: String.t(),
    status: :pass | :fail,
    metrics: map(),
    evidence_artifact_hash: String.t(),
    certificate_hash: String.t(),
    timestamp: DateTime.t()
  }

  defstruct [
    :simulation_type,
    :proposal_id,
    :status,
    :metrics,
    :evidence_artifact_hash,
    :certificate_hash,
    :timestamp
  ]

  @type simulation_type ::
          :structural |
          :safety |
          :governance |
          :scientific |
          :economic |
          :performance |
          :migration |
          :replay

  @doc """
  Create a new simulation result (immutable).
  
  All fields must be provided at creation time and cannot be modified.
  
  ## Parameters
  - `type` - One of the 8 mandatory simulation types
  - `proposal_id` - Proposal being tested
  - `status` - :pass or :fail
  - `metrics` - Type-specific metrics map
  - `evidence_hash` - SHA-256 hash of evidence artifact
  - `cert_hash` - SHA-256 hash of simulation certificate
  
  ## Returns
  New immutable SimulationResult struct
  """
  @spec create(simulation_type(), String.t(), :pass | :fail, map(), String.t(), String.t()) ::
          t()
  def create(type, proposal_id, status, metrics, evidence_hash, cert_hash)
      when type in [:structural, :safety, :governance, :scientific, :economic, :performance, :migration, :replay]
      when status in [:pass, :fail] do
    %__MODULE__{
      simulation_type: type,
      proposal_id: proposal_id,
      status: status,
      metrics: metrics,
      evidence_artifact_hash: evidence_hash,
      certificate_hash: cert_hash,
      timestamp: DateTime.utc_now()
    }
  end

  @doc """
  Check if simulation passed.
  """
  @spec passed?(t()) :: boolean()
  def passed?(%__MODULE__{status: :pass}), do: true
  def passed?(%__MODULE__{status: :fail}), do: false

  @doc """
  Check if simulation failed.
  """
  @spec failed?(t()) :: boolean()
  def failed?(result), do: not passed?(result)

  @doc """
  Check if all simulations in a list passed.
  
  Returns true only if ALL simulations passed (no failures allowed).
  """
  @spec all_passed?([t()]) :: boolean()
  def all_passed?(results) when is_list(results) do
    Enum.all?(results, &passed?/1)
  end

  @doc """
  Get results filtered by simulation type.
  """
  @spec filter_by_type([t()], simulation_type()) :: [t()]
  def filter_by_type(results, type) do
    Enum.filter(results, &(&1.simulation_type == type))
  end

  @doc """
  Get results filtered by status.
  """
  @spec filter_by_status([t()], :pass | :fail) :: [t()]
  def filter_by_status(results, status) do
    Enum.filter(results, &(&1.status == status))
  end

  @doc """
  Generate summary statistics for a set of simulation results.
  
  Returns counts of pass/fail and breakdown by type.
  """
  @spec summarize([t()]) :: map()
  def summarize(results) when is_list(results) do
    total = length(results)
    passed = Enum.count(results, &passed?/1)
    failed = total - passed

    type_breakdown =
      [:structural, :safety, :governance, :scientific, :economic, :performance, :migration, :replay]
      |> Enum.map(fn type ->
        {type, filter_by_type(results, type)}
      end)
      |> Enum.into(%{})

    %{
      total: total,
      passed: passed,
      failed: failed,
      all_passed: all_passed?(results),
      pass_rate: if(total > 0, do: Float.round(passed / total * 100, 2), else: 0.0),
      type_breakdown: type_breakdown
    }
  end

  @doc """
  Verify simulation result integrity.
  
  Checks that all required fields are present and valid.
  """
  @spec verify_integrity(t()) :: {:ok, boolean()} | {:error, [String.t()]}
  def verify_integrity(%__MODULE__{} = result) do
    errors = []

    # Check simulation_type is valid
    errors =
      if result.simulation_type in [
           :structural,
           :safety,
           :governance,
           :scientific,
           :economic,
           :performance,
           :migration,
           :replay
         ] do
        errors
      else
        ["Invalid simulation_type: #{inspect(result.simulation_type)}"] ++ errors
      end

    # Check proposal_id is non-empty
    errors =
      if is_binary(result.proposal_id) and String.length(result.proposal_id) > 0 do
        errors
      else
        ["Invalid proposal_id"] ++ errors
      end

    # Check status is valid
    errors =
      if result.status in [:pass, :fail] do
        errors
      else
        ["Invalid status: #{inspect(result.status)}"] ++ errors
      end

    # Check metrics is a map
    errors =
      if is_map(result.metrics) do
        errors
      else
        ["Metrics must be a map"] ++ errors
      end

    # Check hashes are present
    errors =
      if is_binary(result.evidence_artifact_hash) and
           String.length(result.evidence_artifact_hash) > 0 do
        errors
      else
        ["Missing evidence_artifact_hash"] ++ errors
      end

    errors =
      if is_binary(result.certificate_hash) and String.length(result.certificate_hash) > 0 do
        errors
      else
        ["Missing certificate_hash"] ++ errors
      end

    if Enum.empty?(errors) do
      {:ok, true}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Convert simulation result to JSON-compatible map.
  
  Useful for serialization and artifact storage.
  """
  @spec to_json_map(t()) :: map()
  def to_json_map(%__MODULE__{} = result) do
    %{
      simulation_type: Atom.to_string(result.simulation_type),
      proposal_id: result.proposal_id,
      status: Atom.to_string(result.status),
      metrics: result.metrics,
      evidence_artifact_hash: result.evidence_artifact_hash,
      certificate_hash: result.certificate_hash,
      timestamp: DateTime.to_iso8601(result.timestamp)
    }
  end

  @doc """
  Create a test simulation result for unit testing.
  """
  @spec test_result(simulation_type(), :pass | :fail) :: t()
  def test_result(type \\ :safety, status \\ :pass) do
    create(
      type,
      "test_proposal_001",
      status,
      %{test_metric: 0.95},
      "evidence_hash_test",
      "cert_hash_test"
    )
  end
end
