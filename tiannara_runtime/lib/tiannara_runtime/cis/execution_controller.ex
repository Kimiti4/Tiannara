defmodule TiannaraRuntime.CIS.ExecutionController do
  @moduledoc """
  CIS ExecutionController — single execution step of the documented authority
  chain: CIS Supervisor decides → this controller executes → systems comply.

  5F-P0 restoration (2026-10-19): `execute_kill/3` and
  `terminate_resource/3` were removed from this module (stub reduction
  after `8610c558`) while `MultiWorld.KillSwitch` and `Resources.QuotaGovernor`
  kept calling them (UndefinedFunctionError on the safety chain, audit P0).
  They are re-added additively with the original decision mapping
  (`:approve → :executed`, `:deny → :denied`,
  `:require_secondary_validation → :escalated`) and NO supervision-tree
  changes.
  """

  use GenServer

  alias TiannaraRuntime.CIS.Supervisor, as: CISSup
  alias TiannaraRuntime.MultiWorld.WorldSupervisor
  alias Tiannara.Meta.ChronogramMatrix
  alias Tiannara.GCK.ChronogramGate

  require Logger

  defstruct execution_count: 0, deny_count: 0

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def execute(action, target, reason, severity) do
    GenServer.call(__MODULE__, {:execute, action, target, reason, severity})
  end

  @doc """
  Kill path of the authority chain (5F-P0 restoration).

  Requests `CIS.Supervisor.authorize_kill/3`, then maps the decision:
  - `:approve` → best-effort termination command → `:executed`
  - `:deny` → `:denied`
  - `:require_secondary_validation` → `:escalated`

  `:executed` means CIS-authorized and the termination command was
  ATTEMPTED; delivery requires a registered WorldSupervisor (logged as
  undelivered otherwise). No supervision wiring is added here.
  """
  def execute_kill(world_id, reason, severity \\ :critical) do
    GenServer.call(__MODULE__, {:execute_kill, world_id, reason, severity})
  end

  @doc """
  Resource-termination path of the authority chain (5F-P0 restoration).

  Requests `CIS.Supervisor.authorize_resource_termination/3` with the same
  `:executed | :denied | :escalated` mapping. Authorized cleanup is
  log-only (no resource subsystem is wired into this controller).
  """
  def terminate_resource(resource_id, reason, severity \\ :elevated) do
    GenServer.call(__MODULE__, {:terminate_resource, resource_id, reason, severity})
  end

  def execute_emergency_shutdown(reason) do
    GenServer.cast(__MODULE__, {:emergency_shutdown, reason})
    :initiated
  end

  def register_chronogram_observer(observer_id, parent_id \\ nil) do
    ChronogramMatrix.register_observer(observer_id, parent_id)
  end

  def execute_memory_write(observer_id, state) do
    case ChronogramGate.validate_write(observer_id, state) do
      {:allow, :ok} ->
        ChronogramMatrix.write(observer_id, state)
        {:ok, :written}

      {:reject, reason} ->
        {:error, :gck_rejected, reason}
    end
  end

  def execute_memory_read(observer_id, coordinate) do
    ChronogramMatrix.read(observer_id, coordinate)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:execute, _action, _target, _reason, _severity}, _from, state) do
    safety_mode =
      case Process.whereis(CISSup) do
        nil -> :normal
        _ -> CISSup.get_safety_mode()
      end

    case safety_mode do
      :lockdown ->
        {:reply, {:error, :denied_by_cis}, %{state | deny_count: state.deny_count + 1}}
      _ ->
        {:reply, :ok, %{state | execution_count: state.execution_count + 1}}
    end
  end

  @impl true
  def handle_call({:execute_kill, world_id, reason, severity}, _from, state) do
    case CISSup.authorize_kill(world_id, reason, severity) do
      :approve ->
        delivered = deliver_termination_command(world_id)

        Logger.info(
          "CIS.ExecutionController kill authorized for #{world_id} (command delivered: #{delivered})"
        )

        {:reply, :executed, %{state | execution_count: state.execution_count + 1}}

      :deny ->
        Logger.error("CIS.ExecutionController kill denied by CIS for #{world_id}: #{reason}")
        {:reply, :denied, %{state | deny_count: state.deny_count + 1}}

      :require_secondary_validation ->
        Logger.warning(
          "CIS.ExecutionController kill requires secondary validation for #{world_id}"
        )

        {:reply, :escalated, state}
    end
  end

  @impl true
  def handle_call({:terminate_resource, resource_id, reason, severity}, _from, state) do
    case CISSup.authorize_resource_termination(resource_id, reason, severity) do
      :approve ->
        Logger.info(
          "CIS.ExecutionController resource termination authorized for #{resource_id}: #{reason}"
        )

        {:reply, :executed, %{state | execution_count: state.execution_count + 1}}

      :deny ->
        Logger.error("CIS.ExecutionController resource termination denied by CIS: #{resource_id}")
        {:reply, :denied, %{state | deny_count: state.deny_count + 1}}

      :require_secondary_validation ->
        Logger.warning(
          "CIS.ExecutionController resource termination requires secondary validation: #{resource_id}"
        )

        {:reply, :escalated, state}
    end
  end

  # Best-effort delivery to the registered WorldSupervisor; never raises.
  # When no WorldSupervisor is registered the command is truthfully logged
  # as undelivered (the caller still receives :executed — the frozen
  # caller vocabulary from the original contract).
  defp deliver_termination_command(world_id) do
    case Process.whereis(WorldSupervisor) do
      nil ->
        Logger.warning(
          "CIS.ExecutionController WorldSupervisor not registered — termination command NOT delivered for #{world_id}"
        )

        false

      pid ->
        send(pid, {:kill_world, world_id, :execution_controller_approved})
        true
    end
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply, %__MODULE__{}}
  end

  @impl true
  def handle_cast({:emergency_shutdown, _reason}, state) do
    {:noreply, state}
  end
end
