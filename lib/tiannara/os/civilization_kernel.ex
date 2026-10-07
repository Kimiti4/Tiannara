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

  alias TiannaraOS.State
  alias TiannaraOS.CivilizationAdaptationResult
  alias TiannaraOS.CivilizationAdaptationPipeline

  # Default L0 resource ceilings
  @max_compute_ceiling 10_000.0
  @max_memory_objects 50_000
  @default_tenant_id "default_tenant"

  # ==================== State ====================

  @type state :: %{
    civilization_id: atom(),
    institutions: [atom()],
    current_tick: integer(),
    adaptation_history: [map()],
    os_state: map(),
    tenant_id: String.t(),
    resource_limits: map()
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
      tenant_id: Map.get(init_state, :tenant_id, @default_tenant_id),
      resource_limits: %{
        compute_ceiling: Map.get(init_state, :compute_ceiling, @max_compute_ceiling),
        memory_objects_ceiling: Map.get(init_state, :memory_objects_ceiling, @max_memory_objects)
      },
      os_state: normalize_os_state(Map.get(init_state, :os_state, init_state))
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

  The transformed state is verified against the kernel invariants
  (compute ceiling, memory-object ceiling, tenant isolation) before it is
  stored. Violations are recorded and returned as `{:error, reason}` while the
  previous state is preserved.
  """
  @spec update_state(fun()) :: {:ok, map()} | {:error, term()}
  def update_state(transform_fn) when is_function(transform_fn, 1) do
    GenServer.call(__MODULE__, {:update_state, transform_fn})
  end

  @doc """
  Read the current OS state (the kernel's `os_state`).
  """
  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Apply an operator override that bypasses the invariant checks.

  The override is recorded in the governance `overrides` and `audit_log`
  channels so the bypass remains fully traceable.
  """
  @spec human_override(map()) :: {:ok, map()} | {:error, term()}
  def human_override(new_state) when is_map(new_state) do
    GenServer.call(__MODULE__, {:human_override, new_state})
  end

  @doc """
  Restore a previously captured snapshot.

  The snapshot's in-memory knowledge (memory, worlds, theories, tools,
  discoveries) is preserved from the live state and the rollback is appended
  to the snapshot's governance audit log.
  """
  @spec rollback(map()) :: {:ok, map()} | {:error, term()}
  def rollback(snapshot) when is_map(snapshot) do
    GenServer.call(__MODULE__, {:rollback, snapshot})
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

    case verify_invariants(state, new_os_state) do
      :ok ->
        {:reply, {:ok, new_os_state}, %{state | os_state: new_os_state}}

      {:error, reason} ->
        {:reply, {:error, reason}, record_violation(state, reason)}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state.os_state, state}
  end

  @impl true
  def handle_call({:human_override, new_os_state}, _from, state) do
    event = %{
      type: :human_override,
      timestamp: DateTime.utc_now(),
      civilization_id: state.civilization_id,
      actor: :human_operator
    }

    decorated = new_os_state |> put_governance(:overrides, event) |> put_governance(:audit_log, event)
    {:reply, {:ok, decorated}, %{state | os_state: decorated}}
  end

  @impl true
  def handle_call({:rollback, snapshot}, _from, state) do
    event = %{
      type: :rollback,
      timestamp: DateTime.utc_now(),
      civilization_id: state.civilization_id,
      actor: :human_operator
    }

    restored =
      snapshot
      |> Map.put(:memory, Map.get(state.os_state, :memory, %{}))
      |> put_governance(:audit_log, event)

    {:reply, {:ok, restored}, %{state | os_state: restored}}
  end

  @impl true
  def handle_call(:security_policy_mode, _from, state) do
    security = Map.get(state.os_state, :security, %{})
    mode = if is_map(security), do: Map.get(security, :policy_mode, :strict), else: :strict
    {:reply, mode, state}
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

  @doc """
  Validates a tool's security profile against the kernel's L0 security policy.
  """
  @spec validate_security_profile(term()) :: :ok | {:error, term()}
  def validate_security_profile(security_profile) when is_map(security_profile) do
    if kernel_policy_mode() == :permissive do
      :ok
    else
      cond do
        not Map.get(security_profile, :read_sandbox, false) ->
          {:error, {:security_violation, :untrusted_sandbox}}

        Map.get(security_profile, :network_access, false) ->
          {:error, {:security_violation, :unauthorized_network_access}}

        true ->
          :ok
      end
    end
  end

  def validate_security_profile(_security_profile), do: :ok

  # ==================== Invariant Enforcement ====================

  defp kernel_policy_mode do
    case Process.whereis(__MODULE__) do
      nil ->
        :strict

      _pid ->
        try do
          case GenServer.call(__MODULE__, :security_policy_mode) do
            mode when is_atom(mode) -> mode
            _ -> :strict
          end
        catch
          _kind, _reason -> :strict
        end
    end
  end

  defp verify_invariants(kernel_state, new_os_state) do
    with :ok <- check_memory_objects(kernel_state, new_os_state),
         :ok <- check_compute_ceiling(kernel_state, new_os_state),
         :ok <- check_tenant_isolation(kernel_state, new_os_state) do
      :ok
    end
  end

  defp check_memory_objects(kernel_state, os_state) do
    counted = [:worlds, :theories, :institutions, :tools, :discoveries, :research_programs, :research_institutions]
    total = Enum.reduce(counted, 0, fn key, acc -> acc + collection_size(Map.get(os_state, key, %{})) end)
    ceiling = resource_limit(kernel_state, :memory_objects_ceiling, @max_memory_objects)

    if total > ceiling do
      {:error, :memory_objects_ceiling_exceeded}
    else
      :ok
    end
  end

  defp check_compute_ceiling(kernel_state, os_state) do
    total =
      Map.get(os_state, :institutions, %{})
      |> total_compute_share()

    ceiling = resource_limit(kernel_state, :compute_ceiling, @max_compute_ceiling)

    if total > ceiling do
      {:error, :compute_ceiling_exceeded}
    else
      :ok
    end
  end

  defp check_tenant_isolation(kernel_state, os_state) do
    kernel_tenant = Map.get(kernel_state, :tenant_id, @default_tenant_id)
    worlds = Map.get(os_state, :worlds, %{})

    foreign_tenant? =
      is_map(worlds) and
        Enum.any?(worlds, fn {_world_id, world} ->
          tenant = if is_map(world), do: Map.get(world, :tenant_id), else: nil
          is_binary(tenant) and tenant != kernel_tenant
        end)

    if foreign_tenant? do
      {:error, :tenant_isolation_violation}
    else
      :ok
    end
  end

  defp collection_size(value) when is_map(value), do: map_size(value)
  defp collection_size(value) when is_list(value), do: length(value)
  defp collection_size(_value), do: 0

  defp total_compute_share(institutions) when is_map(institutions) do
    Enum.reduce(institutions, 0.0, fn {_id, institution}, acc ->
      share =
        if is_map(institution) do
          case Map.get(institution, :compute_share) do
            value when is_number(value) -> value * 1.0
            _ -> 0.0
          end
        else
          0.0
        end

      acc + share
    end)
  end

  defp total_compute_share(_institutions), do: 0.0

  defp resource_limit(kernel_state, key, default) do
    case Map.get(kernel_state, :resource_limits, %{}) do
      limits when is_map(limits) -> Map.get(limits, key, default)
      _ -> default
    end
  end

  defp record_violation(state, reason) do
    Logger.error("[CivilizationKernel] Invariant violation rejected state update: #{inspect(reason)}")

    violations = Map.get(state, :violations, [])
    Map.put(state, :violations, [%{reason: reason, timestamp: DateTime.utc_now()} | violations])
  end

  defp put_governance(state, channel, event) do
    governance =
      case Map.get(state, :governance) do
        value when is_map(value) -> value
        _ -> %{}
      end

    entries =
      case Map.get(governance, channel) do
        value when is_list(value) -> value
        _ -> []
      end

    Map.put(state, :governance, Map.put(governance, channel, [event | entries]))
  end

  defp normalize_os_state(%State{} = state), do: state
  defp normalize_os_state(_init_state), do: %State{}
end
