defmodule Tiannara.OPC.RealityCompiler do
  @moduledoc """
  Observer Reality Compiler (OPC) - Converts observed system histories into executable physics constraints (rules).
  
  ## Architecture
  
  The OPC system transforms event histories into executable physics rules through several stages:
  
  1. Event histories (NATS streams, execution traces, divergence events) are collected
  2. Histories are segmented into causal chains
  3. Invariants are inferred from the causal chains
  4. Stable recurrence patterns are detected
  5. Patterns are compiled into "physics rules"
  6. Rules are injected into MSCL + OLEF enforcement layers
  """

  alias Tiannara.OPC.RealityCompiler.{ContradictionResolver, GPUExecutor, MultiHistoryRuntime}

  defstruct [
    :history_collector,
    :causal_segmenter,
    :invariant_detector,
    :pattern_engine,
    :rule_compiler,
    :rule_store,
    :injection_engine,
    :contradiction_resolver,
    :gpu_executor,
    :multi_history_runtime
  ]

  def start_opc_system do
    # Initialize all OPC components
    reality_compiler = %__MODULE__{
      history_collector: nil,
      causal_segmenter: nil,
      invariant_detector: nil,
      pattern_engine: nil,
      rule_compiler: nil,
      rule_store: nil,
      injection_engine: nil,
      contradiction_resolver: ContradictionResolver,
      gpu_executor: GPUExecutor.init(),
      multi_history_runtime: MultiHistoryRuntime.init()
    }

    # Start the system components
    children = [
      {Tiannara.OPC.RuleStore, []},
      {Tiannara.MSCL.ConstraintEngine, []},
      {Tiannara.OLEF.FieldSupervisor, []}
    ]

    opts = [strategy: :one_for_one, name: Tiannara.OPC.RealityCompiler.SystemSupervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Ingests an event into the OPC system for analysis and rule generation.
  """
  def ingest_event(event) do
    Tiannara.OPC.RealityCompiler.HistoryCollector.collect(event)
  end

  @doc """
  Retrieves all currently compiled physics rules.
  """
  def get_compiled_rules do
    Tiannara.OPC.RuleStore.all()
  end

  @doc """
  Processes a batch of events through the full OPC pipeline with GPU acceleration.
  """
  def process_events_with_gpu(events) do
    # 1. Collect events
    normalized_events = normalize_events(events)
    
    # 2. Segment into causal chains
    chains = Tiannara.OPC.RealityCompiler.CausalSegmenter.segment(normalized_events)
    
    # 3. Detect invariants
    invariants = Tiannara.OPC.RealityCompiler.InvariantDetector.detect(chains)
    
    # 4. Extract patterns
    patterns = Tiannara.OPC.RealityCompiler.PatternEngine.extract(chains)
    
    # 5. Compile rules
    rules = Tiannara.OPC.RealityCompiler.RuleCompiler.compile(patterns)
    
    # 6. Resolve contradictions
    resolved_rules = ContradictionResolver.resolve_conflicts(rules)
    
    # 7. Execute on GPU for parallel processing
    gpu_executor = GPUExecutor.init()
    gpu_executor_with_shaders = GPUExecutor.compile_rules_to_shaders(gpu_executor, resolved_rules)
    {:ok, gpu_results} = GPUExecutor.execute_on_gpu(gpu_executor_with_shaders)
    
    # 8. Inject rules into runtime
    Tiannara.OPC.RealityCompiler.InjectionEngine.inject(resolved_rules)
    
    %{rules: resolved_rules, gpu_results: gpu_results, status: :success}
  end

  @doc """
  Creates a new timeline fork for exploring alternative physics evolutions.
  """
  def create_timeline_fork(fork_id, parent_timeline \\ "main") do
    runtime = MultiHistoryRuntime.init()
    MultiHistoryRuntime.fork_timeline(runtime, fork_id, parent_timeline)
  end

  @doc """
  Executes events across multiple timeline branches.
  """
  def execute_across_timelines(multi_runtime, events) do
    Enum.reduce(events, multi_runtime, fn event, acc ->
      MultiHistoryRuntime.execute_across_timelines(acc, event)
    end)
  end

  @doc """
  Merges a timeline branch back into its parent.
  """
  def merge_timeline(multi_runtime, child_timeline_id, strategy \\ :prefer_newer) do
    MultiHistoryRuntime.merge_timeline(multi_runtime, child_timeline_id, strategy)
  end

  @doc """
  Evaluates differences between timeline branches.
  """
  def evaluate_timeline_differences(multi_runtime) do
    MultiHistoryRuntime.evaluate_timeline_differences(multi_runtime)
  end

  @doc """
  Gets statistics about the multi-history runtime.
  """
  def get_multi_history_stats(multi_runtime) do
    MultiHistoryRuntime.get_statistics(multi_runtime)
  end

  defp normalize_events(events) when is_list(events) do
    Enum.map(events, fn event ->
      %{
        id: Map.get(event, :id) || generate_id(),
        type: Map.get(event, :type, "unknown"),
        payload: Map.get(event, :payload, %{}),
        timestamp: Map.get(event, :timestamp) || System.system_time(:millisecond)
      }
    end)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16()
  end

  # Define child_spec for supervisor compatibility (even though this is not a GenServer)
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :temporary,  # Don't restart this worker automatically
      shutdown: 500
    }
  end

  # Placeholder start_link for child_spec compatibility
  def start_link(_opts) do
    # This is just to satisfy the child_spec, as this module is not actually a GenServer
    # The actual system is started via start_opc_system/0
    {:ok, self()}
  end
end
