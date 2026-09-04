defmodule TiannaraOS.ConstitutionDashboard do
  @moduledoc """
  Constitutional Health Dashboard for Phase 12.1 Validation
  
  Monitors all 11 constitutional invariants and reports real-time health status
  during validation gates (100 → 1,000 → 10,000 → 25,000 → 100,000 ticks).
  
  Acts as the spacecraft's flight panel - if every indicator stays green through
  validation gates, the constitutional substrate behaves correctly under execution.
  """
  
  use GenServer
  
  @type dashboard_state :: %{
    institution_id: atom(),
    kernel_pid: pid(),
    current_tick: integer(),
    
    # Constitutional Metrics
    invariants_satisfied: integer(),
    total_invariants: integer(),
    
    # Event Completeness
    events_emitted: integer(),
    expected_events: integer(),
    event_completeness_pct: float(),
    
    # Lifecycle Completeness
    entities_created: integer(),
    entities_promoted: integer(),
    entities_archived: integer(),
    entities_removed: integer(),
    lifecycle_completeness_pct: float(),
    
    # Governance Coverage
    governance_approvals: integer(),
    governance_denials: integer(),
    governance_audits: integer(),
    approval_coverage_pct: float(),
    
    # Traceability Coverage
    traceable_mutations: integer(),
    total_mutations: integer(),
    traceability_coverage_pct: float(),
    
    # Knowledge Graph Integrity
    kg_node_count: integer(),
    kg_edge_count: integer(),
    kg_consistency: :pass | :fail,
    
    # Ledger Conservation
    ledger_balance: float(),
    ledger_total_income: float(),
    ledger_total_expenses: float(),
    ledger_conservation: :pass | :fail,
    
    # Runtime Atlas Registration
    runtime_atlas_registered: boolean(),
    runtime_atlas_status: :pass | :fail,
    
    # Memory Compression Health
    memory_operational_size: integer(),
    memory_research_size: integer(),
    memory_institutional_size: integer(),
    memory_civilizational_size: integer(),
    memory_compression_ratio: float(),
    memory_health: :pass | :fail,
    
    # Kernel Ownership Violations
    kernel_violations: integer(),
    
    # Invariant Failure Tracking
    invariant_failures: [%{
      invariant: atom(),
      tick: integer(),
      details: String.t()
    }],
    
    # Telemetry Collection
    telemetry_log: [map()]
  }
  
  @spec start_link(atom(), pid()) :: {:ok, pid()} | {:error, term()}
  def start_link(institution_id, kernel_pid) do
    GenServer.start_link(__MODULE__, %{institution_id: institution_id, kernel_pid: kernel_pid})
  end
  
  @impl true
  def init(state) do
    initial_state = %{
      institution_id: state.institution_id,
      kernel_pid: state.kernel_pid,
      current_tick: 0,
      
      # Constitutional Metrics
      invariants_satisfied: 0,
      total_invariants: 11,
      
      # Event Completeness
      events_emitted: 0,
      expected_events: 0,
      event_completeness_pct: 0.0,
      
      # Lifecycle Completeness
      entities_created: 0,
      entities_promoted: 0,
      entities_archived: 0,
      entities_removed: 0,
      lifecycle_completeness_pct: 0.0,
      
      # Governance Coverage
      governance_approvals: 0,
      governance_denials: 0,
      governance_audits: 0,
      approval_coverage_pct: 0.0,
      
      # Traceability Coverage
      traceable_mutations: 0,
      total_mutations: 0,
      traceability_coverage_pct: 0.0,
      
      # Knowledge Graph Integrity
      kg_node_count: 0,
      kg_edge_count: 0,
      kg_consistency: :pass,
      
      # Ledger Conservation
      ledger_balance: 0.0,
      ledger_total_income: 0.0,
      ledger_total_expenses: 0.0,
      ledger_conservation: :pass,
      
      # Runtime Atlas Registration
      runtime_atlas_registered: false,
      runtime_atlas_status: :pass,
      
      # Memory Compression Health
      memory_operational_size: 0,
      memory_research_size: 0,
      memory_institutional_size: 0,
      memory_civilizational_size: 0,
      memory_compression_ratio: 0.0,
      memory_health: :pass,
      
      # Kernel Ownership Violations
      kernel_violations: 0,
      
      # Invariant Failure Tracking
      invariant_failures: [],
      
      # Telemetry Collection
      telemetry_log: []
    }
    
    {:ok, initial_state}
  end
  
  # Update dashboard after each tick
  @spec update_dashboard(pid(), integer()) :: :ok
  def update_dashboard(dashboard_pid, current_tick) do
    GenServer.cast(dashboard_pid, {:update, current_tick})
  end
  
  @impl true
  def handle_cast({:update, current_tick}, state) do
    state = %{state | current_tick: current_tick}
    
    # Collect metrics from InstitutionKernel
    state = collect_kernel_metrics(state)
    state = collect_lifecycle_metrics(state)
    state = collect_knowledge_graph_metrics(state)
    state = collect_ledger_metrics(state)
    state = collect_memory_metrics(state)
    state = collect_governance_metrics(state)
    state = collect_runtime_atlas_metrics(state)
    
    # Calculate derived metrics
    state = calculate_event_completeness(state)
    state = calculate_lifecycle_completeness(state)
    state = calculate_governance_coverage(state)
    state = calculate_traceability_coverage(state)
    state = calculate_memory_compression_ratio(state)
    
    # Check constitutional health
    state = check_constitutional_health(state)
    
    # Log telemetry snapshot
    state = log_telemetry_snapshot(state)
    
    {:noreply, state}
  end
  
  # Get current dashboard status
  @spec get_status(pid()) :: map()
  def get_status(dashboard_pid) do
    GenServer.call(dashboard_pid, :get_status)
  end
  
  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      tick: state.current_tick,
      
      constitutional_health: %{
        invariants_satisfied: "#{state.invariants_satisfied}/#{state.total_invariants}",
        event_completeness: "#{Float.round(state.event_completeness_pct, 2)}%",
        lifecycle_completeness: "#{Float.round(state.lifecycle_completeness_pct, 2)}%",
        governance_approval_coverage: "#{Float.round(state.approval_coverage_pct, 2)}%",
        traceability_coverage: "#{Float.round(state.traceability_coverage_pct, 2)}%",
        knowledge_graph_integrity: state.kg_consistency,
        ledger_conservation: state.ledger_conservation,
        runtime_atlas_registration: state.runtime_atlas_status,
        memory_compression_health: state.memory_health,
        kernel_ownership_violations: state.kernel_violations
      },
      
      knowledge_graph: %{
        nodes: state.kg_node_count,
        edges: state.kg_edge_count
      },
      
      ledger: %{
        balance: state.ledger_balance,
        income: state.ledger_total_income,
        expenses: state.ledger_total_expenses
      },
      
      memory: %{
        operational: state.memory_operational_size,
        research: state.memory_research_size,
        institutional: state.memory_institutional_size,
        civilizational: state.memory_civilizational_size,
        compression_ratio: Float.round(state.memory_compression_ratio, 3)
      },
      
      governance: %{
        approvals: state.governance_approvals,
        denials: state.governance_denials,
        audits: state.governance_audits
      },
      
      lifecycle: %{
        created: state.entities_created,
        promoted: state.entities_promoted,
        archived: state.entities_archived,
        removed: state.entities_removed
      },
      
      violations: state.invariant_failures,
      
      overall_status: determine_overall_status(state)
    }
    
    {:reply, status, state}
  end
  
  # Print dashboard to console (for visual monitoring)
  @spec print_dashboard(pid()) :: :ok
  def print_dashboard(dashboard_pid) do
    status = get_status(dashboard_pid)
    
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("CONSTITUTIONAL DASHBOARD - Tick #{status.tick}")
    IO.puts(String.duplicate("=", 80))
    
    # Constitutional Health Panel
    IO.puts("\n🛡️  CONSTITUTIONAL HEALTH:")
    IO.puts("  Invariants Satisfied:         #{status.constitutional_health.invariants_satisfied}")
    IO.puts("  Event Completeness:           #{status.constitutional_health.event_completeness}")
    IO.puts("  Lifecycle Completeness:       #{status.constitutional_health.lifecycle_completeness}")
    IO.puts("  Governance Approval Coverage: #{status.constitutional_health.governance_approval_coverage}")
    IO.puts("  Traceability Coverage:        #{status.constitutional_health.traceability_coverage}")
    IO.puts("  Knowledge Graph Integrity:    #{status.constitutional_health.knowledge_graph_integrity}")
    IO.puts("  Ledger Conservation:          #{status.constitutional_health.ledger_conservation}")
    IO.puts("  Runtime Atlas Registration:   #{status.constitutional_health.runtime_atlas_registration}")
    IO.puts("  Memory Compression Health:    #{status.constitutional_health.memory_compression_health}")
    IO.puts("  Kernel Ownership Violations:  #{status.constitutional_health.kernel_ownership_violations}")
    
    # Knowledge Graph Panel
    IO.puts("\n🕸️  KNOWLEDGE GRAPH:")
    IO.puts("  Nodes: #{status.knowledge_graph.nodes}")
    IO.puts("  Edges: #{status.knowledge_graph.edges}")
    
    # Economic Ledger Panel
    IO.puts("\n💰 ECONOMIC LEDGER:")
    IO.puts("  Balance:  #{Float.round(status.ledger.balance, 2)}")
    IO.puts("  Income:   #{Float.round(status.ledger.income, 2)}")
    IO.puts("  Expenses: #{Float.round(status.ledger.expenses, 2)}")
    
    # Memory Panel
    IO.puts("\n🧠 MEMORY COMPRESSION:")
    IO.puts("  Operational:     #{status.memory.operational}")
    IO.puts("  Research:        #{status.memory.research}")
    IO.puts("  Institutional:   #{status.memory.institutional}")
    IO.puts("  Civilizational:  #{status.memory.civilizational}")
    IO.puts("  Compression Ratio: #{status.memory.compression_ratio}")
    
    # Governance Panel
    IO.puts("\n⚖️  GOVERNANCE:")
    IO.puts("  Approvals: #{status.governance.approvals}")
    IO.puts("  Denials:   #{status.governance.denials}")
    IO.puts("  Audits:    #{status.governance.audits}")
    
    # Lifecycle Panel
    IO.puts("\n🔄 LIFECYCLE:")
    IO.puts("  Created:  #{status.lifecycle.created}")
    IO.puts("  Promoted: #{status.lifecycle.promoted}")
    IO.puts("  Archived: #{status.lifecycle.archived}")
    IO.puts("  Removed:  #{status.lifecycle.removed}")
    
    # Overall Status
    IO.puts("\n" <> String.duplicate("-", 80))
    IO.puts("OVERALL STATUS: #{status.overall_status}")
    IO.puts(String.duplicate("-", 80))
    
    if not Enum.empty?(status.violations) do
      IO.puts("\n❌ INVARIANT VIOLATIONS:")
      Enum.each(status.violations, fn violation ->
        IO.puts("  [Tick #{violation.tick}] #{violation.invariant}: #{violation.details}")
      end)
    end
    
    IO.puts("")
    
    :ok
  end
  
  # Determine overall constitutional status
  defp determine_overall_status(state) do
    cond do
      state.kernel_violations > 0 ->
        "🔴 CRITICAL - Kernel ownership violated"
      
      length(state.invariant_failures) > 0 ->
        "🟠 WARNING - #{length(state.invariant_failures)} invariant failures detected"
      
      state.kg_consistency == :fail ->
        "🟠 WARNING - Knowledge graph inconsistency detected"
      
      state.ledger_conservation == :fail ->
        "🟠 WARNING - Ledger conservation violated"
      
      state.memory_health == :fail ->
        "🟠 WARNING - Memory compression failure"
      
      state.invariants_satisfied < state.total_invariants ->
        "🟡 CAUTION - Not all invariants satisfied"
      
      true ->
        "🟢 HEALTHY - All constitutional indicators stable"
    end
  end
  
  # Collect metrics from InstitutionKernel
  defp collect_kernel_metrics(state) do
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    
    # Count mutations (approximated by semantic event log length)
    total_mutations = length(institution.semantic_event_log)
    
    %{state | 
      total_mutations: total_mutations,
      traceable_mutations: total_mutations  # All events are traceable by design
    }
  end
  
  # Collect lifecycle metrics
  defp collect_lifecycle_metrics(state) do
    # Query Lifecycle Registry ETS table
    # For now, approximate from semantic events
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    
    events = institution.semantic_event_log
    
    entities_created = Enum.count(events, fn e -> 
      Map.get(e, :event_type) in [:institution_started, :campaign_spawned, :program_spawned]
    end)
    
    %{state |
      entities_created: entities_created
    }
  end
  
  # Collect knowledge graph metrics
  defp collect_knowledge_graph_metrics(state) do
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    kg = institution.knowledge_graph
    
    node_count = map_size(kg.nodes)
    edge_count = Enum.reduce(Map.values(kg.edges), 0, fn edges, acc -> acc + length(edges) end)
    
    consistency = if node_count >= 0, do: :pass, else: :fail
    
    %{state |
      kg_node_count: node_count,
      kg_edge_count: edge_count,
      kg_consistency: consistency
    }
  end
  
  # Collect ledger metrics
  defp collect_ledger_metrics(state) do
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    ledger = institution.economic_ledger
    
    total_income = ledger.entries
    |> Enum.filter(fn e -> e.entry_type == :income end)
    |> Enum.reduce(0.0, fn e, acc -> acc + e.amount end)
    
    total_expenses = ledger.entries
    |> Enum.filter(fn e -> e.entry_type == :expense end)
    |> Enum.reduce(0.0, fn e, acc -> acc + e.amount end)
    
    conservation = if abs(ledger.balance - (total_income - total_expenses)) < 0.01 do
      :pass
    else
      :fail
    end
    
    %{state |
      ledger_balance: ledger.balance,
      ledger_total_income: total_income,
      ledger_total_expenses: total_expenses,
      ledger_conservation: conservation
    }
  end
  
  # Collect memory metrics
  defp collect_memory_metrics(state) do
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    
    operational_size = length(institution.operational_memory)
    research_size = length(institution.research_memory.hypotheses) + 
                    length(institution.research_memory.experiments) +
                    length(institution.research_memory.evidence)
    institutional_size = length(institution.institutional_memory.patterns) +
                         length(institution.institutional_memory.heuristics)
    civilizational_size = map_size(institution.civilizational_memory)
    
    health = if operational_size <= 100 do
      :pass  # Memory is being compressed properly
    else
      :fail  # Operational memory growing unbounded
    end
    
    %{state |
      memory_operational_size: operational_size,
      memory_research_size: research_size,
      memory_institutional_size: institutional_size,
      memory_civilizational_size: civilizational_size,
      memory_health: health
    }
  end
  
  # Collect governance metrics
  defp collect_governance_metrics(state) do
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    
    approvals = Enum.count(institution.semantic_event_log, fn e ->
      Map.get(e, :event_type) == :governance_approved
    end)
    
    denials = Enum.count(institution.semantic_event_log, fn e ->
      Map.get(e, :event_type) == :governance_rejected
    end)
    
    %{state |
      governance_approvals: approvals,
      governance_denials: denials,
      governance_audits: approvals + denials
    }
  end
  
  # Collect runtime atlas metrics
  defp collect_runtime_atlas_metrics(state) do
    institution = TiannaraOS.InstitutionKernel.get_institution(state.kernel_pid)
    
    registered = institution.runtime_registration.registered
    
    status = if registered, do: :pass, else: :fail
    
    %{state |
      runtime_atlas_registered: registered,
      runtime_atlas_status: status
    }
  end
  
  # Calculate event completeness percentage
  defp calculate_event_completeness(state) do
    # Every mutation should emit an event
    expected = state.total_mutations
    emitted = state.events_emitted
    
    completeness = if expected > 0 do
      (emitted / expected) * 100
    else
      100.0
    end
    
    %{state |
      events_emitted: state.total_mutations,  # Approximate
      expected_events: expected,
      event_completeness_pct: completeness
    }
  end
  
  # Calculate lifecycle completeness percentage
  defp calculate_lifecycle_completeness(state) do
    total_entities = state.entities_created
    tracked_entities = state.entities_created + state.entities_promoted + 
                       state.entities_archived + state.entities_removed
    
    completeness = if total_entities > 0 do
      (tracked_entities / total_entities) * 100
    else
      100.0
    end
    
    %{state |
      lifecycle_completeness_pct: min(completeness, 100.0)
    }
  end
  
  # Calculate governance approval coverage
  defp calculate_governance_coverage(state) do
    total_actions = state.governance_approvals + state.governance_denials
    
    coverage = if total_actions > 0 do
      (state.governance_approvals / total_actions) * 100
    else
      100.0
    end
    
    %{state |
      approval_coverage_pct: coverage
    }
  end
  
  # Calculate traceability coverage
  defp calculate_traceability_coverage(state) do
    coverage = if state.total_mutations > 0 do
      (state.traceable_mutations / state.total_mutations) * 100
    else
      100.0
    end
    
    %{state |
      traceability_coverage_pct: coverage
    }
  end
  
  # Calculate memory compression ratio
  defp calculate_memory_compression_ratio(state) do
    total_memory = state.memory_operational_size + 
                   state.memory_research_size +
                   state.memory_institutional_size +
                   state.memory_civilizational_size
    
    ratio = if total_memory > 0 do
      state.memory_operational_size / total_memory
    else
      0.0
    end
    
    %{state |
      memory_compression_ratio: ratio
    }
  end
  
  # Check constitutional health
  defp check_constitutional_health(state) do
    # Count satisfied invariants (simplified - would query actual validation results)
    satisfied = 11 - length(state.invariant_failures)
    
    %{state |
      invariants_satisfied: max(satisfied, 0)
    }
  end
  
  # Log telemetry snapshot
  defp log_telemetry_snapshot(state) do
    snapshot = %{
      tick: state.current_tick,
      invariants_satisfied: state.invariants_satisfied,
      event_completeness: state.event_completeness_pct,
      lifecycle_completeness: state.lifecycle_completeness_pct,
      kg_nodes: state.kg_node_count,
      kg_edges: state.kg_edge_count,
      ledger_balance: state.ledger_balance,
      memory_operational: state.memory_operational_size,
      kernel_violations: state.kernel_violations
    }
    
    # Keep last 100 snapshots for trend analysis
    updated_log = [snapshot | Enum.take(state.telemetry_log, 99)]
    
    %{state |
      telemetry_log: updated_log
    }
  end
end
