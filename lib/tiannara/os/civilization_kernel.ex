defmodule TiannaraOS.CivilizationKernel do
  @moduledoc """
  CivilizationKernel - Constitutional kernel for civilization-wide coordination and evolution.

  Capability 13.4 - Civilizational Adaptation

  This kernel operates at the highest level of the Tiannara hierarchy, coordinating
  evolution across all Research Institutions while preserving institutional autonomy,
  diversity, and specialization.

  ## Constitutional Role

  The Civilization Kernel asks "How should we evolve together?" and determines optimal
  evolution paths through evidence-based coordination, NOT centralized control.

  It optimizes:
  - Specialization (institutions developing unique expertise)
  - Collaboration (cross-institution knowledge sharing)
  - Diversity (maintaining varied approaches)
  - Capability distribution (balanced strengths)
  - Resilience (system robustness)
  - Research balance (resource allocation across domains)

  ## Constitutional Pipeline

  ```
  Observe Civilization
      ↓
  Collect Institutional Improvements
      ↓
  Compare Results Across Institutions
      ↓
  Estimate Ecosystem Effects
      ↓
  Recommend Adoption Paths
      ↓
  Coordinate Rollout
      ↓
  Evaluate Outcome
      ↓
  CivilizationAdaptationResult
  ```

  ## Constitutional Invariants

  1. No institution forced to adopt (voluntary adoption)
  2. Evidence determines recommendations (data-driven)
  3. Diversity preserved (avoid monoculture)
  4. Specialization preserved (encourage unique expertise)
  5. Transferability evaluated (can improvements cross boundaries?)
  6. Reversibility maintained (all adaptations reversible)
  7. Complete traceability (full audit trail)

  ## Usage

      # Start civilization kernel
      {:ok, pid} = TiannaraOS.CivilizationKernel.start_link(:tiannara_civilization, init_state)

      # Evaluate civilization-wide adaptation
      {:ok, result} = TiannaraOS.CivilizationKernel.evaluate_civilization_adaptation(
        pid,
        %{
          evaluation_scope: :all_institutions,
          improvement_category: :validation_workflow
        }
      )

      # Access coordination recommendations
      result.coordination_strategy
      result.recommendations
      result.target_institutions
  """

  use GenServer
  require Logger

  alias TiannaraOS.CivilizationAdaptationResult
  alias TiannaraOS.CivilizationAdaptationPipeline

  # ==================== State ====================

  @type state :: %{
    civilization_id: atom(),
    institutions: [atom()],
    current_tick: integer(),
    adaptation_history: [map()]
  }

  # ==================== API ====================

  @doc """
  Start CivilizationKernel for a given civilization.

  ## Parameters

  - `civilization_id`: atom() - unique civilization identifier
  - `init_state`: map() - initial civilization state

  ## Returns

  `{:ok, pid()}` on success

  ## Examples

      iex> {:ok, pid} = TiannaraOS.CivilizationKernel.start_link(
      ...>   :tiannara_civilization,
      ...>   %{institutions: [:quantum_lab, :bio_research, :physics_world]}
      ...> )
  """
  @spec start_link(atom(), map()) :: {:ok, pid()} | {:error, term()}
  def start_link(civilization_id, init_state) do
    Logger.info("[CivilizationKernel] Starting kernel for civilization: #{inspect(civilization_id)}")

    GenServer.start_link(__MODULE__, %{
      civilization_id: civilization_id,
      institutions: Map.get(init_state, :institutions, []),
      current_tick: 0,
      adaptation_history: []
    })
  end

  # Supervisor compatibility - allows starting with just a list of args
  def start_link(args) when is_list(args) do
    [civilization_id, init_state] = args
    start_link(civilization_id, init_state)
  end

  @doc """
  Evaluate civilization-wide adaptation.

  Capability 13.4 - Civilizational Adaptation

  The civilization asks "How should we evolve together?" and coordinates
  evolution across all institutions while preserving diversity.

  ## Constitutional Pipeline

  ```
  Observe Civilization
      ↓
  Collect Institutional Improvements
      ↓
  Compare Results Across Institutions
      ↓
  Estimate Ecosystem Effects
      ↓
  Recommend Adoption Paths
      ↓
  Coordinate Rollout
      ↓
  Evaluate Outcome
  ```

  ## Parameters

  - `kernel_pid`: pid() | atom() - Civilization kernel process ID or name
  - `opts`: map() with keys:
    - `:evaluation_scope` - atom() :all_institutions or specific scope
    - `:improvement_category` - atom() category to evaluate
    - `:institutions_evaluated` - [atom()] list of institutions to include

  ## Returns

  {:ok, CivilizationAdaptationResult.t()} | {:error, String.t()}

  ## Examples

      iex> opts = %{
      ...>   evaluation_scope: :all_institutions,
      ...>   improvement_category: :validation_workflow,
      ...>   institutions_evaluated: [:quantum_lab, :bio_research]
      ...> }
      iex> {:ok, result} = TiannaraOS.CivilizationKernel.evaluate_civilization_adaptation(
      ...>   :tiannara_civilization,
      ...>   opts
      ...> )
  """
  @spec evaluate_civilization_adaptation(pid() | atom(), map()) ::
          {:ok, CivilizationAdaptationResult.t()} | {:error, String.t()}
  def evaluate_civilization_adaptation(kernel_pid, opts) do
    GenServer.call(via_pid(kernel_pid), {:evaluate_civilization_adaptation, opts})
  end

  @doc """
  Get civilization state summary.

  Returns overview of all institutions, their current adaptations, and
  civilization-wide metrics.

  ## Parameters
  - `kernel_pid`: pid() | atom()

  ## Returns
  {:ok, civilization_summary}
  """
  @spec get_civilization_summary(pid() | atom()) :: {:ok, map()} | {:error, String.t()}
  def get_civilization_summary(kernel_pid) do
    GenServer.call(via_pid(kernel_pid), :get_civilization_summary)
  end

  # ==================== Internal Helpers ====================

  defp via_pid(pid) when is_pid(pid), do: pid
  defp via_pid(name) when is_atom(name), do: {:via, Registry, {TiannaraOS.Registry, name}}

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(state) do
    Logger.info("[CivilizationKernel] Initialized for civilization: #{inspect(state.civilization_id)}")
    Logger.info("[CivilizationKernel] Managing #{length(state.institutions)} institutions")

    {:ok, state}
  end

  @impl true
  def handle_call({:evaluate_civilization_adaptation, opts}, _from, state) do
    Logger.info("[CivilizationKernel] Evaluating civilization adaptation for #{inspect(state.civilization_id)}")

    # Create CivilizationAdaptationResult canonical transaction
    result = CivilizationAdaptationResult.new(state.civilization_id, opts)

    # Add lifecycle event
    result = CivilizationAdaptationResult.add_lifecycle_event(result, :evaluation_initiated, %{
      civilization_id: state.civilization_id,
      evaluation_scope: opts[:evaluation_scope],
      institutions_count: length(state.institutions)
    })

    # Add semantic event
    result = CivilizationAdaptationResult.add_semantic_event(result, :civilization_evaluation_started, %{
      civilization_id: state.civilization_id,
      scope: opts[:evaluation_scope] || :all_institutions
    })

    # Record institutions being evaluated
    result = %{result | institutions_evaluated: state.institutions}

    # REAL PIPELINE: Execute cross-institution coordination analysis
    result = CivilizationAdaptationPipeline.execute_pipeline(result, state.civilization_id, opts)

    # Extract strategy for logging
    coordination_strategy = result.coordination_strategy || :none

    # Validate constitutional compliance
    {result_with_compliance, violations} = CivilizationAdaptationResult.validate_constitutional_compliance(result)

    if length(violations) > 0 do
      Logger.warning("[CivilizationKernel] Civilization adaptation has constitutional violations: #{inspect(violations)}")
    end

    # Mark as completed
    result_with_compliance = CivilizationAdaptationResult.mark_complete(result_with_compliance, :completed)

    # Add to adaptation history
    updated_state = %{state |
      adaptation_history: state.adaptation_history ++ [%{
        result_id: result_with_compliance.id,
        timestamp: DateTime.utc_now(),
        strategy: result_with_compliance.coordination_strategy
      }]
    }

    Logger.info("[CivilizationKernel] Civilization adaptation evaluation completed with strategy: #{inspect(coordination_strategy)}")

    {:reply, {:ok, result_with_compliance}, updated_state}
  end

  @impl true
  def handle_call(:get_civilization_summary, _from, state) do
    summary = %{
      civilization_id: state.civilization_id,
      total_institutions: length(state.institutions),
      institutions: state.institutions,
      total_adaptations_evaluated: length(state.adaptation_history),
      recent_adaptations: Enum.take(state.adaptation_history, -5),
      current_tick: state.current_tick
    }

    {:reply, {:ok, summary}, state}
  end

  # ==================== Private Functions ====================

  defp simulate_institutional_improvements(institutions, category) do
    # Placeholder: In production, this would query each institution's MethodEvolutionResult
    # and InstitutionAdaptationResult records
    Enum.map(institutions, fn inst_id ->
      %{
        institution_id: inst_id,
        improvement_id: :"improved_#{category || :workflow}",
        improvement_category: category || :general,
        success_metrics: %{
          efficiency_gain: :rand.uniform() * 0.3,
          quality_improvement: :rand.uniform() * 0.25
        },
        adoption_status: [:adopted, :rejected, :piloting] |> Enum.random(),
        evidence_quality: 0.7 + (:rand.uniform() * 0.25)
      }
    end)
  end

  defp identify_successful_patterns(improvements) do
    # Identify common factors among successful improvements
    adopted = Enum.filter(improvements, fn imp -> imp.adoption_status == :adopted end)

    if length(adopted) > 0 do
      [%{
        pattern_name: "High-Evidence Adoption",
        description: "Improvements with strong evidence (>0.8) tend to succeed",
        observed_in: Enum.map(adopted, fn imp -> imp.institution_id end),
        success_rate: length(adopted) / length(improvements),
        key_factors: ["Strong simulation results", "Successful pilot execution", "Clear governance approval"]
      }]
    else
      []
    end
  end

  defp perform_comparative_analysis(improvements) do
    # Compare performance across institutions
    efficiencies = Enum.map(improvements, fn imp ->
      imp.success_metrics[:efficiency_gain] || 0
    end)

    avg_efficiency = if length(efficiencies) > 0 do
      Enum.sum(efficiencies) / length(efficiencies)
    else
      0
    end

    variance = if length(efficiencies) > 1 do
      mean = avg_efficiency
      sum_sq_diff = Enum.sum(Enum.map(efficiencies, fn e -> :math.pow(e - mean, 2) end))
      :math.sqrt(sum_sq_diff / length(efficiencies))
    else
      0
    end

    %{
      performance_variance: variance,
      best_performers: improvements
        |> Enum.sort_by(fn imp -> imp.success_metrics[:efficiency_gain] || 0 end, :desc)
        |> Enum.take(3)
        |> Enum.map(fn imp -> imp.institution_id end),
      contextual_factors: [],
      transferability_score: if(variance < 0.1, do: 0.9, else: 0.6)
    }
  end

  defp assess_transferability(improvements) do
    # Determine which improvements can transfer across institutions
    high_evidence = Enum.filter(improvements, fn imp -> imp.evidence_quality >= 0.85 end)

    %{
      highly_transferable: Enum.map(high_evidence, fn imp -> imp.improvement_id end),
      context_dependent: [],
      institution_specific: [],
      transfer_barriers: []
    }
  end

  defp assess_diversity_impact(improvements) do
    # Assess whether adoption would increase or decrease diversity
    unique_categories = improvements
      |> Enum.map(fn imp -> imp.improvement_category end)
      |> Enum.uniq()

    diversity_change = if length(unique_categories) > 2 do
      :increase
    else
      :neutral
    end

    %{
      diversity_change: diversity_change,
      risk_of_monoculture: :low,
      diverse_approaches_preserved: true,
      recommendation: "Current diversity levels are healthy, continue encouraging varied approaches"
    }
  end

  defp analyze_ecosystem_effects(improvements, institutions) do
    # Analyze system-level impacts
    adopted_count = Enum.count(improvements, fn imp -> imp.adoption_status == :adopted end)
    adoption_rate = adopted_count / max(length(improvements), 1)

    %{
      system_resilience: if(adoption_rate > 0.5, do: :improved, else: :unchanged),
      capability_distribution: %{},
      bottleneck_risks: [],
      emergent_properties: []
    }
  end

  defp determine_coordination_strategy(improvements, diversity_impact) do
    # Determine optimal coordination approach
    adopted_count = Enum.count(improvements, fn imp -> imp.adoption_status == :adopted end)
    adoption_rate = adopted_count / max(length(improvements), 1)

    cond do
      adoption_rate > 0.8 ->
        %{
          strategy: :universal_adoption,
          target_institutions: [],
          rationale: "High adoption rate suggests universal benefit",
          expected_benefits: ["Standardized best practices", "Reduced variation"],
          risks: ["Potential loss of diversity"]
        }

      adoption_rate > 0.4 ->
        %{
          strategy: :selective_adoption,
          target_institutions: improvements
            |> Enum.filter(fn imp -> imp.adoption_status == :adopted end)
            |> Enum.map(fn imp -> imp.institution_id end),
          rationale: "Moderate adoption suggests domain-specific benefits",
          expected_benefits: ["Targeted improvements", "Preserved diversity"],
          risks: ["Coordination complexity"]
        }

      true ->
        %{
          strategy: :preserve_diversity,
          target_institutions: [],
          rationale: "Low adoption suggests maintaining current diversity is optimal",
          expected_benefits: ["Institutional autonomy", "Experimental freedom"],
          risks: ["Slower standardization"]
        }
    end
  end
end
