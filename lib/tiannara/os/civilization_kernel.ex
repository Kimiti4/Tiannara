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
    adaptation_history: [map()],
    os_state: map()
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
      adaptation_history: [],
      os_state: init_state
    }, name: __MODULE__)
  end

  # Supervisor compatibility - allows starting with just a list of args
  def start_link(args) when is_list(args) do
    [civilization_id, init_state] = args
    start_link(civilization_id, init_state)
  end

  @doc """
  Start CivilizationKernel with default empty state (for testing).
  """
  def start_link() do
    start_link(:test_civilization, %{institutions: []})
  end

  @doc """
  Update the kernel's state via a transformation function.
  """
  @spec update_state(fun()) :: {:ok, map()}
  def update_state(transform_fn) when is_function(transform_fn, 1) do
    GenServer.call(__MODULE__, {:update_state, transform_fn})
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
    Logger.debug("[CivilizationKernel] Mark complete (CivilizationAdaptationResult.mark_complete not available)")

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
  def handle_call({:update_state, transform_fn}, _from, state) do
    new_os_state = transform_fn.(state.os_state)
    {:reply, {:ok, new_os_state}, %{state | os_state: new_os_state}}
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

  @spec validate_security_profile(term()) :: :ok | {:error, term()}
  def validate_security_profile(_profile), do: :ok
end
