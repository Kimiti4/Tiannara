defmodule Tiannara.Interface.ProactiveNotifier do
  @moduledoc """
  Proactive Notifier — generates and rate-limits proactive communications.
  Determines when Tiannara should initiate communication with human operators,
  formulates the notification, and delivers it through configured channels.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types
  alias Tiannara.Interface.DiscoveryPresenter

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec notify(map()) :: {:ok, binary()} | {:error, :rate_limited | :deduplicated}
  def notify(discovery) do
    GenServer.call(__MODULE__, {:notify, discovery})
  end

  @spec pending() :: [map()]
  def pending do
    GenServer.call(__MODULE__, :pending)
  end

  @spec acknowledge(binary()) :: :ok | {:error, :not_found}
  def acknowledge(notification_id) do
    GenServer.call(__MODULE__, {:acknowledge, notification_id})
  end

  @spec pending_count() :: non_neg_integer()
  def pending_count do
    GenServer.call(__MODULE__, :pending_count)
  end

  @spec total_sent() :: non_neg_integer()
  def total_sent do
    GenServer.call(__MODULE__, :total_sent)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(opts) do
    rate_limit = Keyword.get(opts, :rate_limit_per_hour, 10)
    {:ok, %{notifications: %{}, delivery_log: [], rate_limit_per_hour: rate_limit, window_start: DateTime.utc_now(), window_count: 0, total_sent: 0, total_rate_limited: 0, total_deduplicated: 0}}
  end

  @impl true
  def handle_call({:notify, discovery}, _from, state) do
    priority = classify_priority(discovery)
    state = maybe_reset_window(state)

    if priority in [:immediate, :urgent] or state.window_count < state.rate_limit_per_hour do
      if deduplicated?(discovery, state) do
        {:reply, {:error, :deduplicated}, %{state | total_deduplicated: state.total_deduplicated + 1}}
      else
        notification = build_notification(discovery, priority)
        deliver(notification)
        notifications = Map.put(state.notifications, notification.id, notification)

        :telemetry.execute([:tiannara, :interface, :notification_sent], %{count: 1}, %{priority: priority, source: discovery[:source]})

        {:reply, {:ok, notification.id}, %{state | notifications: notifications, delivery_log: [notification.id | Enum.take(state.delivery_log, 99)], window_count: state.window_count + 1, total_sent: state.total_sent + 1}}
      end
    else
      {:reply, {:error, :rate_limited}, %{state | total_rate_limited: state.total_rate_limited + 1}}
    end
  end

  @impl true
  def handle_call(:pending, _from, state) do
    pending = state.notifications |> Map.values() |> Enum.filter(fn n -> not n.acknowledged end) |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
    {:reply, pending, state}
  end

  @impl true
  def handle_call({:acknowledge, notification_id}, _from, state) do
    case Map.get(state.notifications, notification_id) do
      nil -> {:reply, {:error, :not_found}, state}
      notification -> {:reply, :ok, %{state | notifications: Map.put(state.notifications, notification_id, %{notification | acknowledged: true})}}
    end
  end

  @impl true
  def handle_call(:pending_count, _from, state) do
    {:reply, state.notifications |> Map.values() |> Enum.count(fn n -> not n.acknowledged end), state}
  end

  @impl true
  def handle_call(:total_sent, _from, state) do
    {:reply, state.total_sent, state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_sent: state.total_sent, total_rate_limited: state.total_rate_limited, total_deduplicated: state.total_deduplicated, pending: Enum.count(state.notifications, fn {_, n} -> not n.acknowledged end), window_count: state.window_count, rate_limit_per_hour: state.rate_limit_per_hour}, state}
  end

  defp classify_priority(%{severity: :emergency}), do: :immediate
  defp classify_priority(%{severity: :critical}), do: :immediate
  defp classify_priority(%{severity: :warning}), do: :urgent
  defp classify_priority(%{confidence: c}) when c >= 0.9, do: :urgent
  defp classify_priority(%{confidence: c}) when c >= 0.7, do: :scheduled
  defp classify_priority(_), do: :background

  defp maybe_reset_window(state) do
    now = DateTime.utc_now()
    if DateTime.diff(now, state.window_start, :second) >= 3600 do
      %{state | window_start: now, window_count: 0}
    else
      state
    end
  end

  defp deduplicated?(discovery, state) do
    recent_ids = Enum.take(state.delivery_log, 20)
    Enum.any?(recent_ids, fn id ->
      case Map.get(state.notifications, id) do
        nil -> false
        n -> n.title == discovery[:title] and n.source == discovery[:source]
      end
    end)
  end

  defp build_notification(discovery, priority) do
    presented = DiscoveryPresenter.present(discovery)
    %{id: Types.new_id(), priority: priority, title: presented.title, body: presented.body, evidence: presented.evidence, source: discovery[:source] || :unknown, rationale: discovery[:rationale] || "Automated detection.", confidence: discovery[:confidence] || 0.5, actionable: discovery[:recommended_action] != nil, recommended_action: discovery[:recommended_action], created_at: DateTime.utc_now(), delivered_at: DateTime.utc_now(), acknowledged: false}
  end

  defp deliver(notification) do
    Logger.info("[ProactiveNotifier] NOTIFICATION DELIVERED Priority: #{notification.priority} Title: #{notification.title}")
    :telemetry.execute([:tiannara, :interface, :notification_delivered], %{count: 1}, %{priority: notification.priority, channel: :log})
  end
end
