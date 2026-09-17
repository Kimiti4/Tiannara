defmodule Tiannara.RRG do
  @moduledoc """
  Rate-limiting Ontological Graph (RRG) - Top-level module for the epistemic firewall
  and bandwidth allocator for reality claims.

  RRG sits above MSCL + OLEF as the civilization-level control plane for cognition,
  ontology, and distributed reality evolution.
  """

  alias Tiannara.RRG.{Graph, Node, Edge, ExposureTracker, RateLimiter, CoherenceCalculator, CTNAnomalyDetector}

  defstruct [
    :graph,
    :rate_limiter,
    :exposure_tracker,
    :coherence_calculator,
    :anomaly_detector
  ]

  def start_link(opts \\ []) do
    # Start the RRG system as a GenServer
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    initial_graph = Graph.new()
    rate_limiter = RateLimiter.new()
    exposure_tracker = ExposureTracker.new("global")
    coherence_calculator = CoherenceCalculator.new(initial_graph)
    anomaly_detector = CTNAnomalyDetector.new()

    state = %__MODULE__{
      graph: initial_graph,
      rate_limiter: rate_limiter,
      exposure_tracker: exposure_tracker,
      coherence_calculator: coherence_calculator,
      anomaly_detector: anomaly_detector
    }

    {:ok, state}
  end

  # Client API

  def add_node(node) do
    GenServer.call(__MODULE__, {:add_node, node})
  end

  def add_edge(edge) do
    GenServer.call(__MODULE__, {:add_edge, edge})
  end

  def check_ontology_delta(ontology_delta) do
    GenServer.call(__MODULE__, {:check_ontology_delta, ontology_delta})
  end

  def get_graph_stats do
    GenServer.call(__MODULE__, :get_graph_stats)
  end

  def get_coherence_score do
    GenServer.call(__MODULE__, :get_coherence_score)
  end

  def detect_anomalies do
    GenServer.call(__MODULE__, :detect_anomalies)
  end

  def update_cognitive_capacity(new_capacity) when is_number(new_capacity) do
    GenServer.cast(__MODULE__, {:update_cognitive_capacity, new_capacity})
  end

  def update_kernel_stability(new_stability) when is_number(new_stability) do
    GenServer.cast(__MODULE__, {:update_kernel_stability, new_stability})
  end

  def update_system_coherence(new_coherence) when is_number(new_coherence) do
    GenServer.cast(__MODULE__, {:update_system_coherence, new_coherence})
  end

  # Server callbacks

  def handle_call({:add_node, node}, _from, state) do
    new_graph = Graph.add_node(state.graph, node)
    new_state = %{state | graph: new_graph}
    
    {:reply, :ok, new_state}
  end

  def handle_call({:add_edge, edge}, _from, state) do
    new_graph = Graph.add_edge(state.graph, edge)
    new_state = %{state | graph: new_graph}
    
    {:reply, :ok, new_state}
  end

  def handle_call({:check_ontology_delta, ontology_delta}, _from, state) do
    # Get current state for rate limiting check
    rrg_state = %{
      exposure_entropy: state.exposure_tracker.exposure_entropy,
      coherence: CoherenceCalculator.calculate_coherence(state.coherence_calculator),
      cognitive_capacity: state.rate_limiter.cognitive_capacity,
      kernel_stability: state.rate_limiter.kernel_stability
    }
    
    allowed = RateLimiter.allow?(ontology_delta, rrg_state)
    
    # Update exposure tracker if allowed
    new_exposure_tracker = 
      if allowed do
        ExposureTracker.increment_anomaly_saturation(state.exposure_tracker, 0.01)
      else
        state.exposure_tracker
      end
    
    new_state = %{state | exposure_tracker: new_exposure_tracker}
    
    {:reply, %{allowed: allowed, state: rrg_state}, new_state}
  end

  def handle_call(:get_graph_stats, _from, state) do
    stats = Graph.size(state.graph)
    {:reply, stats, state}
  end

  def handle_call(:get_coherence_score, _from, state) do
    score = CoherenceCalculator.calculate_coherence(state.coherence_calculator)
    {:reply, score, state}
  end

  def handle_call(:detect_anomalies, _from, state) do
    anomalies = CTNAnomalyDetector.detect_anomalies(state.graph)
    {:reply, anomalies, state}
  end

  def handle_cast({:update_cognitive_capacity, new_capacity}, state) do
    new_rate_limiter = RateLimiter.update_cognitive_capacity(state.rate_limiter, new_capacity)
    new_state = %{state | rate_limiter: new_rate_limiter}
    
    {:noreply, new_state}
  end

  def handle_cast({:update_kernel_stability, new_stability}, state) do
    new_rate_limiter = RateLimiter.update_kernel_stability(state.rate_limiter, new_stability)
    new_state = %{state | rate_limiter: new_rate_limiter}
    
    {:noreply, new_state}
  end

  def handle_cast({:update_system_coherence, new_coherence}, state) do
    new_rate_limiter = RateLimiter.update_system_coherence(state.rate_limiter, new_coherence)
    updated_coherence_calc = CoherenceCalculator.update_graph(state.coherence_calculator, state.graph)
    
    new_state = %{
      state | 
      rate_limiter: new_rate_limiter,
      coherence_calculator: updated_coherence_calc
    }
    
    {:noreply, new_state}
  end

  # Additional utility functions

  def get_exposure_stats do
    GenServer.call(__MODULE__, :get_exposure_stats)
  end

  def handle_call(:get_exposure_stats, _from, state) do
    stats = ExposureTracker.get_exposure_stats(state.exposure_tracker)
    {:reply, stats, state}
  end

  def get_anomaly_report do
    GenServer.call(__MODULE__, :get_anomaly_report)
  end

  def handle_call(:get_anomaly_report, _from, state) do
    report = CTNAnomalyDetector.get_anomaly_report(state.graph)
    {:reply, report, state}
  end

  def get_detailed_metrics do
    GenServer.call(__MODULE__, :get_detailed_metrics)
  end

  def handle_call(:get_detailed_metrics, _from, state) do
    coherence_metrics = CoherenceCalculator.get_detailed_metrics(state.coherence_calculator)
    exposure_stats = ExposureTracker.get_exposure_stats(state.exposure_tracker)
    anomaly_report = CTNAnomalyDetector.get_anomaly_report(state.graph)
    
    metrics = %{
      coherence: coherence_metrics,
      exposure: exposure_stats,
      anomalies: anomaly_report,
      graph_size: Graph.size(state.graph)
    }
    
    {:reply, metrics, state}
  end

  # Define child_spec for supervision
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
