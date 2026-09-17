defmodule ObservatoryApiWeb.Hub.AlertEngine do
  use GenServer

  @severities [:info, :notice, :warning, :critical, :constitutional, :scientific, :civilizational]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def raise_alert(category, severity, message, evidence \\ %{}) do
    GenServer.cast(__MODULE__, {:alert, category, severity, message, evidence})
  end

  def active_alerts(opts \\ []) do
    GenServer.call(__MODULE__, {:active, opts})
  end

  def acknowledge(alert_id) do
    GenServer.cast(__MODULE__, {:acknowledge, alert_id})
  end

  def resolve(alert_id) do
    GenServer.cast(__MODULE__, {:resolve, alert_id})
  end

  def alert_history(category \\ nil, limit \\ 50) do
    GenServer.call(__MODULE__, {:history, category, limit})
  end

  @impl true
  def init(_opts) do
    {:ok, %{active: %{}, resolved: %{}, history: :queue.new(), total: 0}}
  end

  @impl true
  def handle_cast({:alert, category, severity, message, evidence}, state) do
    id = Ecto.UUID.generate()
    severity = if severity in @severities, do: severity, else: :info

    alert = %{
      id: id,
      category: category,
      severity: severity,
      message: message,
      evidence: evidence,
      status: :active,
      raised_at: DateTime.utc_now(),
      acknowledged_at: nil,
      resolved_at: nil,
      priority: severity_index(severity)
    }

    ObservatoryApiWeb.Hub.EventDispatcher.dispatch(alert, severity_to_priority(severity))

    {:noreply,
     %{
       state
       | active: Map.put(state.active, id, alert),
         history: :queue.in(alert, state.history),
         total: state.total + 1
     }}
  end

  @impl true
  def handle_cast({:acknowledge, alert_id}, %{active: active} = state) do
    case Map.get(active, alert_id) do
      nil ->
        {:noreply, state}

      alert ->
        acknowledged = %{alert | status: :acknowledged, acknowledged_at: DateTime.utc_now()}
        {:noreply, %{state | active: Map.put(active, alert_id, acknowledged)}}
    end
  end

  @impl true
  def handle_cast({:resolve, alert_id}, %{active: active, resolved: resolved} = state) do
    case Map.get(active, alert_id) do
      nil ->
        {:noreply, state}

      alert ->
        resolved_alert = %{alert | status: :resolved, resolved_at: DateTime.utc_now()}

        {:noreply,
         %{
           state
           | active: Map.delete(active, alert_id),
             resolved: Map.put(resolved, alert_id, resolved_alert)
         }}
    end
  end

  @impl true
  def handle_call({:active, _opts}, _from, %{active: active} = state) do
    sorted = active |> Map.values() |> Enum.sort_by(fn a -> a.priority end, :desc)
    {:reply, sorted, state}
  end

  @impl true
  def handle_call({:history, nil, limit}, _from, state) do
    entries = :queue.to_list(state.history) |> Enum.reverse() |> Enum.take(limit)
    {:reply, entries, state}
  end

  @impl true
  def handle_call({:history, category, limit}, _from, state) do
    entries =
      :queue.to_list(state.history)
      |> Enum.reverse()
      |> Enum.filter(fn a -> a.category == category end)
      |> Enum.take(limit)

    {:reply, entries, state}
  end

  defp severity_index(:info), do: 0
  defp severity_index(:notice), do: 1
  defp severity_index(:warning), do: 2
  defp severity_index(:critical), do: 3
  defp severity_index(:constitutional), do: 4
  defp severity_index(:scientific), do: 5
  defp severity_index(:civilizational), do: 6

  defp severity_to_priority(:info), do: :background
  defp severity_to_priority(:notice), do: :background
  defp severity_to_priority(:warning), do: :normal
  defp severity_to_priority(:critical), do: :alert
  defp severity_to_priority(:constitutional), do: :constitutional
  defp severity_to_priority(:scientific), do: :scientific
  defp severity_to_priority(:civilizational), do: :constitutional
end
