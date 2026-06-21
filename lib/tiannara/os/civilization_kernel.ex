defmodule TiannaraOS.CivilizationKernel do
  @moduledoc """
  Top-level authority for TiannaraOS.
  Handles L0 invariants, human overrides, rollback authority, resource ceilings,
  tenant isolation, and audit logs. Operates as a pure constitutional OS kernel.
  """

  use GenServer
  require Logger

  alias TiannaraOS.State

  # Default limits
  @max_compute_ceiling 10_000.0
  @max_memory_objects 50_000

  defstruct [
    :state,
    :tenant_id,
    :audit_log,
    :resource_limits
  ]

  # --- PUBLIC API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Retrieves the current canonical state struct."
  @spec get_state() :: State.t()
  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  @doc "Updates the canonical state using a state-modifying function, verifying invariants."
  @spec update_state((State.t() -> State.t())) :: {:ok, State.t()} | {:error, any()}
  def update_state(update_fun) when is_function(update_fun, 1) do
    GenServer.call(__MODULE__, {:update_state, update_fun})
  end

  @doc "Triggers a human veto override on the state."
  @spec human_override(State.t()) :: {:ok, State.t()} | {:error, any()}
  def human_override(new_state) do
    GenServer.call(__MODULE__, {:human_override, new_state})
  end

  @doc "Triggers an infallible rollback to a historical snapshot."
  @spec rollback(State.t()) :: {:ok, State.t()} | {:error, any()}
  def rollback(snapshot_state) do
    GenServer.call(__MODULE__, {:rollback, snapshot_state})
  end

  @doc "Validates a tool's security profile against L0 kernel security rules."
  @spec validate_security_profile(map()) :: :ok | {:error, atom()}
  def validate_security_profile(security_profile) do
    state = get_state()
    policy_mode = (state.security || %{})[:policy_mode] || :strict

    cond do
      policy_mode == :strict and not Map.get(security_profile, :read_sandbox, false) ->
        {:error, :untrusted_sandbox}

      policy_mode == :strict and Map.get(security_profile, :network_access, false) ->
        {:error, :unauthorized_network_access}

      true ->
        :ok
    end
  end

  # --- CALLBACKS ---

  @impl true
  def init(opts) do
    tenant_id = opts[:tenant_id] || "default_tenant"
    initial_state = %State{
      research_programs: %{},
      discovery_assets: %{},
      collaborators: %{
        human_expert_1: %TiannaraOS.HumanCollaborator{
          id: :human_expert_1,
          expertise: [:cryptography, :system_security],
          trust_score: 0.9,
          role: :domain_expert,
          organization: "Tiannara Core Security Group"
        },
        human_auditor: %TiannaraOS.HumanCollaborator{
          id: :human_auditor,
          expertise: [:governance, :audit],
          trust_score: 0.95,
          role: :auditor,
          organization: "Tiannara Constitutional Council"
        }
      },
      governance: %{
        active_mode: :balanced,
        constitutional_events: [],
        overrides: [],
        audit_log: [],
        damping_factor: 0.9,
        max_cascade_operations: 1000,
        paused_cascades: %{}
      }
    }

    limits = %{
      compute_ceiling: opts[:compute_ceiling] || @max_compute_ceiling,
      memory_objects_ceiling: opts[:memory_objects_ceiling] || @max_memory_objects
    }

    {:ok, %__MODULE__{
      state: initial_state,
      tenant_id: tenant_id,
      audit_log: [],
      resource_limits: limits
    }}
  end

  @impl true
  def handle_call(:get_state, _from, kernel_state) do
    {:reply, kernel_state.state, kernel_state}
  end

  @impl true
  def handle_call({:update_state, update_fun}, _from, kernel_state) do
    new_state = update_fun.(kernel_state.state)

    case verify_invariants(new_state, kernel_state.tenant_id, kernel_state.resource_limits) do
      :ok ->
        new_kernel_state = %{kernel_state | state: new_state}
        {:reply, {:ok, new_state}, new_kernel_state}
      {:error, reason} ->
        logged_state = record_violation(kernel_state, reason)
        {:reply, {:error, reason}, logged_state}
    end
  end

  @impl true
  def handle_call({:human_override, target_state}, _from, kernel_state) do
    # Human overrides bypass general invariants but log an audit trail
    event = %{
      type: :human_override,
      timestamp: System.system_time(:millisecond),
      description: "Human override executed successfully."
    }

    new_governance = %{
      kernel_state.state.governance |
      overrides: [event | kernel_state.state.governance.overrides],
      audit_log: [event | kernel_state.state.governance.audit_log]
    }
    
    new_state = %{target_state | governance: new_governance}
    new_kernel = %{kernel_state | state: new_state, audit_log: [event | kernel_state.audit_log]}
    
    Logger.warning("⚡ [Civilization Kernel] HUMAN OVERRIDE INVARIANT APPLIED BY AUTHORIZED OBSERVER.")
    {:reply, {:ok, new_state}, new_kernel}
  end

  @impl true
  def handle_call({:rollback, snapshot_state}, _from, kernel_state) do
    # Rollback restores state except it preserves civilization memory audits
    event = %{
      type: :rollback,
      timestamp: System.system_time(:millisecond),
      description: "State rolled back to historical snapshot."
    }

    # Preserved global ledger memory
    preserved_memory = kernel_state.state.memory

    new_governance = %{
      snapshot_state.governance |
      constitutional_events: [event | snapshot_state.governance.constitutional_events],
      audit_log: [event | snapshot_state.governance.audit_log]
    }

    new_state = %{snapshot_state | memory: preserved_memory, governance: new_governance}
    new_kernel = %{kernel_state | state: new_state, audit_log: [event | kernel_state.audit_log]}
    
    Logger.warning("⚠️ [Civilization Kernel] Infallible state rollback executed. Memory preserved.")
    {:reply, {:ok, new_state}, new_kernel}
  end

  # --- INVARIANTS VALIDATION ---

  defp verify_invariants(state, tenant_id, limits) do
    cond do
      # Invariant 1: Resource limits bounds
      exceeds_compute_limit?(state, limits.compute_ceiling) ->
        {:error, :compute_ceiling_exceeded}

      exceeds_memory_objects?(state, limits.memory_objects_ceiling) ->
        {:error, :memory_objects_ceiling_exceeded}

      # Invariant 2: Tenant isolation validation (no cross-contamination)
      cross_tenant_violation?(state, tenant_id) ->
        {:error, :tenant_isolation_violation}

      true ->
        :ok
    end
  end

  defp exceeds_compute_limit?(state, ceiling) do
    # Sum compute allocation across economy/institutions
    total_compute =
      state.institutions
      |> Map.values()
      |> Enum.reduce(0.0, fn inst, acc -> acc + (inst.compute_share || 0.0) end)

    total_compute > ceiling
  end

  defp exceeds_memory_objects?(state, ceiling) do
    # Sum total elements in the state maps and nested twin states
    twins_count = Enum.count(state.worlds, fn {_id, world} -> Map.get(world, :twin) != nil end)
    total_objs =
      Enum.count(state.worlds) +
      Enum.count(state.theories) +
      Enum.count(state.institutions) +
      Enum.count(state.tools) +
      Enum.count(state.discoveries) +
      twins_count

    total_objs > ceiling
  end

  defp cross_tenant_violation?(state, tenant_id) do
    # Check if any world has a mismatching tenant ID
    Enum.any?(state.worlds, fn {_id, world} ->
      world_tenant = Map.get(world, :tenant_id)
      world_tenant != nil and world_tenant != tenant_id
    end)
  end

  defp record_violation(kernel_state, reason) do
    event = %{
      type: :invariant_violation,
      timestamp: System.system_time(:millisecond),
      description: "Invariant verification failed: #{inspect(reason)}"
    }

    new_governance = %{
      kernel_state.state.governance |
      audit_log: [event | kernel_state.state.governance.audit_log]
    }

    new_state = %{kernel_state.state | governance: new_governance}
    %{kernel_state | state: new_state, audit_log: [event | kernel_state.audit_log]}
  end
end
