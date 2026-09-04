defmodule Tiannara.ASC.Crucible.Observatory do
  @moduledoc """
  Crucible Observatory — collects, aggregates, and analyzes all crucible observations.

  Purpose:
  - Collect every CrucibleObservation from Builder/Validator/Breaker/Attacker/Repairer
  - Aggregate metrics for survival analytics
  - Generate law candidates from observation patterns
  - Track knowledge reuse and transfer statistics

  ## Metrics Tracked

  - survival_rate
  - failure_rate
  - exploit_rate
  - repair_rate
  - recovery_rate
  - mean_time_to_failure
  - mean_time_to_repair
  - mean_time_to_recovery
  - knowledge_reuse_rate
  - patch_stability
  - exploit_recurrence_rate

  ## Example

      iex> {:ok, obs} = Tiannara.ASC.Crucible.Observatory.record_observation(observation)
      iex> stats = Tiannara.ASC.Crucible.Observatory.get_survival_stats()
      iex> stats.survival_rate
      0.73

  """

  use GenServer

  alias Tiannara.ASC.Crucible.Observation
  alias Tiannara.ASC.Crucible.RepairPattern

  # State structure
  defstruct [
    # Observation storage
    observations: [],

    # Aggregated metrics
    survival_rate: 0.0,
    failure_rate: 0.0,
    exploit_rate: 0.0,
    repair_rate: 0.0,
    recovery_rate: 0.0,

    # Timing metrics
    mean_time_to_failure: 0.0,
    mean_time_to_repair: 0.0,
    mean_time_to_recovery: 0.0,

    # Knowledge metrics
    knowledge_reuse_rate: 0.0,
    patch_stability: 0.0,
    exploit_recurrence_rate: 0.0,

    # Repair patterns
    repair_patterns: [],

    # Law candidates
    law_candidates: [],

    # Epoch tracking
    epochs: [],
    current_epoch_id: nil,

    # Metadata
    total_observations: 0,
    started_at: nil,
    last_updated_at: nil
  ]

  @typedoc "Crucible Observatory state"
  @type t :: %__MODULE__{
          observations: [Observation.t()],
          survival_rate: float(),
          failure_rate: float(),
          exploit_rate: float(),
          repair_rate: float(),
          recovery_rate: float(),
          mean_time_to_failure: float(),
          mean_time_to_repair: float(),
          mean_time_to_recovery: float(),
          knowledge_reuse_rate: float(),
          patch_stability: float(),
          exploit_recurrence_rate: float(),
          repair_patterns: [RepairPattern.t()],
          law_candidates: [any()],
          epochs: [Epoch.t()],
          current_epoch_id: String.t() | nil,
          total_observations: non_neg_integer(),
          started_at: DateTime.t() | nil,
          last_updated_at: DateTime.t() | nil
        }

  # Client API

  @doc """
  Start the Crucible Observatory GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Record a new crucible observation.
  """
  def record_observation(%Observation{} = observation) do
    GenServer.call(__MODULE__, {:record_observation, observation})
  end

  @doc """
  Record multiple observations at once.
  """
  def record_observations(observations) when is_list(observations) do
    GenServer.call(__MODULE__, {:record_observations, observations})
  end

  @doc """
  Get current survival statistics.
  """
  def get_survival_stats do
    GenServer.call(__MODULE__, :get_survival_stats)
  end

  @doc """
  Get aggregated metrics for law discovery.
  """
  def get_metrics do
    GenServer.call(__MODULE__, :get_metrics)
  end

  @doc """
  Get all observations filtered by source.
  """
  def get_observations_by_source(source) do
    GenServer.call(__MODULE__, {:get_observations_by_source, source})
  end

  @doc """
  Get all observations filtered by severity.
  """
  def get_observations_by_severity(severity) do
    GenServer.call(__MODULE__, {:get_observations_by_severity, severity})
  end

  @doc """
  Register a new repair pattern.
  """
  def register_repair_pattern(%RepairPattern{} = pattern) do
    GenServer.call(__MODULE__, {:register_repair_pattern, pattern})
  end

  @doc """
  Get all registered repair patterns.
  """
  def get_repair_patterns do
    GenServer.call(__MODULE__, :get_repair_patterns)
  end

  @doc """
  Get law candidates generated from observations.
  """
  def get_law_candidates do
    GenServer.call(__MODULE__, :get_law_candidates)
  end

  @doc """
  Reset observatory state (for testing).
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      started_at: DateTime.utc_now(),
      last_updated_at: DateTime.utc_now()
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:record_observation, observation}, _from, state) do
    new_state = process_observation(state, observation)
    {:reply, {:ok, observation}, new_state}
  end

  @impl true
  def handle_call({:record_observations, observations}, _from, state) do
    new_state = Enum.reduce(observations, state, &process_observation(&2, &1))
    {:reply, {:ok, length(observations)}, new_state}
  end

  @impl true
  def handle_call(:get_survival_stats, _from, state) do
    stats = calculate_survival_stats(state)
    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_call(:get_metrics, _from, state) do
    {:reply, {:ok, extract_metrics(state)}, state}
  end

  @impl true
  def handle_call({:get_observations_by_source, source}, _from, state) do
    filtered = Observation.filter_by_source(state.observations, source)
    {:reply, {:ok, filtered}, state}
  end

  @impl true
  def handle_call({:get_observations_by_severity, severity}, _from, state) do
    filtered = Observation.filter_by_severity(state.observations, severity)
    {:reply, {:ok, filtered}, state}
  end

  @impl true
  def handle_call({:register_repair_pattern, pattern}, _from, state) do
    new_state = %{state | repair_patterns: [pattern | state.repair_patterns]}
    updated_state = recalculate_knowledge_metrics(new_state)
    {:reply, {:ok, pattern}, updated_state}
  end

  @impl true
  def handle_call(:get_repair_patterns, _from, state) do
    {:reply, {:ok, state.repair_patterns}, state}
  end

  @impl true
  def handle_call(:get_law_candidates, _from, state) do
    candidates = generate_law_candidates(state)
    {:reply, {:ok, candidates}, state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    new_state = %__MODULE__{
      started_at: DateTime.utc_now(),
      last_updated_at: DateTime.utc_now()
    }
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:finalize_epoch, epoch_id, projects_tested}, _from, state) do
    # Get current metrics
    metrics = extract_metrics(state)

    # === FIX 2: Run law discovery on epoch observations ===
    IO.puts("\n🔍 Running Law Discovery...")
    candidate_laws = discover_candidate_laws_from_observations(state.observations)
    IO.puts("✅ Discovered #{length(candidate_laws)} candidate laws")
    # ========================================

    # Add candidate laws to metrics for epoch creation
    enhanced_metrics = Map.put(metrics, :law_candidates, candidate_laws)

    # Create epoch record with discovered laws
    epoch = Tiannara.ASC.Crucible.Epoch.from_observatory_metrics(
      epoch_id,
      enhanced_metrics,
      projects_tested
    )

    # === FIX 3: Update Falsification Ledger with new evidence ===
    if length(candidate_laws) > 0 do
      IO.puts("📚 Updating Falsification Ledger...")
      observations = get_all_observations(state)
      Tiannara.ASC.Crucible.LawFalsificationLedger.update_from_epoch(epoch, observations)
      IO.puts("✅ Falsification Ledger updated")
    end
    # ========================================

    # Check if meets Alpha criteria
    meets_criteria = Tiannara.ASC.Crucible.Epoch.meets_alpha_criteria?(epoch)

    # Store epoch
    updated_state = %{
      state
      | epochs: [epoch | state.epochs],
        current_epoch_id: epoch_id,
        last_updated_at: DateTime.utc_now()
    }

    # Log results
    if meets_criteria do
      IO.puts("\n✅ Alpha Campaign SUCCESS")
      IO.inspect(Tiannara.ASC.Crucible.Epoch.summarize(epoch), label: "Epoch Summary")
    else
      IO.puts("\n❌ Alpha Campaign INCOMPLETE")
      IO.inspect(Tiannara.ASC.Crucible.Epoch.summarize(epoch), label: "Epoch Summary")
    end

    {:reply, {:ok, epoch}, updated_state}
  end

  @impl true
  def handle_call(:get_epochs, _from, state) do
    {:reply, {:ok, state.epochs}, state}
  end

  @impl true
  def handle_call({:compare_epochs, epoch_id1, epoch_id2}, _from, state) do
    epoch1 = Enum.find(state.epochs, &(&1.epoch_id == epoch_id1))
    epoch2 = Enum.find(state.epochs, &(&1.epoch_id == epoch_id2))

    if is_nil(epoch1) || is_nil(epoch2) do
      {:reply, {:error, :epoch_not_found}, state}
    else
      comparison = Tiannara.ASC.Crucible.Epoch.compare_epochs(epoch1, epoch2)
      {:reply, {:ok, comparison}, state}
    end
  end

  # Private helpers

  defp process_observation(state, %Observation{} = observation) do
    # Store observation
    updated_observations = [observation | state.observations]

    # Update counts
    total = length(updated_observations)

    # Recalculate rates
    rates = calculate_rates(updated_observations)

    # Update state
    %{
      state
      | observations: updated_observations,
        total_observations: total,
        survival_rate: rates.survival_rate,
        failure_rate: rates.failure_rate,
        exploit_rate: rates.exploit_rate,
        repair_rate: rates.repair_rate,
        recovery_rate: rates.recovery_rate,
        last_updated_at: DateTime.utc_now()
    }
  end

  defp calculate_rates(observations) do
    total = length(observations)

    if total == 0 do
      %{
        survival_rate: 0.0,
        failure_rate: 0.0,
        exploit_rate: 0.0,
        repair_rate: 0.0,
        recovery_rate: 0.0
      }
    else
      # Count by type
      failures = Enum.count(observations, &(&1.observation_type == :failure))
      exploits = Enum.count(observations, &(&1.observation_type == :exploit))
      repairs = Enum.count(observations, &(&1.observation_type == :repair))
      recoveries = Enum.count(observations, &(&1.observation_type == :recovery))

      # Calculate rates
      failure_rate = failures / total
      exploit_rate = exploits / total
      repair_rate = repairs / total
      recovery_rate = recoveries / total

      # Survival rate = 1 - failure_rate (simplified)
      survival_rate = 1.0 - failure_rate

      %{
        survival_rate: Float.round(survival_rate, 3),
        failure_rate: Float.round(failure_rate, 3),
        exploit_rate: Float.round(exploit_rate, 3),
        repair_rate: Float.round(repair_rate, 3),
        recovery_rate: Float.round(recovery_rate, 3)
      }
    end
  end

  defp calculate_survival_stats(state) do
    observations = state.observations
    total = length(observations)

    if total == 0 do
      %{
        total_observations: 0,
        survival_rate: 0.0,
        failure_rate: 0.0,
        exploit_rate: 0.0,
        repair_rate: 0.0,
        recovery_rate: 0.0,
        mean_time_to_failure: 0.0,
        mean_time_to_repair: 0.0,
        mean_time_to_recovery: 0.0,
        knowledge_reuse_rate: 0.0,
        patch_stability: 0.0,
        exploit_recurrence_rate: 0.0
      }
    else
      rates = calculate_rates(observations)

      %{
        total_observations: total,
        survival_rate: rates.survival_rate,
        failure_rate: rates.failure_rate,
        exploit_rate: rates.exploit_rate,
        repair_rate: rates.repair_rate,
        recovery_rate: rates.recovery_rate,
        mean_time_to_failure: state.mean_time_to_failure,
        mean_time_to_repair: state.mean_time_to_repair,
        mean_time_to_recovery: state.mean_time_to_recovery,
        knowledge_reuse_rate: state.knowledge_reuse_rate,
        patch_stability: state.patch_stability,
        exploit_recurrence_rate: state.exploit_recurrence_rate
      }
    end
  end

  defp extract_metrics(state) do
    %{
      # Basic counts
      total_observations: state.total_observations,
      observation_count_by_source: count_by_field(state.observations, :source),
      observation_count_by_type: count_by_field(state.observations, :observation_type),
      observation_count_by_severity: count_by_field(state.observations, :severity),
      observation_count_by_origin: count_by_field(state.observations, :origin),

      # Rates
      survival_rate: state.survival_rate,
      failure_rate: state.failure_rate,
      exploit_rate: state.exploit_rate,
      repair_rate: state.repair_rate,
      recovery_rate: state.recovery_rate,

      # Timing
      mean_time_to_failure: state.mean_time_to_failure,
      mean_time_to_repair: state.mean_time_to_repair,
      mean_time_to_recovery: state.mean_time_to_recovery,

      # Knowledge
      knowledge_reuse_rate: state.knowledge_reuse_rate,
      patch_stability: state.patch_stability,
      exploit_recurrence_rate: state.exploit_recurrence_rate,
      repair_pattern_count: length(state.repair_patterns),

      # Law discovery
      law_candidate_count: length(state.law_candidates),

      # Metadata
      started_at: state.started_at,
      last_updated_at: state.last_updated_at
    }
  end

  defp count_by_field(observations, field) do
    observations
    |> Enum.group_by(&Map.get(&1, field))
    |> Enum.map(fn {key, values} -> {key, length(values)} end)
    |> Enum.into(%{})
  end

  defp recalculate_knowledge_metrics(state) do
    patterns = state.repair_patterns
    total_patterns = length(patterns)

    if total_patterns == 0 do
      state
    else
      # Calculate knowledge reuse rate
      reused_patterns = Enum.count(patterns, &(&1.reuse_count > 0))
      knowledge_reuse_rate = reused_patterns / total_patterns

      # Calculate average patch stability
      avg_stability =
        if total_patterns > 0 do
          Enum.sum_by(patterns, & &1.confidence) / total_patterns
        else
          0.0
        end

      %{
        state
        | knowledge_reuse_rate: Float.round(knowledge_reuse_rate, 3),
          patch_stability: Float.round(avg_stability, 3)
      }
    end
  end

  defp generate_law_candidates(state) do
    observations = state.observations
    patterns = state.repair_patterns

    candidates = []

    # Candidate 1: Resilience Through Recoverability
    candidate1 = check_resilience_through_recoverability(observations)
    candidates = if candidate1, do: [candidate1 | candidates], else: candidates

    # Candidate 2: Explicit Constraints Improve Survivability
    candidate2 = check_explicit_constraints(observations)
    candidates = if candidate2, do: [candidate2 | candidates], else: candidates

    # Candidate 3: Knowledge Reuse Outperforms Reinvention
    candidate3 = check_knowledge_reuse(patterns)
    candidates = if candidate3, do: [candidate3 | candidates], else: candidates

    # Candidate 4: Transferability Predicts Engineering Value
    candidate4 = check_transferability(patterns)
    candidates = if candidate4, do: [candidate4 | candidates], else: candidates

    candidates
  end

  defp check_resilience_through_recoverability(observations) do
    # Law: Systems survive not because they fail less, but because they recover faster
    failures = Enum.count(observations, &(&1.observation_type == :failure))
    recoveries = Enum.count(observations, &(&1.observation_type == :recovery))

    if failures >= 10 && recoveries >= 5 do
      recovery_rate = recoveries / failures

      if recovery_rate > 0.5 do
        %{
          id: "law_resilience_recoverability",
          title: "Resilience Through Recoverability",
          observation: "Systems with high recovery rates show higher survivability",
          evidence: %{failures: failures, recoveries: recoveries, recovery_rate: recovery_rate},
          confidence: min(recovery_rate, 1.0),
          status: :candidate
        }
      else
        nil
      end
    else
      nil
    end
  end

  defp check_explicit_constraints(observations) do
    # Law: Systems with explicit invariants fail more predictably and repair more successfully
    invariant_violations =
      Enum.count(observations, fn obs ->
        obs.origin == :requirements && obs.observation_type == :failure
      end)

    repairs = Enum.count(observations, &(&1.observation_type == :repair))

    if invariant_violations >= 5 && repairs >= 5 do
      repair_success_rate = repairs / (repairs + invariant_violations)

      %{
        id: "law_explicit_constraints",
        title: "Explicit Constraints Improve Survivability",
        observation: "Systems with explicit invariants have higher repair success rates",
        evidence: %{
          invariant_violations: invariant_violations,
          repairs: repairs,
          repair_success_rate: repair_success_rate
        },
        confidence: min(repair_success_rate, 1.0),
        status: :candidate
      }
    else
      nil
    end
  end

  defp check_knowledge_reuse(patterns) do
    # Law: Reusable repair patterns outperform novel repairs
    if length(patterns) >= 3 do
      reused = Enum.count(patterns, &(&1.reuse_count > 0))
      reuse_rate = reused / length(patterns)

      if reuse_rate > 0.3 do
        avg_success_rate =
          if reused > 0 do
            Enum.sum_by(patterns, & &1.success_rate) / length(patterns)
          else
            0.0
          end

        %{
          id: "law_knowledge_reuse",
          title: "Knowledge Reuse Outperforms Reinvention",
          observation: "Reusable repair patterns show higher success rates than novel repairs",
          evidence: %{
            total_patterns: length(patterns),
            reused_patterns: reused,
            reuse_rate: reuse_rate,
            avg_success_rate: avg_success_rate
          },
          confidence: min(reuse_rate * avg_success_rate, 1.0),
          status: :candidate
        }
      else
        nil
      end
    else
      nil
    end
  end

  defp check_transferability(patterns) do
    # Law: The most valuable solutions are those that transfer across architectures
    if length(patterns) >= 3 do
      transferred = Enum.count(patterns, &(length(&1.domains_used) > 1))
      transfer_rate = transferred / length(patterns)

      if transfer_rate > 0.2 do
        %{
          id: "law_transferability",
          title: "Transferability Predicts Engineering Value",
          observation: "Solutions that transfer across domains show higher engineering value",
          evidence: %{
            total_patterns: length(patterns),
            transferred_patterns: transferred,
            transfer_rate: transfer_rate
          },
          confidence: min(transfer_rate * 1.5, 1.0),
          status: :candidate
        }
      else
        nil
      end
    else
      nil
    end
  end

  @doc """
  Finalize current epoch and create epoch record.

  ## Parameters
  - epoch_id: Unique identifier for this epoch (e.g., "alpha_001")
  - projects_tested: Number of projects tested in this epoch

  ## Returns
  - {:ok, %Epoch{}} with complete epoch data
  """
  def finalize_epoch(epoch_id, projects_tested) do
    GenServer.call(__MODULE__, {:finalize_epoch, epoch_id, projects_tested})
  end

  @doc """
  Get all completed epochs.
  """
  def get_epochs do
    GenServer.call(__MODULE__, :get_epochs)
  end

  @doc """
  Compare two epochs to identify trends.
  """
  def compare_epochs(epoch_id1, epoch_id2) do
    GenServer.call(__MODULE__, {:compare_epochs, epoch_id1, epoch_id2})
  end

  # Private helper to get all observations from state
  defp get_all_observations(state) do
    state.observations
  end

  # Private helper to discover candidate laws from observations
  defp discover_candidate_laws_from_observations(observations) do
    # Simple pattern discovery based on observation types
    # In future, this will use more sophisticated statistical analysis
    
    # Count observation types
    failure_count = Enum.count(observations, &(&1.observation_type == :failure))
    exploit_count = Enum.count(observations, &(&1.observation_type == :exploit))
    success_count = Enum.count(observations, &(&1.observation_type == :success))
    
    total = length(observations)
    
    # Generate simple candidate laws based on patterns
    laws = []
    
    # Law 1: Failure diversity indicates architectural fragility
    if failure_count > 0 && total > 0 do
      failure_rate = failure_count / total
      if failure_rate > 0.3 do
        _laws = laws ++ [%{
          id: "law_failure_diversity",
          title: "Failure Diversity Indicates Architectural Fragility",
          statement: "Systems with high failure diversity (#{Float.round(failure_rate * 100, 1)}% failure rate) indicate architectural fragility across #{total} observations",
          confidence: 0.6,
          supporting_evidence: failure_count,
          contradicting_evidence: 0
        }]
      end
    end
    
    # Law 2: Exploit recurrence indicates security debt
    if exploit_count > 0 do
      _laws = laws ++ [%{
        id: "law_exploit_recurrence",
        title: "Exploit Recurrence Indicates Security Debt",
        statement: "Recurring exploits (#{exploit_count} found) indicate accumulated security debt",
        confidence: 0.7,
        supporting_evidence: exploit_count,
        contradicting_evidence: 0
      }]
    end
    
    # Law 3: Build success doesn't guarantee correctness
    if success_count > 0 && failure_count > 0 do
      _laws = laws ++ [%{
        id: "law_build_correctness_gap",
        title: "Build Success Doesn't Guarantee Correctness",
        statement: "Successful builds (#{success_count}) coexist with failures (#{failure_count}), indicating validation gaps",
        confidence: 0.8,
        supporting_evidence: success_count + failure_count,
        contradicting_evidence: 0
      }]
    end
    
    laws
  end
end
