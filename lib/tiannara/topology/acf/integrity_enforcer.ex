defmodule Tiannara.Topology.ACF.IntegrityEnforcer do
  @moduledoc """
  Integrity Enforcer for ACF.

  Enforces axiomatic integrity across the system and manages conservation integrity checks.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def run_integrity_check(system_state) do
    GenServer.call(__MODULE__, {:run_integrity_check, system_state})
  end

  def enforce_axiomatic_integrity(system_state) do
    GenServer.call(__MODULE__, {:enforce_axiomatic_integrity, system_state})
  end

  def get_integrity_status() do
    GenServer.call(__MODULE__, :get_integrity_status)
  end

  def get_integrity_history() do
    GenServer.call(__MODULE__, :get_integrity_history)
  end

  def set_integrity_threshold(threshold) do
    GenServer.call(__MODULE__, {:set_integrity_threshold, threshold})
  end

  def get_integrity_threshold() do
    GenServer.call(__MODULE__, :get_integrity_threshold)
  end

  def run_comprehensive_integrity_audit() do
    GenServer.call(__MODULE__, :run_comprehensive_integrity_audit)
  end

  def get_integrity_violations() do
    GenServer.call(__MODULE__, :get_integrity_violations)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Create ETS table for integrity records
    :ets.new(:integrity_records, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    # Create ETS table for integrity violations
    :ets.new(:integrity_violations, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Create ETS table for integrity thresholds
    :ets.new(:integrity_thresholds, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Initialize integrity thresholds
    :ets.insert(:integrity_thresholds, {
      :global, 0.95,  # Global integrity threshold
      :system, 0.90,  # System integrity threshold
      :law, 0.85      # Individual law integrity threshold
    })

    # Initialize integrity status
    :ets.insert(:integrity_records, {
      System.system_time(:millisecond),
      :initialized,
      1.0,
      %{}
    })

    Logger.info("Integrity Enforcer initialized")

    # Schedule periodic integrity checks
    schedule_integrity_check()

    {:ok, %{}}
  end

  @impl true
  def handle_call({:run_integrity_check, system_state}, _from, state) when is_map(system_state) do
    # Run integrity check on system state
    integrity_result = check_system_integrity(system_state)
    
    # Record integrity check
    record_integrity_check(integrity_result)
    
    Logger.info("Integrity check completed: #{integrity_result.integrity_score}")
    
    {:reply, {:ok, integrity_result}, state}
  end

  @impl true
  def handle_call({:enforce_axiomatic_integrity, system_state}, _from, state) when is_map(system_state) do
    # Enforce axiomatic integrity
    case enforce_integrity(system_state) do
      :intact ->
        Logger.info("Axiomatic integrity maintained")
        {:reply, {:ok, :intact}, state}
        
      {:violations, violations} ->
        # Handle violations
        violation_results = handle_integrity_violations(system_state, violations)
        
        Logger.warning("Detected #{length(violations)} integrity violations")
        
        {:reply, {:ok, :violations_detected, violation_results}, state}
    end
  end

  @impl true
  def handle_call(:get_integrity_status, _from, state) do
    integrity_status = get_current_integrity_status()
    
    {:reply, {:ok, integrity_status}, state}
  end

  @impl true
  def handle_call(:get_integrity_history, _from, state) do
    history = :ets.tab2list(:integrity_records)
    |> Enum.map(fn record ->
      %{
        timestamp: record.timestamp,
        status: record.status,
        integrity_score: record.integrity_score,
        details: record.details
      }
    end)
    
    {:reply, {:ok, history}, state}
  end

  @impl true
  def handle_call({:set_integrity_threshold, threshold}, _from, state) when is_number(threshold) and threshold >= 0 and threshold <= 1 do
    # Update integrity threshold
    :ets.insert(:integrity_thresholds, {:global, threshold})
    
    Logger.info("Updated global integrity threshold to #{threshold}")
    
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:get_integrity_threshold, _from, state) do
    case :ets.lookup(:integrity_thresholds, :global) do
      [{:global, threshold}] ->
        {:reply, {:ok, threshold}, state}
      [] ->
        {:reply, {:error, :threshold_not_found}, state}
    end
  end

  @impl true
  def handle_call(:run_comprehensive_integrity_audit, _from, state) do
    # Run comprehensive integrity audit
    audit_result = run_comprehensive_audit()
    
    # Record audit result
    record_integrity_check(%{
      timestamp: System.system_time(:millisecond),
      status: :audit_completed,
      integrity_score: audit_result.overall_score,
      details: audit_result
    })
    
    Logger.info("Comprehensive integrity audit completed")
    
    {:reply, {:ok, audit_result}, state}
  end

  @impl true
  def handle_call(:get_integrity_violations, _from, state) do
    violations = :ets.tab2list(:integrity_violations)
    |> Enum.map(fn violation ->
      %{
        timestamp: violation.timestamp,
        violation_type: violation.violation_type,
        severity: violation.severity,
        description: violation.description,
        affected_system: violation.affected_system
      }
    end)
    
    {:reply, {:ok, violations}, state}
  end

  # Periodic integrity check
  @impl true
  def handle_info(:integrity_check, state) do
    # Run periodic integrity check
    Logger.info("Running periodic integrity check")
    
    # Get current system state (in practice would query the actual system)
    mock_system_state = %{
      timestamp: System.system_time(:millisecond),
      components: []
    }
    
    # Run integrity check
    integrity_result = check_system_integrity(mock_system_state)
    record_integrity_check(integrity_result)
    
    # Schedule next check
    schedule_integrity_check()
    
    {:noreply, state}
  end

  # Helper functions
  defp schedule_integrity_check() do
    # Schedule integrity check every 60 seconds
    Process.send_after(self(), :integrity_check, 60_000)
  end

  defp check_system_integrity(system_state) when is_map(system_state) do
    # Calculate system integrity score
    components = Map.get(system_state, :components, [])
    
    # Check each component's integrity
    component_integrities = Enum.map(components, fn component ->
      check_component_integrity(component)
    end)
    
    # Calculate overall integrity score
    total_components = length(component_integrities)
    intact_components = Enum.count(component_integrities, fn score -> score >= 0.9 end)
    
    overall_score = if total_components > 0 do
      intact_components / total_components
    else
      1.0
    end
    
    %{
      timestamp: System.system_time(:millisecond),
      status: if(overall_score >= 0.9, do: :intact, else: :violated),
      integrity_score: overall_score,
      component_integrities: component_integrities,
      total_components: total_components,
      intact_components: intact_components
    }
  end

  defp check_component_integrity(_component) do
    state =
      try do
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            else
              nil
            end
        end
      rescue
        _ -> nil
      end

    if state do
      twin_worlds = Enum.filter(Map.values(state.worlds), &(&1.twin != nil))
      any_failed_ci = Enum.any?(twin_worlds, fn w ->
        Enum.any?(w.twin.ci_runs, &(&1.outcome == :failure))
      end)
      if any_failed_ci, do: 0.8, else: 1.0
    else
      1.0
    end
  end

  defp enforce_integrity(system_state) when is_map(system_state) do
    # Enforce axiomatic integrity
    violations = []
    
    # Check global integrity threshold
    case get_current_integrity_score() do
      score when score >= 0.95 ->
        :intact
      _ ->
        # Check specific integrity aspects
        global_check = check_global_integrity(system_state)
        law_check = check_law_integrity(system_state)
        causal_check = check_causal_integrity(system_state)
        
        if global_check == :intact and law_check == :intact and causal_check == :intact do
          :intact
        else
          violations = violations ++ [
            {global_check, "Global integrity check failed"},
            {law_check, "Law integrity check failed"},
            {causal_check, "Causal integrity check failed"}
          ]
          
          {:violations, violations}
        end
    end
  end

  defp check_global_integrity(_system_state) do
    state =
      try do
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            else
              nil
            end
        end
      rescue
        _ -> nil
      end

    if state do
      low_confidence_exists = Enum.any?(state.evidence_graph, fn {_id, node} ->
        node.type == :theory and node.value < 0.4
      end)
      if low_confidence_exists do
        {:violation, "Global axiomatic integrity compromised: low theory confidence detected"}
      else
        :intact
      end
    else
      :intact
    end
  end

  defp check_law_integrity(_system_state) do
    state =
      try do
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            else
              nil
            end
        end
      rescue
        _ -> nil
      end

    if state do
      claim_violation_exists = Enum.any?(state.evidence_graph, fn {_id, node} ->
        node.type == :claim and node.value < 0.3
      end)
      if claim_violation_exists do
        {:violation, "Conservation law integrity compromised: claim value below safety threshold"}
      else
        :intact
      end
    else
      :intact
    end
  end

  defp check_causal_integrity(_system_state) do
    state =
      try do
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            else
              nil
            end
        end
      rescue
        _ -> nil
      end

    if state do
      low_fitness_exists = Enum.any?(state.tools, fn {_id, genome} ->
        genome.fitness < 0.3
      end)
      if low_fitness_exists do
        {:violation, "Causal closure integrity compromised: untrusted tool genome detected"}
      else
        :intact
      end
    else
      :intact
    end
  end

  defp handle_integrity_violations(system_state, violations) when is_list(violations) do
    # Handle each violation
    Enum.map(violations, fn violation ->
      handle_single_violation(system_state, violation)
    end)
  end

  defp handle_single_violation(system_state, {violation_type, description}) do
    # Handle individual integrity violation
    violation_record = %{
      timestamp: System.system_time(:millisecond),
      violation_type: violation_type,
      description: description,
      affected_system: system_state,
      severity: determine_violation_severity(violation_type)
    }
    
    :ets.insert(:integrity_violations, {violation_record})
    
    violation_record
  end

  defp determine_violation_severity(violation_type) do
    case violation_type do
      :global -> :critical
      :law -> :high
      :causal -> :critical
      _ -> :medium
    end
  end

  defp record_integrity_check(integrity_result) when is_map(integrity_result) do
    # Record integrity check result
    record = {
      integrity_result.timestamp,
      integrity_result.status,
      integrity_result.integrity_score,
      integrity_result
    }
    
    :ets.insert(:integrity_records, {record})
    
    # Check if integrity threshold is met
    case :ets.lookup(:integrity_thresholds, :global) do
      [{:global, threshold}] ->
        if integrity_result.integrity_score < threshold do
          Logger.warning("Integrity score #{integrity_result.integrity_score} below threshold #{threshold}")
        end
      _ ->
        :ok
    end
  end

  defp get_current_integrity_status() do
    # Get current integrity status
    case :ets.tab2list(:integrity_records) do
      [latest | _] ->
        %{
          current_score: latest.integrity_score,
          status: latest.status,
          last_check: latest.timestamp,
          total_checks: :ets.info(:integrity_records, :size),
          total_violations: :ets.info(:integrity_violations, :size)
        }
      [] ->
        %{
          current_score: 1.0,
          status: :unknown,
          last_check: 0,
          total_checks: 0,
          total_violations: 0
        }
    end
  end

  defp get_current_integrity_score() do
    # Get current integrity score
    case :ets.tab2list(:integrity_records) do
      [latest | _] -> latest.integrity_score
      [] -> 1.0
    end
  end

  defp run_comprehensive_audit() do
    # Run comprehensive integrity audit
    audit_timestamp = System.system_time(:millisecond)
    
    # Check all integrity aspects
    global_integrity = check_global_integrity(%{})
    law_integrity = check_law_integrity(%{})
    causal_integrity = check_causal_integrity(%{})
    component_integrity = check_all_component_integrities()
    
    # Calculate overall score
    checks = [global_integrity, law_integrity, causal_integrity | component_integrity]
    intact_checks = Enum.count(checks, fn check -> check == :intact end)
    total_checks = length(checks)
    
    overall_score = if total_checks > 0 do
      intact_checks / total_checks
    else
      1.0
    end
    
    # Generate audit report
    %{
      timestamp: audit_timestamp,
      overall_score: overall_score,
      intact_checks: intact_checks,
      total_checks: total_checks,
      global_integrity: global_integrity,
      law_integrity: law_integrity,
      causal_integrity: causal_integrity,
      component_integrity: component_integrity,
      recommendations: generate_audit_recommendations(overall_score, checks)
    }
  end

  defp check_all_component_integrities() do
    # Check integrity of all components
    components = []
    
    # Mock implementation
    Enum.map(components, fn _component ->
      check_component_integrity(%{})
    end)
  end

  defp generate_audit_recommendations(overall_score, checks) do
    score_recs =
      cond do
        overall_score >= 0.95 -> ["System integrity is excellent"]
        overall_score >= 0.85 -> ["System integrity is good but could be improved"]
        true -> ["System integrity requires immediate attention"]
      end

    failed_checks = Enum.filter(checks, fn check -> check != :intact end)

    check_recs =
      case failed_checks do
        [] -> ["All integrity checks passed"]
        _ -> ["Address failed integrity checks"]
      end

    score_recs ++ check_recs
  end
end
