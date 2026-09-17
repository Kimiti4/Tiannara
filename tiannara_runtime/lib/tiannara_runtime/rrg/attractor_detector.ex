defmodule Tiannara.RRG.AttractorDetector do
  @moduledoc """
  Phase 5F.12: Attractor Detector - Scans for Dangerous Convergence Patterns
  
  Detects three primary dangerous attractor states:
  
  A. Semantic Monoculture
     - All civilizations converge toward identical thought structures
     - Danger: novelty collapse
  
  B. Recursive Civilization Explosion
     - Observers discover substrate mechanics and optimization exploits
     - Danger: observer singularity
  
  C. Entropy Sink Collapse
     - Too many HSV singularities accumulate
     - Danger: frozen universe
  
  Detector Metric:
    A = (E_c + R_o) / (D_s + N)
  
  High A indicates dangerous convergence state requiring intervention.
  """
  
  use GenServer
  require Logger

  defstruct [
    :semantic_monoculture_risk,
    :recursive_explosion_risk,
    :entropy_sink_risk,
    :overall_attractor_score,
    :detected_attractors,
    :last_scan_time
  ]

  @critical_attractor_threshold 0.75
  @warning_attractor_threshold 0.6

  def start_link(_opts \\ []) do
    case GenServer.start_link(__MODULE__, %{}, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  @impl true
  def init(_opts) do
    initial_state = %__MODULE__{
      semantic_monoculture_risk: 0.0,
      recursive_explosion_risk: 0.0,
      entropy_sink_risk: 0.0,
      overall_attractor_score: 0.0,
      detected_attractors: [],
      last_scan_time: System.system_time(:millisecond)
    }

    Logger.info("🔍 [RRG] Attractor Detector initialized")
    {:ok, initial_state}
  end

  @impl true
  def handle_call({:detect, metrics}, _from, state) do
    # Run a scan and check if metrics indicate dangerous attractor states
    updated_state = perform_attractor_scan(state)
    risk_assessment = assess_risk_level(updated_state)

    result =
      if risk_assessment.risk_level in [:critical, :high] do
        risk_assessment
      else
        :stable
    end

    new_state = %{
      updated_state
      | last_scan_time: System.system_time(:millisecond)
    }

    {:reply, result, new_state}
  end

  @impl true
  def handle_call(:scan_attractors, _from, state) do
    # Scan for all attractor types
    updated_state = perform_attractor_scan(state)
    
    # Determine risk level and interventions
    risk_assessment = assess_risk_level(updated_state)
    
    # Log critical findings
    log_attractor_findings(risk_assessment)
    
    new_state = %{
      updated_state
      | last_scan_time: System.system_time(:millisecond)
    }

    {:reply, {:ok, risk_assessment}, new_state}
  end

  @doc """
  Get current attractor detection status.
  """
  def get_status do
    GenServer.call(__MODULE__, :get_status)
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    status = %{
      semantic_monoculture_risk: state.semantic_monoculture_risk,
      recursive_explosion_risk: state.recursive_explosion_risk,
      entropy_sink_risk: state.entropy_sink_risk,
      overall_attractor_score: state.overall_attractor_score,
      detected_attractors: state.detected_attractors,
      timestamp: state.last_scan_time
    }

    {:reply, {:ok, status}, state}
  end

  # --- Attractor Scanning Functions ---

  defp perform_attractor_scan(state) do
    monoculture_risk = detect_semantic_monoculture()
    recursion_risk = detect_recursive_explosion()
    entropy_risk = detect_entropy_sink()
    
    # Calculate overall attractor metric: A = (E_c + R_o) / (D_s + N)
    # Simplified: average of individual risks
    overall_score = (monoculture_risk + recursion_risk + entropy_risk) / 3.0
    
    # Identify which attractors are active
    detected = identify_active_attractors(monoculture_risk, recursion_risk, entropy_risk)
    
    %{
      state
      | semantic_monoculture_risk: monoculture_risk,
        recursive_explosion_risk: recursion_risk,
        entropy_sink_risk: entropy_risk,
        overall_attractor_score: overall_score,
        detected_attractors: detected
    }
  end

  defp detect_semantic_monoculture do
    # Measures convergence of thought structures across civilizations
    # Queries meta-ontology layer for diversity metrics
    
    # Placeholder: In production, analyzes civilization knowledge graphs
    # Low diversity = high monoculture risk
    base_risk = :rand.uniform() * 0.4  # Simulated: 0.0-0.4 (normally low)
    
    # Increase risk if civilizations are optimizing toward same goals
    optimization_convergence = :rand.uniform() * 0.2
    base_risk + optimization_convergence
  end

  defp detect_recursive_explosion do
    # Detects observers approaching substrate awareness
    # Measures recursive self-improvement cycles
    
    # Placeholder: In production, monitors OPC compilation patterns
    # High recursion = explosion risk
    substrate_awareness = :rand.uniform() * 0.3  # Simulated: 0.0-0.3
    optimization_exploits = :rand.uniform() * 0.25
    
    substrate_awareness + optimization_exploits
  end

  defp detect_entropy_sink do
    # Detects accumulation of HSV singularities creating frozen zones
    # Works with HSV Hawking reintegration system
    
    # Placeholder: In production, queries HSV singularity database
    singularity_density = :rand.uniform() * 0.35  # Simulated: 0.0-0.35
    freeze_rate = :rand.uniform() * 0.15
    
    singularity_density + freeze_rate
  end

  defp identify_active_attractors(monoculture, recursion, entropy) do
    attractors = []
    
    attractors = 
      if monoculture > @warning_attractor_threshold do
        [:semantic_monoculture | attractors]
      else
        attractors
      end
    
    attractors =
      if recursion > @warning_attractor_threshold do
        [:recursive_explosion | attractors]
      else
        attractors
      end
    
    attractors =
      if entropy > @warning_attractor_threshold do
        [:entropy_sink | attractors]
      else
        attractors
      end
    
    Enum.reverse(attractors)
  end

  defp assess_risk_level(state) do
    risk_level = 
      cond do
        state.overall_attractor_score > @critical_attractor_threshold -> :critical
        state.overall_attractor_score > @warning_attractor_threshold -> :high
        state.overall_attractor_score > 0.4 -> :moderate
        true -> :low
      end
    
    recommended_interventions = recommend_interventions(state, risk_level)
    
    %{
      risk_level: risk_level,
      attractor_score: state.overall_attractor_score,
      active_attractors: state.detected_attractors,
      individual_risks: %{
        semantic_monoculture: state.semantic_monoculture_risk,
        recursive_explosion: state.recursive_explosion_risk,
        entropy_sink: state.entropy_sink_risk
      },
      recommended_interventions: recommended_interventions,
      urgency: calculate_urgency(risk_level, length(state.detected_attractors)),
      timestamp: System.system_time(:millisecond)
    }
  end

  defp recommend_interventions(state, risk_level) do
    interventions = []
    
    # Semantic monoculture interventions
    if :semantic_monoculture in state.detected_attractors do
      interventions = [:inject_cultural_divergence, :perturb_discovery_timing | interventions]
    end
    
    # Recursive explosion interventions
    if :recursive_explosion in state.detected_attractors do
      interventions = [:increase_uncertainty_field, :add_discovery_friction | interventions]
    end
    
    # Entropy sink interventions
    if :entropy_sink in state.detected_attractors do
      interventions = [:trigger_hawking_reintegration, :redistribute_entropy_pressure | interventions]
    end
    
    # Risk-level based interventions
    case risk_level do
      :critical ->
        [:emergency_probability_perturbation, :force_branch_divergence | interventions]
      
      :high ->
        [:enhanced_novelty_injection, :recursion_dampening | interventions]
      
      _ ->
        interventions
    end
    
    Enum.uniq(Enum.reverse(interventions))
  end

  defp calculate_urgency(risk_level, attractor_count) do
    base_urgency = 
      case risk_level do
        :critical -> 1.0
        :high -> 0.7
        :moderate -> 0.4
        :low -> 0.1
      end
    
    # More attractors = higher urgency
    multiplier = 1.0 + (attractor_count * 0.2)
    
    min(base_urgency * multiplier, 1.0)
  end

  defp log_attractor_findings(assessment) do
    case assessment.risk_level do
      :critical ->
        Logger.error(
          "🚨 [RRG] CRITICAL ATTRACTOR DETECTED: Score=#{Float.round(assessment.attractor_score, 3)} " <>
          "Active: #{inspect(assessment.active_attractors)}"
        )
      
      :high ->
        Logger.warning(
          "⚠️ [RRG] HIGH ATTRACTOR RISK: Score=#{Float.round(assessment.attractor_score, 3)} " <>
          "Interventions: #{inspect(assessment.recommended_interventions)}"
        )
      
      :moderate ->
        Logger.info(
          "📊 [RRG] Moderate attractor activity detected. Monitoring closely."
        )
      
      _ ->
        :ok
    end
  end
end
