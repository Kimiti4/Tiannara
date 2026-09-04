defmodule TiannaraOS.EpistemicHealthResult do
  @moduledoc """
  EpistemicHealthResult - Canonical constitutional transaction for institutional epistemic health evaluation.
  
  This artifact captures the complete audit trail of one institutional epistemic health evaluation event,
  including health metrics for the evaluating institution and neighboring institutions, detected anomalies,
  quarantine actions, remediation steps, and all constitutional deltas.
  
  ## Key Principle: Behavioral Exposure Over Algorithm Exposure
  
  Instead of exposing immune system state, threat databases, detector outputs, or anomaly graphs,
  this result stores only the behavioral contract: what epistemic health was evaluated, what anomalies
  were detected, and what actions were taken. Internal immune mechanisms remain hidden implementation details.
  
  ## Constitutional Properties
  
  - Immutable once finalized
  - Contains lightweight health references (not full immune system state)
  - Complete audit trail via semantic events and lifecycle tracking
  - Economic ledger accounts for health evaluation costs
  - Governance validates severe quarantines before execution
  - All twenty domains use identical implementation
  
  ## Fields
  
  - `:health_id` - Unique identifier for this health evaluation event
  - `:institution_id` - Owning institution (atom)
  - `:timestamp` - When evaluation occurred (DateTime.t())
  - `:tick` - Institutional tick counter (integer)
  - `:evaluation_scope` - Scope of evaluation (:self | :neighbors | :ecosystem)
  - `:evaluated_institutions` - List of institutions evaluated ([atom()])
  - `:health_metrics` - Overall health scores (%{institution_id => score})
  - `:detected_anomalies` - List of detected issues ([%{type, severity, description, evidence}])
  - `:quarantine_actions` - Actions taken to isolate corruption ([%{action, target, reason}])
  - `:remediation_steps` - Steps to restore healthy state ([%{step, status}])
  - `:false_positive_risk` - Risk of incorrect detection (float 0.0-1.0)
  - `:reversibility_guaranteed` - Whether actions can be undone (boolean)
  - `:governance_decision` - Governance approval/rejection (%{decision, reason, decided_tick} | nil)
  - `:ledger_delta` - Economic cost accounting (%{operation, cost, description, timestamp} | nil)
  - `:memory_delta` - Memory updates (%{operation, data, timestamp} | nil)
  - `:semantic_events` - Domain-specific events emitted ([map()])
  - `:lifecycle_events` - Lifecycle registry entries ([map()])
  - `:constitutional_validation` - Invariant verification results (map() | nil)
  - `:execution_time_ms` - How long evaluation took (integer)
  - `:status` - Current state (:healthy | :anomalies_detected | :quarantine_active | :remediation_complete | :evaluation_failed)
  - `:failure_reason` - Explanation if failed (String.t() | nil)
  
  ## Example
  
      %EpistemicHealthResult{
        health_id: "eh_abc123",
        institution_id: :medicine_inst,
        evaluation_scope: :ecosystem,
        evaluated_institutions: [:medicine_inst_a, :medicine_inst_b, :medicine_inst_c],
        health_metrics: %{
          medicine_inst_a: 0.92,
          medicine_inst_b: 0.45,  # Low health - anomalies detected
          medicine_inst_c: 0.88
        },
        detected_anomalies: [
          %{
            type: :fabricated_publication,
            severity: :critical,
            description: "Publication pub_xyz contains fabricated experimental data",
            evidence: ["Inconsistent results across replications", "Statistical impossibilities"]
          }
        ],
        quarantine_actions: [
          %{action: :quarantine_publication, target: "pub_xyz", reason: "Fabricated data detected"}
        ],
        remediation_steps: [
          %{step: :notify_collaborators, status: :completed},
          %{step: :request_replication, status: :pending}
        ],
        false_positive_risk: 0.05,
        reversibility_guaranteed: true,
        status: :quarantine_active
      }
  """
  
  @derive Jason.Encoder
  defstruct [
    :health_id,                   # String.t() - unique identifier
    :institution_id,              # atom() - owning institution
    :timestamp,                   # DateTime.t() - when evaluation occurred
    :tick,                        # integer() - institutional tick
    
    :evaluation_scope,            # atom() - :self | :neighbors | :ecosystem
    :evaluated_institutions,      # [atom()] - institutions evaluated
    :health_metrics,              # %{atom() => float()} - health scores per institution
    :detected_anomalies,          # [%{type, severity, description, evidence}]
    :quarantine_actions,          # [%{action, target, reason}]
    :remediation_steps,           # [%{step, status}]
    
    :false_positive_risk,         # float() - risk of incorrect detection (0.0-1.0)
    :reversibility_guaranteed,    # boolean() - whether actions can be undone
    
    :governance_decision,         # map() | nil - governance approval/rejection
    :ledger_delta,                # map() | nil - economic cost accounting
    :memory_delta,                # map() | nil - memory updates
    :semantic_events,             # [map()] - domain-specific events
    :lifecycle_events,            # [map()] - lifecycle registry entries
    :constitutional_validation,   # map() | nil - invariant verification
    
    :execution_time_ms,           # integer() - evaluation duration
    :status,                      # atom() - current state
    :failure_reason               # String.t() | nil - explanation if failed
  ]
  
  @doc """
  Create a new EpistemicHealthResult for an institution's health evaluation.
  
  ## Parameters
  
  - `institution_id`: atom() - owning institution
  - `evaluation_scope`: atom() - scope (:self | :neighbors | :ecosystem)
  - `opts`: map() - optional parameters (:tick, :evaluated_institutions)
  
  ## Returns
  
  EpistemicHealthResult.t() - initialized result with :healthy status
  
  ## Example
  
      result = EpistemicHealthResult.new(:medicine_inst, :ecosystem, %{
        tick: 42,
        evaluated_institutions: [:inst_a, :inst_b]
      })
  """
  def new(institution_id, evaluation_scope, opts \\ %{}) do
    # Convert keyword list to map if needed
    opts_map = if is_list(opts), do: Map.new(opts), else: opts
    
    %__MODULE__{
      health_id: generate_health_id(institution_id),
      institution_id: institution_id,
      timestamp: DateTime.utc_now(),
      tick: Map.get(opts_map, :tick, 0),
      
      evaluation_scope: evaluation_scope,
      evaluated_institutions: Map.get(opts_map, :evaluated_institutions, []),
      health_metrics: %{},
      detected_anomalies: [],
      quarantine_actions: [],
      remediation_steps: [],
      
      false_positive_risk: 0.0,
      reversibility_guaranteed: true,
      
      governance_decision: nil,
      ledger_delta: nil,
      memory_delta: nil,
      semantic_events: [],
      lifecycle_events: [],
      constitutional_validation: nil,
      
      execution_time_ms: 0,
      status: :healthy,
      failure_reason: nil
    }
  end
  
  @doc """
  Set health metrics for evaluated institutions.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `metrics`: %{atom() => float()} - health scores per institution (0.0-1.0)
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with health metrics
  """
  def set_health_metrics(result, metrics) do
    %{result | health_metrics: metrics}
  end
  
  @doc """
  Add a detected anomaly.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `anomaly_type`: atom() - type of anomaly (e.g., :fabricated_publication, :poisoned_evidence)
  - `severity`: atom() - severity level (:low | :medium | :high | :critical)
  - `description`: String.t() - description of the anomaly
  - `evidence`: [String.t()] - evidence supporting the detection
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with anomaly added
  """
  def add_anomaly(result, anomaly_type, severity, description, evidence) do
    anomaly = %{
      type: anomaly_type,
      severity: severity,
      description: description,
      evidence: evidence
    }
    
    %{result | detected_anomalies: result.detected_anomalies ++ [anomaly]}
  end
  
  @doc """
  Add a quarantine action.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `action`: atom() - quarantine action (e.g., :quarantine_publication, :isolate_institution)
  - `target`: String.t() | atom() - target of quarantine
  - `reason`: String.t() - reason for quarantine
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with quarantine action
  """
  def add_quarantine_action(result, action, target, reason) do
    quarantine = %{
      action: action,
      target: target,
      reason: reason
    }
    
    %{result | quarantine_actions: result.quarantine_actions ++ [quarantine]}
  end
  
  @doc """
  Add a remediation step.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `step`: atom() - remediation step (e.g., :notify_collaborators, :request_replication)
  - `status`: atom() - step status (:pending | :in_progress | :completed)
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with remediation step
  """
  def add_remediation_step(result, step, status) do
    remediation = %{
      step: step,
      status: status
    }
    
    %{result | remediation_steps: result.remediation_steps ++ [remediation]}
  end
  
  @doc """
  Set false positive risk.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `risk`: float() - risk of incorrect detection (0.0-1.0)
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with false positive risk
  """
  def set_false_positive_risk(result, risk) do
    %{result | false_positive_risk: risk}
  end
  
  @doc """
  Set reversibility guarantee.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `guaranteed`: boolean() - whether actions can be undone
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with reversibility guarantee
  """
  def set_reversibility_guaranteed(result, guaranteed) do
    %{result | reversibility_guaranteed: guaranteed}
  end
  
  @doc """
  Add governance decision (approve/reject quarantine actions).
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `decision`: map() - governance decision (%{decision, reason, decided_tick})
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with governance decision
  """
  def add_governance_decision(result, decision) do
    %{result | governance_decision: decision}
  end
  
  @doc """
  Set ledger delta for health evaluation costs.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `delta`: map() - ledger delta (%{operation, cost, description, timestamp})
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with ledger delta
  """
  def set_ledger_delta(result, delta) do
    %{result | ledger_delta: delta}
  end
  
  @doc """
  Set memory delta for health evaluation.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `delta`: map() - memory delta (%{operation, data, timestamp})
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with memory delta
  """
  def set_memory_delta(result, delta) do
    %{result | memory_delta: delta}
  end
  
  @doc """
  Add semantic event emitted during health evaluation.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `event`: map() - semantic event (%{type, data, timestamp})
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with event added
  """
  def add_semantic_event(result, event) do
    %{result | semantic_events: result.semantic_events ++ [event]}
  end
  
  @doc """
  Add lifecycle event for health evaluation.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `event`: map() - lifecycle event (%{event_type, tick, timestamp, metadata})
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with lifecycle event
  """
  def add_lifecycle_event(result, event) do
    %{result | lifecycle_events: result.lifecycle_events ++ [event]}
  end
  
  @doc """
  Set constitutional validation results.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `validation`: map() - validation results (%{status, invariants_checked, validated_tick})
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with validation
  """
  def set_constitutional_validation(result, validation) do
    %{result | constitutional_validation: validation}
  end
  
  @doc """
  Set execution time for health evaluation.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `time_ms`: integer() - execution time in milliseconds
  
  ## Returns
  
  EpistemicHealthResult.t() - updated result with execution time
  """
  def set_execution_time(result, time_ms) do
    %{result | execution_time_ms: time_ms}
  end
  
  @doc """
  Mark health evaluation as having detected anomalies.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  
  ## Returns
  
  EpistemicHealthResult.t() - result marked with anomalies detected
  """
  def mark_anomalies_detected(result) do
    %{result | status: :anomalies_detected}
  end
  
  @doc """
  Mark health evaluation as having active quarantine.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  
  ## Returns
  
  EpistemicHealthResult.t() - result marked with quarantine active
  """
  def mark_quarantine_active(result) do
    %{result | status: :quarantine_active}
  end
  
  @doc """
  Mark health evaluation as remediation complete.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  
  ## Returns
  
  EpistemicHealthResult.t() - result marked as remediation complete
  """
  def mark_remediation_complete(result) do
    %{result | status: :remediation_complete}
  end
  
  @doc """
  Mark health evaluation as failed.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  - `reason`: String.t() - failure explanation
  
  ## Returns
  
  EpistemicHealthResult.t() - result marked as failed
  """
  def mark_failed(result, reason) do
    %{result |
      status: :evaluation_failed,
      failure_reason: reason
    }
  end
  
  @doc """
  Get overall ecosystem health (average of all institution scores).
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  
  ## Returns
  
  float() - average health score (0.0-1.0), or 0.0 if no metrics
  """
  def get_ecosystem_health(result) do
    if map_size(result.health_metrics) > 0 do
      scores = Map.values(result.health_metrics)
      Enum.sum(scores) / length(scores)
    else
      0.0
    end
  end
  
  @doc """
  Check if any critical anomalies were detected.
  
  ## Parameters
  
  - `result`: EpistemicHealthResult.t() - target result
  
  ## Returns
  
  boolean() - true if any critical severity anomalies exist
  """
  def has_critical_anomalies?(result) do
    Enum.any?(result.detected_anomalies, fn anomaly ->
      anomaly.severity == :critical
    end)
  end
  
  # Generate unique health ID
  defp generate_health_id(institution_id) do
    prefix = Atom.to_string(institution_id) |> String.slice(0, 3)
    timestamp = System.system_time(:millisecond) |> rem(1000000)
    random = :rand.uniform(9999)
    "eh_#{prefix}_#{timestamp}_#{random}"
  end
end
