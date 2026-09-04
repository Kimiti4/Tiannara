defmodule Tiannara.ASC.Reality.PhysicalDeploymentManager do
  use GenServer

  alias Tiannara.ASC.Reality.Adapters.SimulatedAdapter
  alias Tiannara.ASC.Reality.SafetyVerificationEngine

  @moduledoc """
  Constitutional planner and gatekeeper for physical deployments.

  A physical deployment is a plan, never an autonomous actor. It proceeds
  through a staged lifecycle in which every transition is verified and the
  `:pending_approval` stage is a hard human gate: no machine path may advance
  a deployment past it. Execution is delegated to a `Tiannara.ASC.Reality.
  PhysicalAdapter` (hardware-agnostic), and an emergency stop is always
  available.

  Lifecycle: planned → safety_reviewed → pending_approval → approved →
  simulated → dry_run → supervised → autonomous → completed
  Terminal: rejected, rolled_back, aborted
  """

  @stage_order [
    :planned,
    :safety_reviewed,
    :pending_approval,
    :approved,
    :simulated,
    :dry_run,
    :supervised,
    :autonomous,
    :completed
  ]

  @terminal_stages [:rejected, :rolled_back, :aborted]

  @default_adapter SimulatedAdapter

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def plan(design) when is_map(design) do
    GenServer.call(__MODULE__, {:plan, design})
  end

  def advance(id) do
    GenServer.call(__MODULE__, {:advance, id})
  end

  def approve(id, approver, note \\ "") do
    GenServer.call(__MODULE__, {:approve, id, approver, note})
  end

  def reject(id, approver, note \\ "") do
    GenServer.call(__MODULE__, {:reject, id, approver, note})
  end

  def abort(id, reason) do
    GenServer.call(__MODULE__, {:abort, id, reason})
  end

  def emergency_stop(id) do
    GenServer.call(__MODULE__, {:emergency_stop, id})
  end

  def resume(id) do
    GenServer.call(__MODULE__, {:resume, id})
  end

  def execute(id, action) do
    GenServer.call(__MODULE__, {:execute, id, action})
  end

  def get_deployment(id) do
    GenServer.call(__MODULE__, {:get_deployment, id})
  end

  def list_deployments do
    GenServer.call(__MODULE__, :list_deployments)
  end

  def adapter_info(id) do
    GenServer.call(__MODULE__, {:adapter_info, id})
  end

  def build_plan(design) when is_map(design) do
    case Map.get(design, :steps, :missing) do
      :missing ->
        {:ok, %{steps: default_steps(), params: Map.get(design, :params, %{})}}

      steps when is_list(steps) and steps != [] ->
        if valid_steps?(steps) do
          {:ok, %{steps: steps, params: Map.get(design, :params, %{})}}
        else
          {:error, :invalid_steps}
        end

      _ ->
        {:error, :invalid_steps}
    end
  end

  def derive_steps(design) when is_map(design) do
    case Map.get(design, :steps, []) do
      [] -> default_steps()
      steps when is_list(steps) -> steps
      _ -> default_steps()
    end
  end

  @impl true
  def init(:ok) do
    {:ok, %{deployments: %{}}}
  end

  @impl true
  def handle_call({:plan, design}, _from, state) do
    with {:ok, plan} <- build_plan(design),
         {:ok, verification} <- safe_verify(design, plan) do
      deployment = %{
        id: "phys-#{:erlang.system_time(:millisecond)}",
        name: Map.get(design, :name, "Physical Deployment"),
        design: design,
        type: Map.get(design, :type, :physical),
        adapter: Map.get(design, :adapter, @default_adapter),
        stage: :planned,
        plan: plan,
        safety_verification: verification,
        approval: nil,
        estop_active: false,
        execution_log: [],
        stage_times: %{planned: now_iso()},
        summary: %{
          safety: length(verification.checks),
          steps: length(plan.steps)
        },
        created_at: DateTime.utc_now()
      }

      {:reply, {:ok, deployment}, put_deployment(state, deployment)}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:advance, id}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{stage: stage} when stage in @terminal_stages ->
        {:reply, {:error, :terminal_stage}, state}

      %{estop_active: true} ->
        {:reply, {:error, :estop_active}, state}

      deployment ->
        case do_advance(deployment.stage, deployment) do
          {:ok, next_stage} ->
            updated = advance_stage(deployment, next_stage)
            {:reply, {:ok, updated}, put_deployment(state, updated)}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
    end
  end

  def handle_call({:approve, id, approver, note}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{stage: :pending_approval} = deployment ->
        updated = %{
          deployment
          | approval: %{
              decision: :approved,
              approver: approver,
              note: note,
              approved_at: DateTime.utc_now()
            }
        }

        {:reply, {:ok, updated}, put_deployment(state, updated)}

      _ ->
        {:reply, {:error, :wrong_stage}, state}
    end
  end

  def handle_call({:reject, id, approver, note}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{stage: :pending_approval} = deployment ->
        updated = %{
          deployment
          | stage: :rejected,
            approval: %{
              decision: :rejected,
              approver: approver,
              note: note,
              rejected_at: DateTime.utc_now()
            }
        }

        {:reply, {:ok, updated}, put_deployment(state, updated)}

      _ ->
        {:reply, {:error, :wrong_stage}, state}
    end
  end

  def handle_call({:abort, id, reason}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      deployment ->
        deployment.adapter.emergency_stop()

        updated = %{
          deployment
          | stage: :aborted,
            estop_active: true,
            stage_times: Map.put(deployment.stage_times, :aborted, now_iso())
        }

        updated = Map.put(updated, :abort_reason, reason)
        {:reply, {:ok, updated}, put_deployment(state, updated)}
    end
  end

  def handle_call({:emergency_stop, id}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      deployment ->
        deployment.adapter.emergency_stop()
        updated = %{deployment | estop_active: true}
        {:reply, {:ok, updated}, put_deployment(state, updated)}
    end
  end

  def handle_call({:resume, id}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      deployment ->
        deployment.adapter.clear_estop()
        updated = %{deployment | estop_active: false}
        {:reply, {:ok, updated}, put_deployment(state, updated)}
    end
  end

  def handle_call({:execute, id, action}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      %{estop_active: true} ->
        {:reply, {:error, :estop_active}, state}

      %{stage: stage} = deployment
      when stage in [:simulated, :dry_run, :supervised, :autonomous] ->
        case deployment.adapter.execute_action(action) do
          {:ok, result} ->
            entry = %{action: action, result: result, at: DateTime.utc_now()}
            updated = %{deployment | execution_log: [entry | deployment.execution_log]}
            {:reply, {:ok, updated}, put_deployment(state, updated)}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      _ ->
        {:reply, {:error, :not_authorized}, state}
    end
  end

  def handle_call({:get_deployment, id}, _from, state) do
    {:reply, Map.get(state.deployments, id), state}
  end

  def handle_call(:list_deployments, _from, state) do
    {:reply, Map.values(state.deployments), state}
  end

  def handle_call({:adapter_info, id}, _from, state) do
    case Map.get(state.deployments, id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      deployment ->
        info = %{
          capabilities: deployment.adapter.capabilities(),
          status: deployment.adapter.status()
        }

        {:reply, {:ok, info}, state}
    end
  end

  defp do_advance(:planned, deployment) do
    safety_review_gate(deployment)
  end

  defp do_advance(:safety_reviewed, _deployment) do
    {:ok, :pending_approval}
  end

  defp do_advance(:pending_approval, deployment) do
    approval_gate(deployment)
  end

  defp do_advance(:approved, _deployment) do
    {:ok, :simulated}
  end

  defp do_advance(:simulated, _deployment) do
    {:ok, :dry_run}
  end

  defp do_advance(:dry_run, _deployment) do
    {:ok, :supervised}
  end

  defp do_advance(:supervised, deployment) do
    simulation_gate(deployment)
  end

  defp do_advance(:autonomous, _deployment) do
    {:ok, :completed}
  end

  defp do_advance(stage, _deployment) when stage in @terminal_stages do
    {:error, :terminal_stage}
  end

  defp do_advance(_stage, _deployment) do
    {:error, :invalid_transition}
  end

  defp safety_review_gate(%{safety_verification: %{passed: true}}), do: {:ok, :safety_reviewed}
  defp safety_review_gate(_deployment), do: {:error, :safety_not_verified}

  defp approval_gate(%{approval: %{decision: :approved}}), do: {:ok, :approved}
  defp approval_gate(_deployment), do: {:error, :requires_human_approval}

  defp simulation_gate(deployment) do
    if adapter_active?(deployment), do: {:ok, :autonomous}, else: {:error, :simulation_not_active}
  end

  defp adapter_active?(deployment) do
    case deployment.adapter.status() do
      %{active: active} -> active
      _ -> false
    end
  end

  defp safe_verify(design, plan) do
    case SafetyVerificationEngine.verify(design, plan) do
      {:ok, %{passed: true} = verification} ->
        {:ok, verification}

      {:ok, _verification} ->
        {:error, :safety_verification_failed}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp valid_steps?(steps) do
    is_list(steps) and steps != [] and
      Enum.all?(steps, &(is_atom(&1) or is_binary(&1) or is_map(&1)))
  end

  defp default_steps do
    [:calibrate, :initialize, :run_diagnostics, :deploy_firmware]
  end

  defp advance_stage(deployment, next_stage) do
    %{
      deployment
      | stage: next_stage,
        stage_times: Map.put(deployment.stage_times, next_stage, now_iso())
    }
  end

  defp put_deployment(state, deployment) do
    %{state | deployments: Map.put(state.deployments, deployment.id, deployment)}
  end

  defp now_iso do
    DateTime.utc_now() |> DateTime.to_iso8601()
  end
end
