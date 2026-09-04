defmodule Tiannara.HAI.ReviewRouter do
  use GenServer
  require Logger

  alias Tiannara.HAI.Domain.ReviewRequest
  alias Tiannara.HAI.HAIEvents

  @mandatory_levels [:high, :critical, :civilizational]
  @recommended_levels [:medium]
  @informational_levels [:low]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def submit_review(request_attrs) do
    GenServer.call(__MODULE__, {:submit, request_attrs})
  end

  def record_decision(review_id, decision, rationale) do
    GenServer.call(__MODULE__, {:decide, review_id, decision, rationale})
  end

  def pending_reviews do
    GenServer.call(__MODULE__, :pending)
  end

  def reviews_by_status(status) do
    GenServer.call(__MODULE__, {:by_status, status})
  end

  def mandatory_review?(impact_level), do: impact_level in @mandatory_levels

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    {:ok, %{reviews: %{}, total_submitted: 0, total_approved: 0, total_rejected: 0,
      total_modified: 0, total_deferred: 0, total_expired: 0, mandatory_count: 0,
      healthy: true, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:submit, attrs}, _from, state) do
    request = ReviewRequest.new(attrs)
    routing = determine_routing(request.impact_level)

    HAIEvents.emit(:review_submitted, request.id, %{
      source: request.source_subsystem, impact_level: request.impact_level,
      routing: routing, confidence: request.confidence,
      mandatory: ReviewRequest.mandatory_review?(request)})

    mandatory_increment = if ReviewRequest.mandatory_review?(request), do: 1, else: 0

    new_state = %{state | reviews: Map.put(state.reviews, request.id, %{request | status: routing}),
      total_submitted: state.total_submitted + 1,
      mandatory_count: state.mandatory_count + mandatory_increment}

    {:reply, {:ok, %{request | status: routing}}, new_state}
  end

  @impl true
  def handle_call({:decide, review_id, decision, rationale}, _from, state) do
    case Map.fetch(state.reviews, review_id) do
      {:ok, request} ->
        updated = %{request | status: decision, human_decision: decision,
          human_rationale: rationale, resolved_at: DateTime.utc_now()}

        HAIEvents.emit(:review_resolved, review_id, %{
          decision: decision, rationale: rationale, impact_level: request.impact_level,
          resolution_time_ms: DateTime.diff(updated.resolved_at, request.created_at, :millisecond)})

        counter_key = case decision do
          :approved -> :total_approved; :rejected -> :total_rejected
          :modified -> :total_modified; :deferred -> :total_deferred
          :expired -> :total_expired; _ -> nil
        end

        new_state = %{state | reviews: Map.put(state.reviews, review_id, updated)}
        new_state = if counter_key, do: Map.update(new_state, counter_key, 1, &(&1 + 1)), else: new_state
        {:reply, :ok, new_state}

      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:pending, _from, state) do
    pending = state.reviews |> Map.values() |> Enum.filter(&(&1.status == :pending))
    {:reply, pending, state}
  end

  @impl true
  def handle_call({:by_status, status}, _from, state) do
    filtered = state.reviews |> Map.values() |> Enum.filter(&(&1.status == status))
    {:reply, filtered, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{healthy: state.healthy, total_submitted: state.total_submitted,
      total_approved: state.total_approved, total_rejected: state.total_rejected,
      total_modified: state.total_modified, total_deferred: state.total_deferred,
      total_expired: state.total_expired, mandatory_count: state.mandatory_count,
      pending_count: state.reviews |> Map.values() |> Enum.count(&(&1.status == :pending)),
      approval_rate: safe_div(state.total_approved, state.total_submitted)}, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp determine_routing(impact_level) when impact_level in @mandatory_levels, do: :pending
  defp determine_routing(impact_level) when impact_level in @recommended_levels, do: :pending
  defp determine_routing(_impact_level), do: :approved

  defp safe_div(_n, 0), do: 0.0
  defp safe_div(n, d), do: n / d
end
