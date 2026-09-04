defmodule TiannaraOS.Governance.ProposalEvents do
  @moduledoc """
  ProposalEvents - Event type definitions for proposal lifecycle
  
  Defines all immutable event types that can be appended to the ProposalLedger.
  Each event represents a state change in the proposal lifecycle.
  
  ## Event Types
  - proposal_created
  - status_changed
  - review_added
  - simulation_completed
  - ratification_completed
  - migration_plan_created
  - execution_started
  - execution_completed
  - certification_completed
  - proposal_superseded
  - proposal_archived
  
  All events are immutable once written to the ledger.
  """

  # === Event Constructors ===

  @doc """
  Create a proposal_created event.
  """
  @spec proposal_created(String.t(), String.t(), map()) :: map()
  def proposal_created(proposal_id, rfc_id, data) do
    %{
      type: :proposal_created,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: Map.merge(%{
        title: data.title,
        description: data.description,
        proposer: data.proposer,
        proposal_genome: data.proposal_genome,
        version: 1
      }, data)
    }
  end

  @doc """
  Create a status_changed event.
  """
  @spec status_changed(String.t(), String.t(), atom(), atom(), String.t()) :: map()
  def status_changed(proposal_id, rfc_id, old_status, new_status, reason \\ "") do
    %{
      type: :status_changed,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        old_status: old_status,
        new_status: new_status,
        reason: reason,
        changed_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Create a review_added event.
  """
  @spec review_added(String.t(), String.t(), String.t(), map()) :: map()
  def review_added(proposal_id, rfc_id, review_id, review_data) do
    %{
      type: :review_added,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        review_id: review_id,
        decision: review_data.decision,
        reviewer_id: review_data.reviewer_id,
        rationale: review_data.rationale
      }
    }
  end

  @doc """
  Create a simulation_completed event.
  """
  @spec simulation_completed(String.t(), String.t(), String.t(), map()) :: map()
  def simulation_completed(proposal_id, rfc_id, simulation_id, simulation_data) do
    %{
      type: :simulation_completed,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        simulation_id: simulation_id,
        scenario: simulation_data.scenario,
        passed: simulation_data.passed,
        fitness_delta: simulation_data.fitness_delta_observed,
        entropy_delta: simulation_data.entropy_delta_observed
      }
    }
  end

  @doc """
  Create a ratification_completed event.
  """
  @spec ratification_completed(String.t(), String.t(), String.t(), map()) :: map()
  def ratification_completed(proposal_id, rfc_id, ratification_id, ratification_data) do
    %{
      type: :ratification_completed,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        ratification_id: ratification_id,
        threshold_met: ratification_data.threshold_met,
        approving_institutions: ratification_data.approving_institutions,
        total_voting_power: ratification_data.total_voting_power
      }
    }
  end

  @doc """
  Create a migration_plan_created event.
  """
  @spec migration_plan_created(String.t(), String.t(), String.t(), map()) :: map()
  def migration_plan_created(proposal_id, rfc_id, migration_id, migration_data) do
    %{
      type: :migration_plan_created,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        migration_id: migration_id,
        steps_count: length(migration_data.steps),
        estimated_duration_ms: migration_data.estimated_duration_ms,
        risk_level: migration_data.risk_level
      }
    }
  end

  @doc """
  Create an execution_started event.
  """
  @spec execution_started(String.t(), String.t()) :: map()
  def execution_started(proposal_id, rfc_id) do
    %{
      type: :execution_started,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        started_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Create an execution_completed event.
  """
  @spec execution_completed(String.t(), String.t(), boolean(), String.t()) :: map()
  def execution_completed(proposal_id, rfc_id, success, result_summary \\ "") do
    %{
      type: :execution_completed,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        success: success,
        result_summary: result_summary,
        completed_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Create a certification_completed event.
  """
  @spec certification_completed(String.t(), String.t(), String.t()) :: map()
  def certification_completed(proposal_id, rfc_id, certificate_hash) do
    %{
      type: :certification_completed,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        certificate_hash: certificate_hash,
        certified_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Create a proposal_superseded event.
  """
  @spec proposal_superseded(String.t(), String.t(), String.t()) :: map()
  def proposal_superseded(proposal_id, rfc_id, superseded_by_id) do
    %{
      type: :proposal_superseded,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        superseded_by: superseded_by_id,
        superseded_at: DateTime.utc_now()
      }
    }
  end

  @doc """
  Create a proposal_archived event.
  """
  @spec proposal_archived(String.t(), String.t()) :: map()
  def proposal_archived(proposal_id, rfc_id) do
    %{
      type: :proposal_archived,
      proposal_id: proposal_id,
      rfc_id: rfc_id,
      data: %{
        archived_at: DateTime.utc_now()
      }
    }
  end

  # === Event Validation ===

  @doc """
  Validate event structure.
  """
  @spec validate(map()) :: :ok | {:error, String.t()}
  def validate(event) do
    required_fields = [:type, :proposal_id, :rfc_id, :data]
    
    missing = Enum.filter(required_fields, &is_nil(Map.get(event, &1)))
    
    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  # === Event Serialization ===

  @doc """
  Serialize event to JSON-compatible map.
  """
  @spec to_json(map()) :: map()
  def to_json(event) do
    %{
      type: Atom.to_string(event.type),
      proposal_id: event.proposal_id,
      rfc_id: event.rfc_id,
      data: serialize_data(event.data)
    }
  end

  @doc """
  Deserialize event from JSON-compatible map.
  """
  @spec from_json(map()) :: map()
  def from_json(json) do
    %{
      type: String.to_existing_atom(json["type"]),
      proposal_id: json["proposal_id"],
      rfc_id: json["rfc_id"],
      data: deserialize_data(json["data"])
    }
  end

  # === Private Functions ===

  defp serialize_data(data) do
    Enum.into(data, %{}, fn {key, value} ->
      {key, serialize_value(value)}
    end)
  end

  defp serialize_value(value) when is_atom(value), do: Atom.to_string(value)
  defp serialize_value(value) when is_struct(value, DateTime), do: DateTime.to_iso8601(value)
  defp serialize_value(value), do: value

  defp deserialize_data(data) do
    Enum.into(data, %{}, fn {key, value} ->
      {String.to_existing_atom(key), deserialize_value(value)}
    end)
  end

  defp deserialize_value("true"), do: true
  defp deserialize_value("false"), do: false
  defp deserialize_value(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> dt
      {:error, _} -> value
    end
  end
  defp deserialize_value(value), do: value
end
