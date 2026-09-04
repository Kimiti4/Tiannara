defmodule Tiannara.CEL.Services.RuntimePolicyEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.CEL.Policy.RuntimePolicy
  alias Tiannara.CEL.Services.ExecutiveMemory
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @impl true
  def id, do: :runtime_policy_engine

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [:dynamic_policy_management, :operational_constraint_evaluation,
     :rate_limiting, :feature_flagging, :policy_auditability]
  end

  @impl true
  def dependencies, do: [:executive_memory]

  @impl true
  def health do
    if Process.whereis(__MODULE__), do: :healthy, else: :unhealthy
  end

  @impl true
  def constitutional_score do
    active_count =
      if Process.whereis(__MODULE__) do
        GenServer.call(__MODULE__, :stats)
      else
        %{active_policy_count: 0}
      end

    %ConstitutionalScore{
      service_id: id(),
      health: 1.0,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def put_policy(%RuntimePolicy{} = policy) do
    GenServer.call(__MODULE__, {:put_policy, policy})
  end

  def disable_policy(policy_id, actor) do
    GenServer.call(__MODULE__, {:disable_policy, policy_id, actor})
  end

  def evaluate(context) do
    GenServer.call(__MODULE__, {:evaluate, context})
  end

  def active_policies, do: GenServer.call(__MODULE__, :active_policies)

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    Process.send_after(self(), :cleanup_expired, :timer.minutes(5))
    {:ok, %{
      policies: %{},
      evaluation_count: 0,
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:put_policy, policy}, _from, state) do
    record_decision("policy_#{policy.id}_v#{policy.version}", :runtime_policy_updated, %{
      policy_id: policy.id, version: policy.version, enabled: policy.enabled, actions: policy.actions
    }, %{actor: policy.created_by, source: :runtime_policy_engine})

    emit_constitutional_event(:policy_updated, %{policy_id: policy.id, version: policy.version}, %{})

    new_policies = Map.put(state.policies, policy.id, policy)
    {:reply, :ok, %{state | policies: new_policies}}
  end

  @impl true
  def handle_call({:disable_policy, policy_id, actor}, _from, state) do
    case Map.fetch(state.policies, policy_id) do
      {:ok, policy} ->
        disabled = %{policy | enabled: false}
        new_policies = Map.put(state.policies, policy_id, disabled)

        record_decision("policy_#{policy_id}_disabled", :runtime_policy_disabled, %{
          policy_id: policy_id
        }, %{actor: actor, source: :runtime_policy_engine})

        {:reply, :ok, %{state | policies: new_policies}}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:evaluate, context}, _from, state) do
    applicable =
      state.policies
      |> Map.values()
      |> Enum.filter(&policy_active?(&1, context))
      |> Enum.sort_by(& &1.priority, :desc)

    decision =
      case applicable do
        [] ->
          {:allowed, %{reason: "no_matching_policy"}}

        [policy | _] ->
          emit_constitutional_event(:policy_matched, %{policy_id: policy.id}, %{
            context: sanitize_context(context)
          })

          {map_to_decision(policy.actions), %{policy_id: policy.id, policy_name: policy.name}}
      end

    {:reply, decision, %{state | evaluation_count: state.evaluation_count + 1}}
  end

  @impl true
  def handle_call(:active_policies, _from, state) do
    active = state.policies |> Map.values() |> Enum.filter(& &1.enabled)
    {:reply, active, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    active_count = state.policies |> Map.values() |> Enum.count(& &1.enabled)
    {:reply, %{
      healthy: state.healthy,
      total_policies: map_size(state.policies),
      active_policy_count: active_count,
      evaluation_count: state.evaluation_count
    }, state}
  end

  @impl true
  def handle_info(:cleanup_expired, state) do
    now = DateTime.utc_now()

    {new_policies, expired} =
      Map.split_with(state.policies, fn {_id, policy} ->
        is_nil(policy.expires_at) or DateTime.compare(policy.expires_at, now) == :gt
      end)

    expired_count = map_size(expired)

    if expired_count > 0 do
      Logger.info("RuntimePolicyEngine: Cleaned up #{expired_count} expired policies")
      record_decision("policy_cleanup_#{DateTime.to_unix(now)}", :runtime_policies_expired, %{
        count: expired_count
      }, %{source: :runtime_policy_engine})
    end

    Process.send_after(self(), :cleanup_expired, :timer.minutes(5))
    {:noreply, %{state | policies: new_policies}}
  end

  defp policy_active?(policy, context) do
    policy.enabled and evaluate_conditions(policy.conditions, context)
  end

  defp evaluate_conditions(conditions, context) when is_map(conditions) do
    Enum.all?(conditions, fn {key, expected} ->
      actual = Map.get(context, key)

      case expected do
        {:gt, threshold} -> is_number(actual) and actual > threshold
        {:lt, threshold} -> is_number(actual) and actual < threshold
        {:in, list} -> is_list(list) and actual in list
        _ -> actual == expected
      end
    end)
  end

  defp map_to_decision(actions) do
    cond do
      Map.get(actions, :allow) == false ->
        {:denied, Map.get(actions, :reason, "policy_denied"), actions}

      Map.has_key?(actions, :throttle_ms) ->
        {:throttled, Map.get(actions, :throttle_ms), actions}

      Map.has_key?(actions, :route_to) ->
        {:routed, Map.get(actions, :route_to), actions}

      true ->
        {:allowed, actions}
    end
  end

  defp sanitize_context(context) do
    Map.drop(context, [:large_payload, :raw_data])
  end

  defp record_decision(correlation_id, event_type, payload, metadata) do
    ExecutiveMemory.record_event(event_type, payload, Map.put(metadata, :correlation_id, correlation_id))
  rescue
    _ -> :ok
  end
end
