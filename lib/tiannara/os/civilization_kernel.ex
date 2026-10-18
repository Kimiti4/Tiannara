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
  alias TiannaraOS.State

  # Civilizational resource ceilings (absolute totals across all institutions /
  # tools). Exceeding them is an unrecoverable governance violation and must
  # reject the update fail-closed.
  @compute_ceiling 10_000.0
  @memory_objects_ceiling 50_000

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
    Logger.info(
      "[CivilizationKernel] Starting kernel for civilization: #{inspect(civilization_id)}"
    )

    GenServer.start_link(
      __MODULE__,
      %{
        civilization_id: civilization_id,
        institutions: Map.get(init_state, :institutions, []),
        current_tick: 0,
        adaptation_history: [],
        os_state: init_state
      },
      name: __MODULE__
    )
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

  This is the ONLY governed write path into the canonical civilization state.
  The transformed state is validated against civilizational invariants
  (resource ceilings, tenant isolation) and rejected fail-closed on violation.
  Successful updates are recorded in the governance audit log.
  """
  @spec update_state(fun()) :: {:ok, map()} | {:error, atom()}
  def update_state(transform_fn) when is_function(transform_fn, 1) do
    GenServer.call(__MODULE__, {:update_state, transform_fn})
  end

  @doc """
  Read the current canonical civilization state.
  """
  @spec get_state() :: map()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc """
  Deliberate constitutional bypass: install `new_state` verbatim, skipping ALL
  normal validation (resource ceilings, tenant isolation). Used for human veto /
  correction where a human authoritatively overrides the constitution. The
  override is recorded in `governance.overrides` and `governance.audit_log`.
  """
  @spec human_override(map()) :: {:ok, map()} | {:error, term()}
  def human_override(new_state) when is_map(new_state) do
    GenServer.call(__MODULE__, {:human_override, new_state})
  end

  @doc """
  Roll the canonical state back to `target_state`, infallibly (ARC1 rule):
  civilization memory is preserved and the rollback is logged to the
  governance audit log.
  """
  @spec rollback(map()) :: {:ok, map()} | {:error, term()}
  def rollback(target_state) when is_map(target_state) do
    GenServer.call(__MODULE__, {:rollback, target_state})
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
    Logger.info(
      "[CivilizationKernel] Initialized for civilization: #{inspect(state.civilization_id)}"
    )

    Logger.info("[CivilizationKernel] Managing #{length(state.institutions)} institutions")

    {:ok, state}
  end

  @impl true
  def handle_call(:security_policy_mode, _from, state) do
    # kernel_policy_mode/0 reads the active policy through this call; missing
    # this clause crashed the kernel (FunctionClauseError) on every tool run.
    mode = state |> Map.get(:security, %{}) |> Map.get(:policy_mode, :strict)
    {:reply, mode, state}
  end

  @impl true
  def handle_call({:evaluate_civilization_adaptation, opts}, _from, state) do
    Logger.info(
      "[CivilizationKernel] Evaluating civilization adaptation for #{inspect(state.civilization_id)}"
    )

    # Create CivilizationAdaptationResult canonical transaction
    result = CivilizationAdaptationResult.new(state.civilization_id, opts)

    # Add lifecycle event
    result =
      CivilizationAdaptationResult.add_lifecycle_event(result, :evaluation_initiated, %{
        civilization_id: state.civilization_id,
        evaluation_scope: opts[:evaluation_scope],
        institutions_count: length(state.institutions)
      })

    # Add semantic event
    result =
      CivilizationAdaptationResult.add_semantic_event(result, :civilization_evaluation_started, %{
        civilization_id: state.civilization_id,
        scope: opts[:evaluation_scope] || :all_institutions
      })

    # Record institutions being evaluated
    result = %{result | institutions_evaluated: state.institutions}

    # REAL PIPELINE: Execute cross-institution coordination analysis
    #
    # Fail-closed (2026-10-17, production-readiness scan A1): the pipeline
    # returns {:error, reason} while its institutional inputs are simulated
    # and its result-attachment layer was success-shaped stubs. The previous
    # success path here was also broken — execute_pipeline returned
    # {:ok, :stub} (a tuple) and the code dereferenced .coordination_strategy
    # on it, which would crash on any call (this handle_call has no
    # production callers). The struct-handling success path is removed;
    # restore it when the pipeline is rewired with real institutional inputs
    # and real CivilizationAdaptationResult attachment functions.
    case CivilizationAdaptationPipeline.execute_pipeline(result, state.civilization_id, opts) do
      {:error, _reason} = error ->
        Logger.warning(
          "[CivilizationKernel] Adaptation pipeline unavailable: #{inspect(error)}"
        )
        {:reply, error, state}
    end
  end

  @impl true
  def handle_call({:update_state, transform_fn}, _from, state) do
    os_state = current_os_state(state)
    new_os_state = transform_fn.(os_state)

    case validate_state(new_os_state) do
      :ok ->
        audited = log_governance_event(new_os_state, :update_state, %{})
        {:reply, {:ok, audited}, %{state | os_state: audited}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, current_os_state(state), state}
  end

  @impl true
  def handle_call({:human_override, new_state}, _from, state) do
    # Constitutional bypass: no validation. Record the override in both the
    # overrides ledger and the governance audit log.
    governance = Map.get(new_state, :governance, %{}) |> normalize_governance()
    event = override_event(:human_override)

    governance = %{
      governance
      | overrides: Map.get(governance, :overrides, []) ++ [event],
        audit_log: Map.get(governance, :audit_log, []) ++ [event]
    }

    overridden = %{new_state | governance: governance}
    {:reply, {:ok, overridden}, %{state | os_state: overridden}}
  end

  @impl true
  def handle_call({:rollback, target_state}, _from, state) do
    os_state = current_os_state(state)

    # ARC1: preserve the current civilization memory across the rollback.
    restored = %{target_state | memory: Map.get(os_state, :memory, %{})}

    event = %{
      type: :rollback,
      at: DateTime.utc_now(),
      from_worlds: os_state |> Map.get(:worlds, %{}) |> map_size(),
      to_worlds: restored |> Map.get(:worlds, %{}) |> map_size()
    }

    governance = Map.get(restored, :governance, %{}) |> normalize_governance()
    governance = %{governance | audit_log: Map.get(governance, :audit_log, []) ++ [event]}
    restored = %{restored | governance: governance}

    {:reply, {:ok, restored}, %{state | os_state: restored}}
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

  # ==================== Governance & Validation ====================

  # The kernel may be started with a bare map (e.g. `%{}`) that predates the
  # canonical State substrate. Normalize lazily so the governed API always
  # operates on a well-formed %State{}.
  defp current_os_state(%{os_state: %State{} = s}), do: s

  defp current_os_state(%{os_state: other}) when is_map(other),
    do: struct(State, Map.to_list(other))

  defp current_os_state(_), do: struct(State)

  defp normalize_governance(g) when is_map(g) do
    %{
      active_mode: Map.get(g, :active_mode, :balanced),
      constitutional_events: Map.get(g, :constitutional_events, []),
      overrides: Map.get(g, :overrides, []),
      audit_log: Map.get(g, :audit_log, [])
    }
  end

  defp normalize_governance(_), do: normalize_governance(%{})

  defp override_event(type) do
    %{type: type, at: DateTime.utc_now()}
  end

  defp log_governance_event(%State{} = s, action, meta) do
    governance = normalize_governance(Map.get(s, :governance, %{}))
    event = Map.merge(%{type: action, at: DateTime.utc_now()}, meta)
    %{s | governance: %{governance | audit_log: governance.audit_log ++ [event]}}
  end

  defp log_governance_event(other, action, meta) when is_map(other) do
    governance = normalize_governance(Map.get(other, :governance, %{}))
    event = Map.merge(%{type: action, at: DateTime.utc_now()}, meta)
    %{other | governance: %{governance | audit_log: governance.audit_log ++ [event]}}
  end

  # Resource-ceiling + tenant-isolation validation, fail-closed.
  defp validate_state(%State{} = s) do
    with :ok <- validate_compute_ceiling(s),
         :ok <- validate_memory_objects_ceiling(s),
         :ok <- validate_tenant_isolation(s) do
      :ok
    end
  end

  defp validate_state(_), do: :ok

  # Sum of every institution's compute_share must not exceed the civilizational
  # compute ceiling.
  defp validate_compute_ceiling(%State{institutions: insts}) when is_map(insts) do
    total =
      insts
      |> Map.values()
      |> Enum.reduce(0.0, fn
        %{compute_share: v}, acc when is_number(v) -> acc + v * 1.0
        _, acc -> acc
      end)

    if total > @compute_ceiling do
      {:error, :compute_ceiling_exceeded}
    else
      :ok
    end
  end

  defp validate_compute_ceiling(_), do: :ok

  defp validate_memory_objects_ceiling(%State{} = s) do
    total = count_memory_objects(s)

    if total > @memory_objects_ceiling do
      {:error, :memory_objects_ceiling_exceeded}
    else
      :ok
    end
  end

  # Approximate the memory-object footprint as the count of every entry across
  # the collection-valued state fields.
  defp count_memory_objects(%State{} = s) do
    [
      s.worlds,
      s.theories,
      s.institutions,
      s.tools,
      s.evidence_graph,
      s.discoveries,
      s.research_programs,
      s.collaborators,
      s.discovery_assets,
      s.capabilities
    ]
    |> Enum.reduce(0, fn
      m, acc when is_map(m) -> acc + map_size(m)
      _, acc -> acc
    end)
  end

  # Every world must belong to the active tenant ("default_tenant"). A world
  # seeded under a different tenant is an isolation violation and is rejected.
  defp validate_tenant_isolation(%State{worlds: worlds}) when is_map(worlds) do
    if Enum.any?(worlds, fn {_id, w} ->
         Map.get(w, :tenant_id, "default_tenant") != "default_tenant"
       end) do
      {:error, :tenant_isolation_violation}
    else
      :ok
    end
  end

  defp validate_tenant_isolation(_), do: :ok

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
end
