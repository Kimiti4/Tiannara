defmodule ObservatoryApiWeb.Hub.SubscriptionRegistry do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register_operator(operator_id, role, permissions) do
    GenServer.cast(__MODULE__, {:register, operator_id, role, permissions})
  end

  def subscribe(operator_id, topic, pid, opts \\ %{}) do
    GenServer.cast(__MODULE__, {:subscribe, operator_id, topic, pid, opts})
  end

  def unsubscribe(operator_id, topic) do
    GenServer.cast(__MODULE__, {:unsubscribe, operator_id, topic})
  end

  def authorized?(operator_id, topic) do
    GenServer.call(__MODULE__, {:authorized, operator_id, topic})
  end

  def operator_subscriptions(operator_id) do
    GenServer.call(__MODULE__, {:subscriptions, operator_id})
  end

  def registry_stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    {:ok, %{operators: %{}, topic_subscribers: %{}}}
  end

  @impl true
  def handle_cast({:register, operator_id, role, permissions}, state) do
    {:noreply,
     %{
       state
       | operators:
           Map.put(state.operators, operator_id, %{
             id: operator_id,
             role: role,
             permissions: permissions,
             subscriptions: [],
             budget: compute_budget(role),
             joined_at: DateTime.utc_now()
           })
     }, state}
  end

  @impl true
  def handle_cast({:subscribe, op_id, topic, pid, opts}, state) do
    case Map.get(state.operators, op_id) do
      nil ->
        {:noreply, state}

      op ->
        topic_subs = Map.get(state.topic_subscribers, topic, [])

        new_topic_subs = [
          {op_id, pid, opts} | Enum.reject(topic_subs, fn {oid, _, _} -> oid == op_id end)
        ]

        updated_op = %{op | subscriptions: [topic | op.subscriptions -- [topic]]}

        {:noreply,
         %{
           state
           | operators: Map.put(state.operators, op_id, updated_op),
             topic_subscribers: Map.put(state.topic_subscribers, topic, new_topic_subs)
         }}
    end
  end

  @impl true
  def handle_cast({:unsubscribe, op_id, topic}, state) do
    topic_subs = Map.get(state.topic_subscribers, topic, [])
    cleaned = Enum.reject(topic_subs, fn {oid, _, _} -> oid == op_id end)

    operators =
      case Map.get(state.operators, op_id) do
        nil -> state.operators
        op -> Map.put(state.operators, op_id, %{op | subscriptions: op.subscriptions -- [topic]})
      end

    {:noreply,
     %{
       state
       | operators: operators,
         topic_subscribers: Map.put(state.topic_subscribers, topic, cleaned)
     }}
  end

  @impl true
  def handle_call({:authorized, op_id, topic}, _from, state) do
    result =
      case Map.get(state.operators, op_id) do
        nil ->
          {:error, :unregistered_operator}

        op ->
          topic_perm = Map.get(op.permissions, topic, :deny)
          {:ok, topic_perm in [:allow, :read, :subscribe]}
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:subscriptions, op_id}, _from, state) do
    result =
      case Map.get(state.operators, op_id) do
        nil -> []
        op -> op.subscriptions
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    total_subs =
      Enum.reduce(state.topic_subscribers, 0, fn {_, subs}, acc -> acc + length(subs) end)

    {:reply,
     %{
       operators: map_size(state.operators),
       topics: map_size(state.topic_subscribers),
       total_subscriptions: total_subs,
       operator_roles: state.operators |> Enum.map(fn {_, o} -> o.role end) |> Enum.frequencies()
     }, state}
  end

  defp compute_budget(:administrator), do: 100
  defp compute_budget(:scientist), do: 50
  defp compute_budget(:engineer), do: 50
  defp compute_budget(:auditor), do: 30
  defp compute_budget(:observer), do: 10
  defp compute_budget(:governor), do: 75
  defp compute_budget(_), do: 20
end
