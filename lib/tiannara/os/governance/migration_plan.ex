defmodule TiannaraOS.Governance.MigrationPlan do
  @moduledoc """
  MigrationPlan - Plan for executing approved proposal changes
  
  Details the step-by-step migration from current state to proposed state.
  
  ## Immutable Fields
  - `migration_id` - SHA-256 hash (content-addressed)
  - `proposal_id` - Proposal being migrated
  - `created_at` - Fixed timestamp
  
  ## Owner
  ExecutionScheduler is the canonical owner.
  
  ## Storage
  Ledger events only (append-only).
  """

  @enforce_keys [:migration_id, :proposal_id, :steps, :estimated_duration_ms, :risk_level, :rollback_plan, :success_criteria, :created_at]
  
  defstruct [
    :migration_id,
    :proposal_id,
    :steps,
    :estimated_duration_ms,
    :risk_level,
    :rollback_plan,
    :prerequisites,
    :dependencies,
    :pre_checks,
    :post_checks,
    :success_criteria,
    :planned_start,
    :actual_start,
    :completed_at,
    :created_at,
    :status,
    :evidence_refs
  ]

  @type status :: 
    :planned | :ready | :executing | :completed | :failed | :rolled_back | :cancelled

  @type t :: %__MODULE__{
    migration_id: String.t(),
    proposal_id: String.t(),
    steps: [map()],
    estimated_duration_ms: integer(),
    risk_level: float(),
    rollback_plan: map(),
    prerequisites: [String.t()],
    dependencies: [String.t()],
    pre_checks: [map()],
    post_checks: [map()],
    success_criteria: [String.t()],
    planned_start: DateTime.t() | nil,
    actual_start: DateTime.t() | nil,
    completed_at: DateTime.t() | nil,
    created_at: DateTime.t(),
    status: status(),
    evidence_refs: [String.t()]
  }

  @doc """
  Create a new migration plan.
  """
  @spec new(map()) :: {:ok, t()} | {:error, String.t()}
  def new(attrs) do
    with {:ok, validated} <- validate_new_attrs(attrs),
         {:ok, migration_id} <- compute_migration_id(validated),
         now <- get_timestamp(validated.deterministic_context) do
      plan = %__MODULE__{
        migration_id: migration_id,
        proposal_id: validated.proposal_id,
        steps: validated.steps,
        estimated_duration_ms: validated.estimated_duration_ms,
        risk_level: validated.risk_level,
        rollback_plan: validated.rollback_plan,
        prerequisites: validated.prerequisites || [],
        dependencies: validated.dependencies || [],
        pre_checks: validated.pre_checks || [],
        post_checks: validated.post_checks || [],
        success_criteria: validated.success_criteria,
        planned_start: validated.planned_start,
        actual_start: nil,
        completed_at: nil,
        created_at: now,
        status: :planned,
        evidence_refs: validated.evidence_refs || []
      }
      
      {:ok, plan}
    end
  end

  @doc """
  Update migration status.
  """
  @spec update_status(t(), status(), map()) :: {:ok, t()} | {:error, String.t()}
  def update_status(plan, new_status, context \\ %{}) do
    with :ok <- validate_transition(plan.status, new_status),
         now <- get_timestamp(context) do
      updates = case new_status do
        :executing -> %{actual_start: now}
        :completed -> %{completed_at: now}
        :failed -> %{completed_at: now}
        :rolled_back -> %{completed_at: now}
        _ -> %{}
      end
      
      updated = Map.merge(plan, updates) |> Map.put(:status, new_status)
      {:ok, updated}
    end
  end

  @doc """
  Validate migration plan structure.
  """
  @spec validate(t()) :: :ok | {:error, [String.t()]}
  def validate(plan) do
    errors = []
    
    errors = if String.length(plan.migration_id) != 64 do
      ["migration_id must be 64 characters"] ++ errors
    else
      errors
    end
    
    errors = if String.length(plan.proposal_id) != 64 do
      ["proposal_id must be 64 characters"] ++ errors
    else
      errors
    end
    
    errors = if length(plan.steps) == 0 do
      ["steps must have at least one step"] ++ errors
    else
      errors
    end
    
    errors = if not is_integer(plan.estimated_duration_ms) or plan.estimated_duration_ms <= 0 do
      ["estimated_duration_ms must be positive integer"] ++ errors
    else
      errors
    end
    
    errors = if not is_number(plan.risk_level) or plan.risk_level < 0 or plan.risk_level > 1 do
      ["risk_level must be between 0 and 1"] ++ errors
    else
      errors
    end
    
    errors = if not is_map(plan.rollback_plan) do
      ["rollback_plan must be a map"] ++ errors
    else
      errors
    end
    
    errors = if length(plan.success_criteria) == 0 do
      ["success_criteria must have at least one criterion"] ++ errors
    else
      errors
    end
    
    if Enum.empty?(errors) do
      :ok
    else
      {:error, Enum.reverse(errors)}
    end
  end

  @doc """
  Serialize to JSON-compatible map.
  """
  @spec to_json(t()) :: map()
  def to_json(plan) do
    %{
      migration_id: plan.migration_id,
      proposal_id: plan.proposal_id,
      steps: plan.steps,
      estimated_duration_ms: plan.estimated_duration_ms,
      risk_level: plan.risk_level,
      rollback_plan: plan.rollback_plan,
      prerequisites: plan.prerequisites,
      dependencies: plan.dependencies,
      pre_checks: plan.pre_checks,
      post_checks: plan.post_checks,
      success_criteria: plan.success_criteria,
      planned_start: plan.planned_start && DateTime.to_iso8601(plan.planned_start),
      actual_start: plan.actual_start && DateTime.to_iso8601(plan.actual_start),
      completed_at: plan.completed_at && DateTime.to_iso8601(plan.completed_at),
      created_at: DateTime.to_iso8601(plan.created_at),
      status: Atom.to_string(plan.status),
      evidence_refs: plan.evidence_refs
    }
  end

  @doc """
  Deserialize from JSON-compatible map.
  """
  @spec from_json(map()) :: {:ok, t()} | {:error, String.t()}
  def from_json(json) do
    try do
      plan = %__MODULE__{
        migration_id: json["migration_id"],
        proposal_id: json["proposal_id"],
        steps: json["steps"],
        estimated_duration_ms: json["estimated_duration_ms"],
        risk_level: json["risk_level"],
        rollback_plan: json["rollback_plan"],
        prerequisites: json["prerequisites"] || [],
        dependencies: json["dependencies"] || [],
        pre_checks: json["pre_checks"] || [],
        post_checks: json["post_checks"] || [],
        success_criteria: json["success_criteria"],
        planned_start: if(json["planned_start"]) do
          case DateTime.from_iso8601(json["planned_start"]) do
            {:ok, dt} -> dt
            _ -> nil
          end
        else
          nil
        end,
        actual_start: if(json["actual_start"]) do
          case DateTime.from_iso8601(json["actual_start"]) do
            {:ok, dt} -> dt
            _ -> nil
          end
        else
          nil
        end,
        completed_at: if(json["completed_at"]) do
          case DateTime.from_iso8601(json["completed_at"]) do
            {:ok, dt} -> dt
            _ -> nil
          end
        else
          nil
        end,
        created_at: case DateTime.from_iso8601(json["created_at"]) do
          {:ok, dt} -> dt
          _ -> DateTime.utc_now()
        end,
        status: String.to_existing_atom(json["status"]),
        evidence_refs: json["evidence_refs"] || []
      }
      
      {:ok, plan}
    rescue
      e -> {:error, "Failed to deserialize migration plan: #{inspect(e)}"}
    end
  end

  # === Private Functions ===

  defp validate_new_attrs(attrs) do
    required = [
      :proposal_id, :steps, :estimated_duration_ms, :risk_level,
      :rollback_plan, :success_criteria, :deterministic_context
    ]
    
    missing = Enum.filter(required, &is_nil(Map.get(attrs, &1)))
    
    if Enum.empty?(missing) do
      {:ok, attrs}
    else
      {:error, "Missing required fields: #{inspect(missing)}"}
    end
  end

  defp compute_migration_id(attrs) do
    data = attrs.proposal_id <> Jason.encode!(attrs.steps) <> DateTime.to_iso8601(attrs.deterministic_context.timestamp)
    hash = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
    {:ok, hash}
  end

  defp get_timestamp(%{deterministic_context: %{timestamp: ts}}) do
    ts
  end
  
  defp get_timestamp(_context) do
    DateTime.utc_now()
  end

  defp validate_transition(from, to) do
    allowed_transitions = %{
      planned: [:ready, :cancelled],
      ready: [:executing, :cancelled],
      executing: [:completed, :failed],
      completed: [],
      failed: [:rolled_back],
      rolled_back: [],
      cancelled: []
    }
    
    targets = Map.get(allowed_transitions, from, [])
    if to in targets do
      :ok
    else
      {:error, "Invalid transition from #{from} to #{to}"}
    end
  end
end
