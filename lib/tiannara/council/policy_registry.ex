defmodule Tiannara.Council.PolicyRegistry do
  use GenServer
  require Logger

  @type policy_id :: atom()
  @type policy :: %{
          id: policy_id(),
          description: String.t(),
          applies_to: [atom()],
          conditions: [condition()],
          action: :approve | :reject | :require_human | :require_simulation | :escalate,
          priority: integer(),
          enabled: boolean()
        }
  @type condition ::
          {:risk_above, float()}
          | {:touches_invariant, boolean()}
          | {:actor_is, atom()}
          | {:mission_impact, :high | :critical}
          | {:resource_cost_above, non_neg_integer()}
          | {:always}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def evaluate(decision_type, context) do
    GenServer.call(__MODULE__, {:evaluate, decision_type, context})
  end

  def register_policy(policy), do: GenServer.call(__MODULE__, {:register, policy})
  def disable_policy(policy_id), do: GenServer.call(__MODULE__, {:disable, policy_id})
  def active_policies, do: GenServer.call(__MODULE__, :active)

  @impl true
  def init(_opts) do
    policies = default_policies()
    Logger.info("PolicyRegistry: initialized with #{map_size(policies)} policies")
    {:ok, %{policies: policies}}
  end

  @impl true
  def handle_call({:evaluate, decision_type, context}, _from, state) do
    matching =
      state.policies
      |> Map.values()
      |> Enum.filter(&(&1.enabled and decision_type in &1.applies_to))
      |> Enum.filter(&all_conditions_met?(&1.conditions, context))
      |> Enum.sort_by(& &1.priority, :desc)

    case matching do
      [best | _] -> {:reply, {:matched, best}, state}
      [] -> {:reply, {:default_approve, nil}, state}
    end
  end

  @impl true
  def handle_call({:register, policy}, _from, state) do
    {:reply, :ok, put_in(state, [:policies, policy.id], policy)}
  end

  @impl true
  def handle_call({:disable, id}, _from, state) do
    if Map.has_key?(state.policies, id) do
      {:reply, :ok, put_in(state, [:policies, id, :enabled], false)}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:active, _from, state) do
    active = state.policies |> Map.values() |> Enum.filter(& &1.enabled)
    {:reply, active, state}
  end

  defp default_policies do
    %{
      architectural_change: %{
        id: :architectural_change,
        description: "All architectural changes require human approval",
        applies_to: [:architectural_change, :subsystem_decommission, :module_replacement],
        conditions: [{:always}],
        action: :require_human,
        priority: 100,
        enabled: true
      },
      self_modification: %{
        id: :self_modification,
        description: "Self-modification requires simulation + human approval",
        applies_to: [:self_modification, :constitutional_amendment],
        conditions: [{:always}],
        action: :require_simulation,
        priority: 110,
        enabled: true
      },
      high_risk: %{
        id: :high_risk,
        description: "Decisions with risk > 0.8 require human review",
        applies_to: [:any],
        conditions: [{:risk_above, 0.8}],
        action: :require_human,
        priority: 90,
        enabled: true
      },
      invariant_protection: %{
        id: :invariant_protection,
        description: "Actions touching hard invariants require human override",
        applies_to: [:any],
        conditions: [{:touches_invariant, true}],
        action: :require_human,
        priority: 200,
        enabled: true
      },
      emergency_halt: %{
        id: :emergency_halt,
        description: "Emergency actions approved immediately for safety",
        applies_to: [:emergency_halt, :circuit_breaker],
        conditions: [{:always}],
        action: :approve,
        priority: 300,
        enabled: true
      },
      resource_threshold: %{
        id: :resource_threshold,
        description: "Resource reallocation above 50% of pool requires review",
        applies_to: [:resource_reallocation],
        conditions: [{:resource_cost_above, 5000}],
        action: :require_human,
        priority: 80,
        enabled: true
      }
    }
  end

  defp all_conditions_met?(conditions, context) do
    Enum.all?(conditions, &condition_met?(&1, context))
  end

  defp condition_met?({:always}, _ctx), do: true
  defp condition_met?({:risk_above, threshold}, ctx), do: Map.get(ctx, :risk_assessment, 0.0) > threshold
  defp condition_met?({:touches_invariant, true}, ctx), do: Map.get(ctx, :touches_invariant, false)
  defp condition_met?({:actor_is, actor}, ctx), do: Map.get(ctx, :actor) == actor
  defp condition_met?({:mission_impact, level}, ctx), do: Map.get(ctx, :mission_impact) == level
  defp condition_met?({:resource_cost_above, threshold}, ctx), do: Map.get(ctx, :resource_cost, 0) > threshold
  defp condition_met?(_, _), do: false
end
