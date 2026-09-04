defmodule Tiannara.Topology.RRG do
  @moduledoc """
  Recursive Rate Governance (RRG).

  Implements recursive rate limiting, governance policies, and system-wide regulation.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def define_governance_policy(policy_id, rules, opts \\ []) do
    GenServer.call(__MODULE__, {:define_governance_policy, policy_id, rules, opts})
  end

  def apply_rate_limit(resource_id, user_id, request_count \\ 1) do
    GenServer.call(__MODULE__, {:apply_rate_limit, resource_id, user_id, request_count})
  end

  def get_governance_policy(policy_id) do
    GenServer.call(__MODULE__, {:get_governance_policy, policy_id})
  end

  def get_all_policies() do
    GenServer.call(__MODULE__, :get_all_policies)
  end

  def get_user_rate_limits(user_id) do
    GenServer.call(__MODULE__, {:get_user_rate_limits, user_id})
  end

  def get_resource_usage(resource_id) do
    GenServer.call(__MODULE__, {:get_resource_usage, resource_id})
  end

  def enforce_governance_compliance() do
    GenServer.call(__MODULE__, :enforce_governance_compliance)
  end

  def get_governance_metrics() do
    GenServer.call(__MODULE__, :get_governance_metrics)
  end

  def recursive_rate_check(user_id, resource_ids) when is_list(resource_ids) do
    GenServer.call(__MODULE__, {:recursive_rate_check, user_id, resource_ids})
  end

  def update_policy_threshold(policy_id, new_thresholds) do
    GenServer.call(__MODULE__, {:update_policy_threshold, policy_id, new_thresholds})
  end

  def audit_governance_violations() do
    GenServer.call(__MODULE__, :audit_governance_violations)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS tables for governance management
    :ets.new(:governance_policies, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(:rate_limits, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:resource_usage, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:governance_violations, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    :ets.new(:governance_metrics, [
      :bag,
      :public,
      :named_table,
      {:write_concurrency, true}
    ])

    # Default governance policies
    default_policies = %{
      "system_core" => %{
        type: :global,
        rate_limits: %{requests_per_second: 1000, requests_per_minute: 60000},
        recursive_depth: 5,
        penalty_multiplier: 2.0,
        enabled: true
      },
      "user_requests" => %{
        type: :user,
        rate_limits: %{requests_per_minute: 100, requests_per_hour: 1000},
        recursive_depth: 3,
        penalty_multiplier: 1.5,
        enabled: true
      },
      "resource_access" => %{
        type: :resource,
        rate_limits: %{accesses_per_second: 100, accesses_per_minute: 1000},
        recursive_depth: 4,
        penalty_multiplier: 1.8,
        enabled: true
      }
    }

    # Initialize default policies
    Enum.each(default_policies, fn {policy_id, policy_data} ->
      :ets.insert(:governance_policies, {policy_id, policy_data})
    end)

    # Configuration
    config = %{
      max_policies: 100,
      enforcement_mode: :strict,  # :strict, :adaptive, :monitor
      violation_penalty_duration: 300_000,  # 5 minutes
      audit_interval: 60_000,  # 1 minute
      recursive_limit: 10,
      auto_adjust_enabled: true,
      adaptive_threshold_factor: 1.2
    }

    Logger.info("Recursive Rate Governance initialized with #{map_size(default_policies)} default policies")
    
    # Start audit timer
    Process.send_after(self(), :enforce_governance_compliance, config.audit_interval)
    
    {:ok, %{
      config: config,
      total_policies: map_size(default_policies),
      active_violations: 0,
      total_violations: 0,
      last_audit: 0,
      compliance_rate: 1.0,
      adaptive_adjustments: 0
    }}
  end

  @impl true
  def handle_call({:define_governance_policy, policy_id, rules, opts}, _from, state) do
    # Validate policy
    case validate_governance_policy(policy_id, rules) do
      :ok ->
        # Check policy limit
        if state.total_policies >= state.config.max_policies do
          {:reply, {:error, :policy_limit_exceeded}, state}
        else
          # Create policy
          policy_data = create_governance_policy(policy_id, rules, opts)
          :ets.insert(:governance_policies, {policy_id, policy_data})
          
          Logger.info("Defined governance policy #{policy_id}")
          
          {:reply, :ok, 
           %{state | 
             total_policies: state.total_policies + 1
           }}
        end
        
      {:error, reason} ->
        Logger.error("Invalid governance policy: #{reason}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:apply_rate_limit, resource_id, user_id, request_count}, _from, state) do
    # Get applicable policies
    applicable_policies = get_applicable_policies(resource_id, user_id)
    
    # Apply rate limits
    case apply_rate_limits(resource_id, user_id, request_count, applicable_policies) do
      :allowed ->
        Logger.debug("Rate limit allowed for #{user_id} on #{resource_id}")
        {:reply, {:ok, :allowed}, state}
        
      {:denied, reason} ->
        # Record violation
        record_governance_violation(resource_id, user_id, reason)
        
        Logger.warning("Rate limit denied for #{user_id} on #{resource_id}: #{reason}")
        {:reply, {:error, reason}, 
         %{state | 
           active_violations: state.active_violations + 1,
           total_violations: state.total_violations + 1
         }}
        
      {:adaptive, adjusted_limit} ->
        Logger.info("Applied adaptive rate limiting for #{user_id} on #{resource_id}")
        {:reply, {:ok, :adaptive, adjusted_limit}, state}
    end
  end

  @impl true
  def handle_call({:get_governance_policy, policy_id}, _from, state) do
    case :ets.lookup(:governance_policies, policy_id) do
      [{^policy_id, policy_data}] ->
        {:reply, {:ok, policy_data}, state}
      [] ->
        {:reply, {:error, :policy_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_all_policies, _from, state) do
    policies = :ets.tab2list(:governance_policies)
    |> Enum.map(fn {policy_id, policy_data} ->
      %{id: policy_id, data: policy_data}
    end)
    
    {:reply, {:ok, policies}, state}
  end

  @impl true
  def handle_call({:get_user_rate_limits, user_id}, _from, state) do
    # Get all rate limits for user
    user_limits = :ets.select(:rate_limits, [{
      {user_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    # Calculate effective limits
    effective_limits = calculate_effective_limits(user_limits)
    
    {:reply, {:ok, effective_limits}, state}
  end

  @impl true
  def handle_call({:get_resource_usage, resource_id}, _from, state) do
    # Get resource usage data
    usage_data = :ets.select(:resource_usage, [{
      {resource_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    # Calculate usage statistics
    usage_stats = calculate_resource_usage_stats(usage_data)
    
    {:reply, {:ok, usage_stats}, state}
  end

  @impl true
  def handle_call(:enforce_governance_compliance, _from, state) do
    # Enforce compliance across all policies
    compliance_result = enforce_compliance_across_policies()
    
    # Update compliance metrics
    compliance_metrics = %{
      timestamp: System.system_time(:millisecond),
      total_policies: state.total_policies,
      active_violations: state.active_violations,
      compliance_rate: compliance_result.compliance_rate,
      violations_detected: compliance_result.violations_count,
      actions_taken: compliance_result.actions_taken
    }
    
    :ets.insert(:governance_metrics, {compliance_metrics})
    
    Logger.info("Governance compliance audit: #{compliance_result.compliance_rate} compliance rate")
    
    {:reply, {:ok, compliance_result}, state}
  end

  @impl true
  def handle_call({:recursive_rate_check, user_id, resource_ids}, _from, state) when is_list(resource_ids) do
    # Perform recursive rate check across multiple resources
    check_result = perform_recursive_rate_check(user_id, resource_ids, state.config.recursive_limit)
    
    case check_result do
      :allowed ->
        Logger.debug("Recursive rate check allowed for #{user_id}")
        {:reply, {:ok, :allowed}, state}
        
      {:denied, reason} ->
        Logger.warning("Recursive rate check denied for #{user_id}: #{reason}")
        {:reply, {:error, reason}, 
         %{state | 
           active_violations: state.active_violations + 1,
           total_violations: state.total_violations + 1
         }}
        
      {:adaptive, adjusted_limits} ->
        Logger.info("Applied recursive adaptive rate limiting for #{user_id}")
        {:reply, {:ok, :adaptive, adjusted_limits}, state}
    end
  end

  @impl true
  def handle_call({:update_policy_threshold, policy_id, new_thresholds}, _from, state) do
    case :ets.lookup(:governance_policies, policy_id) do
      [{^policy_id, policy_data}] ->
        # Update policy thresholds
        updated_policy = %{policy_data | 
          rate_limits: Map.merge(policy_data.rate_limits, new_thresholds),
          updated_at: System.system_time(:millisecond)
        }
        
        :ets.insert(:governance_policies, {policy_id, updated_policy})
        
        Logger.info("Updated thresholds for policy #{policy_id}")
        
        {:reply, :ok, state}
        
      [] ->
        {:reply, {:error, :policy_not_found}, state}
    end
  end

  @impl true
  def handle_call(:audit_governance_violations, _from, state) do
    # Get all violations
    violations = :ets.tab2list(:governance_violations)
    
    # Analyze violations
    violation_analysis = analyze_governance_violations(violations)
    
    # Generate audit report
    audit_report = %{
      timestamp: System.system_time(:millisecond),
      total_violations: length(violations),
      violation_analysis: violation_analysis,
      recommendations: generate_violation_recommendations(violation_analysis),
      compliance_status: calculate_compliance_status(violations)
    }
    
    Logger.info("Governance violations audit: #{length(violations)} violations found")
    
    {:reply, {:ok, audit_report}, state}
  end

  # Periodic compliance enforcement
  @impl true
  def handle_info(:enforce_governance_compliance, state) do
    Logger.info("Performing scheduled governance compliance enforcement")
    
    # Enforce compliance
    compliance_result = enforce_compliance_across_policies()
    
    # Update state
    new_state = %{state | 
      compliance_rate: compliance_result.compliance_rate,
      last_audit: System.system_time(:millisecond)
    }
    
    # Schedule next enforcement
    Process.send_after(self(), :enforce_governance_compliance, state.config.audit_interval)
    
    {:noreply, new_state}
  end

  # Helper functions
  defp validate_governance_policy(policy_id, rules) when is_binary(policy_id) and is_map(rules) do
    case policy_id do
      "" -> {:error, :empty_policy_id}
      _ ->
        case rules do
          %{rate_limits: rate_limits} when is_map(rate_limits) -> :ok
          _ -> {:error, :invalid_rate_limits}
        end
    end
  end

  defp validate_governance_policy(_, _), do: {:error, :invalid_parameters}

  defp create_governance_policy(policy_id, rules, opts) do
    %{
      id: policy_id,
      type: Keyword.get(opts, :type, :resource),
      rate_limits: rules.rate_limits,
      recursive_depth: Keyword.get(opts, :recursive_depth, 3),
      penalty_multiplier: Keyword.get(opts, :penalty_multiplier, 1.5),
      enabled: Keyword.get(opts, :enabled, true),
      created_at: System.system_time(:millisecond),
      updated_at: System.system_time(:millisecond),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  defp get_applicable_policies(_resource_id, _user_id) do
    # Get policies applicable to resource and user
    all_policies = :ets.tab2list(:governance_policies)
    |> Enum.map(fn {policy_id, policy_data} ->
      {policy_id, policy_data}
    end)
    
    # Filter by enabled policies
    Enum.filter(all_policies, fn {_, policy_data} -> policy_data.enabled end)
  end

  defp apply_rate_limits(resource_id, user_id, request_count, applicable_policies) do
    # Apply each policy's rate limits
    results = Enum.map(applicable_policies, fn {policy_id, policy_data} ->
      check_single_policy_limit(resource_id, user_id, request_count, policy_id, policy_data)
    end)
    
    # Aggregate results
    case results do
      [] -> :allowed  # No policies apply
        
      results ->
        # Check if any policy denies access
        denials = Enum.filter(results, fn result -> 
          case result do
            {:denied, _} -> true
            _ -> false
          end
        end)
        
        if length(denials) > 0 do
          # Return first denial
          hd(denials)
        else
          # Check for adaptive results
          adaptive = Enum.filter(results, fn result -> 
            case result do
              {:adaptive, _} -> true
              _ -> false
            end
          end)
          
          if length(adaptive) > 0 do
            hd(adaptive)
          else
            :allowed
          end
        end
    end
  end

  defp check_single_policy_limit(resource_id, user_id, request_count, policy_id, policy_data) do
    # Get current usage
    current_usage = get_current_usage(resource_id, user_id, policy_id)
    
    # Check rate limits
    rate_limits = policy_data.rate_limits
    
    case check_rate_limit_exceeded(current_usage, rate_limits, request_count) do
      :within_limit ->
        # Update usage
        update_usage(resource_id, user_id, policy_id, request_count)
        :allowed
        
      :adaptive_limit ->
        # Apply adaptive adjustment
        adjusted_limit = apply_adaptive_adjustment(current_usage, rate_limits, policy_data)
        update_usage(resource_id, user_id, policy_id, request_count)
        {:adaptive, adjusted_limit}
    end
  end

  defp get_current_usage(resource_id, user_id, policy_id) do
    # Get usage from rate limits table
    usage = :ets.select(:rate_limits, [{
      {user_id, resource_id, policy_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    case usage do
      [usage_data] -> usage_data
      [] -> %{count: 0, last_reset: System.system_time(:millisecond)}
    end
  end

  defp check_rate_limit_exceeded(current_usage, rate_limits, request_count) do
    current_count = current_usage.count + request_count
    now = System.system_time(:millisecond)
    
    # Check per-second limit
    case rate_limits.requests_per_second do
      limit when limit > 0 ->
        time_window = 1000  # 1 second
        time_since_reset = now - current_usage.last_reset
        
        if time_since_reset >= time_window do
          # Reset counter
          :within_limit
        else
          if current_count > limit do
            :exceeded_limit
          else
            :within_limit
          end
        end
        
      _ -> :within_limit
    end
    
    # Check per-minute limit
    case rate_limits.requests_per_minute do
      limit when limit > 0 ->
        time_window = 60_000  # 1 minute
        time_since_reset = now - current_usage.last_reset
        
        if time_since_reset >= time_window do
          # Reset counter
          :within_limit
        else
          if current_count > limit do
            :exceeded_limit
          else
            :within_limit
          end
        end
        
      _ -> :within_limit
    end
    
    # Check adaptive conditions
    case rate_limits.adaptive_threshold do
      threshold when threshold > 0 ->
        if current_count / threshold > 0.8 do
          :adaptive_limit
        else
          :within_limit
        end
        
      _ ->
        :within_limit
    end
  end

  defp update_usage(resource_id, user_id, policy_id, request_count) do
    current_usage = get_current_usage(resource_id, user_id, policy_id)
    
    updated_usage = %{current_usage | 
      count: current_usage.count + request_count,
      last_updated: System.system_time(:millisecond)
    }
    
    :ets.insert(:rate_limits, {user_id, resource_id, policy_id, updated_usage})
    
    # Record resource usage
    usage_record = %{
      timestamp: System.system_time(:millisecond),
      resource_id: resource_id,
      user_id: user_id,
      request_count: request_count,
      policy_id: policy_id
    }
    
    :ets.insert(:resource_usage, {resource_id, usage_record})
  end

  defp apply_adaptive_adjustment(current_usage, rate_limits, policy_data) do
    # Apply adaptive rate limiting based on current usage
    usage_ratio = current_usage.count / max(rate_limits.requests_per_minute, 1)
    
    # Apply adaptive factor
    adaptive_factor = 1.0 / (1.0 + usage_ratio * policy_data.penalty_multiplier)
    
    # Calculate adjusted limit
    adjusted_limit = max(1, trunc(rate_limits.requests_per_minute * adaptive_factor))
    
    adjusted_limit
  end

  defp calculate_effective_limits(user_limits) when is_list(user_limits) do
    # Calculate effective rate limits from all applicable policies
    limits = Enum.map(user_limits, fn usage_data ->
      usage_data.rate_limits
    end)
    
    # Find minimum limits across all policies
    Enum.reduce(limits, %{}, fn policy_limits, acc ->
      Map.merge(acc, policy_limits, fn key, current_val ->
        min(current_val, Map.get(policy_limits, key, current_val))
      end)
    end)
  end

  defp calculate_resource_usage_stats(usage_data) when is_list(usage_data) do
    case length(usage_data) do
      0 -> %{}
      
      _ ->
        # Calculate statistics
        total_requests = Enum.sum(Enum.map(usage_data, & &1.request_count))
        avg_requests = total_requests / length(usage_data)
        
        # Time range
        timestamps = Enum.map(usage_data, & &1.timestamp)
        time_range = %{start: Enum.min(timestamps), end: Enum.max(timestamps)}
        
        # Top users
        user_counts = Enum.reduce(usage_data, %{}, fn record, acc ->
          Map.update(acc, record.user_id, 1, &(&1 + 1))
        end)
        
        top_users = user_counts
        |> Enum.sort_by(&elem(&1, 1), :desc)
        |> Enum.take(5)
        
        %{
          total_requests: total_requests,
          average_requests: avg_requests,
          time_range: time_range,
          top_users: top_users,
          unique_users: map_size(user_counts),
          timestamp: System.system_time(:millisecond)
        }
    end
  end

  defp enforce_compliance_across_policies() do
    # Get all active policies
    policies = :ets.tab2list(:governance_policies)
    
    # Check compliance for each policy
    compliance_results = Enum.map(policies, fn {policy_id, policy_data} ->
      check_policy_compliance(policy_id, policy_data)
    end)
    
    # Calculate overall compliance rate
    compliant_policies = Enum.filter(compliance_results, & &1.compliant)
    compliance_rate = if length(compliance_results) > 0 do
      length(compliant_policies) / length(compliance_results)
    else
      1.0
    end
    
    # Count violations
    violations_count = Enum.count(compliance_results, fn result ->
      not result.compliant
    end)
    
    # Take enforcement actions
    actions_taken = Enum.reduce(compliance_results, [], fn result, actions ->
      if not result.compliant do
        result.actions ++ actions
      else
        actions
      end
    end)
    
    %{
      compliance_rate: compliance_rate,
      violations_count: violations_count,
      total_policies: length(compliance_results),
      actions_taken: actions_taken
    }
  end

  defp check_policy_compliance(policy_id, policy_data) do
    # Check if policy is being enforced correctly
    policy_violations = :ets.select(:governance_violations, [{
      {policy_id, :"$1"},
      [],
      [:"$1"]
    }])
    
    # Check for excessive violations
    recent_violations = Enum.filter(policy_violations, fn violation ->
      System.system_time(:millisecond) - violation.timestamp < 60_000  # Last minute
    end)
    
    # Determine if policy is compliant
    compliant = length(recent_violations) < 5  # Allow up to 5 violations per minute
    
    # Generate enforcement actions if needed
    actions = if not compliant do
      generate_enforcement_actions(policy_id, policy_data, recent_violations)
    else
      []
    end
    
    %{
      policy_id: policy_id,
      compliant: compliant,
      violations_count: length(recent_violations),
      actions: actions
    }
  end

  defp generate_enforcement_actions(_policy_id, _policy_data, violations) do
    actions = []
    
    # Reduce rate limits if too many violations
    if length(violations) > 10 do
      _actions = actions ++ ["reduce_rate_limits"]
    end
    
    # Enable adaptive mode
    if length(violations) > 5 do
      _actions = actions ++ ["enable_adaptive_mode"]
    end
    
    # Temporarily disable policy if severe violations
    if length(violations) > 20 do
      _actions = actions ++ ["temporarily_disable"]
    end
    
    actions
  end

  defp perform_recursive_rate_check(user_id, resource_ids, max_depth) when length(resource_ids) <= max_depth do
    # Recursive rate check with depth limit
    case check_recursive_depth(user_id, resource_ids, 1) do
      :allowed -> :allowed
      {:denied, reason} -> {:denied, reason}
      {:adaptive, limits} -> {:adaptive, limits}
    end
  end

  defp perform_recursive_rate_check(_, _, _), do: {:denied, "Recursive depth exceeded"}

  defp check_recursive_depth(user_id, resource_ids, current_depth) do
    if current_depth > length(resource_ids) do
      :allowed
    else
      resource_id = Enum.at(resource_ids, current_depth - 1)
      
      case apply_rate_limit(resource_id, user_id, 1) do
        {:ok, :allowed} ->
          check_recursive_depth(user_id, resource_ids, current_depth + 1)
        {:ok, :adaptive, adjusted_limit} ->
          {:adaptive, %{current_depth => adjusted_limit}}
        {:error, reason} ->
          {:denied, reason}
      end
    end
  end

  defp record_governance_violation(resource_id, user_id, reason) do
    violation = %{
      timestamp: System.system_time(:millisecond),
      resource_id: resource_id,
      user_id: user_id,
      reason: reason,
      severity: determine_violation_severity(reason)
    }
    
    :ets.insert(:governance_violations, {resource_id, violation})
    :ets.insert(:governance_violations, {user_id, violation})
  end

  defp determine_violation_severity(reason) do
    case reason do
      "Rate limit exceeded" -> :medium
      "Recursive depth exceeded" -> :high
      "System overload" -> :critical
      _ -> :low
    end
  end

  defp analyze_governance_violations(violations) do
    # Analyze violation patterns
    violation_stats = %{
      total_violations: length(violations),
      by_severity: Enum.group_by(violations, & &1.severity) |> Enum.map(fn {severity, viol_list} -> {severity, length(viol_list)} end) |> Map.new(),
      by_resource: Enum.group_by(violations, & &1.resource_id) |> Enum.map(fn {res_id, viol_list} -> {res_id, length(viol_list)} end) |> Map.new(),
      by_user: Enum.group_by(violations, & &1.user_id) |> Enum.map(fn {user_id, viol_list} -> {user_id, length(viol_list)} end) |> Map.new()
    }
    
    violation_stats
  end

  defp generate_violation_recommendations(violation_analysis) do
    recommendations = []
    
    # Add recommendations based on violation patterns
    case violation_analysis.by_severity do
      %{critical: count} when count > 0 ->
        _recommendations = recommendations ++ ["Critical violations detected - consider system-wide rate limit adjustments"]
      _ ->
        :ok
    end
    
    case violation_analysis.by_resource do
      %{res_id: res_id, count: count} when count > 10 ->
        _recommendations = recommendations ++ ["High violation rate on resource #{res_id} - consider additional rate limiting"]
      _ ->
        :ok
    end
    
    recommendations
  end

  defp calculate_compliance_status(violations) do
    case length(violations) do
      0 -> :fully_compliant
      count when count <= 5 -> :mostly_compliant
      count when count <= 20 -> :partially_compliant
      _ -> :non_compliant
    end
  end
end
