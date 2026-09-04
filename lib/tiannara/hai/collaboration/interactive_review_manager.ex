defmodule Tiannara.HAI.Collaboration.InteractiveReviewManager do
  use GenServer
  require Logger

  alias Tiannara.HAI.HAIEvents

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def open_session(discovery_id, reviewer_id, context \\ %{}) do
    GenServer.call(__MODULE__, {:open_session, discovery_id, reviewer_id, context})
  end

  def record_decision(session_id, decision, rationale, modifications \\ %{}) do
    GenServer.call(__MODULE__, {:record_decision, session_id, decision, rationale, modifications})
  end

  def add_comment(session_id, reviewer_id, comment) do
    GenServer.call(__MODULE__, {:add_comment, session_id, reviewer_id, comment})
  end

  def active_sessions, do: GenServer.call(__MODULE__, :active_sessions)

  def review_history(discovery_id), do: GenServer.call(__MODULE__, {:history, discovery_id})

  def metrics, do: GenServer.call(__MODULE__, :metrics)

  @impl true
  def init(_opts) do
    {:ok, %{
      sessions: %{},
      history: [],
      total_sessions: 0,
      total_decisions: 0,
      approval_count: 0,
      rejection_count: 0,
      modification_count: 0,
      avg_review_time_ms: 0,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_call({:open_session, discovery_id, reviewer_id, context}, _from, state) do
    session_id = "session_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    session = %{
      id: session_id,
      discovery_id: discovery_id,
      reviewer_id: reviewer_id,
      context: context,
      status: :active,
      comments: [],
      decision: nil,
      rationale: nil,
      modifications: %{},
      opened_at: DateTime.utc_now(),
      closed_at: nil
    }

    HAIEvents.emit(:review_submitted, session_id, %{
      discovery_id: discovery_id,
      reviewer_id: reviewer_id
    })

    {:reply, {:ok, session}, %{state |
      sessions: Map.put(state.sessions, session_id, session),
      total_sessions: state.total_sessions + 1
    }}
  end

  @impl true
  def handle_call({:record_decision, session_id, decision, rationale, modifications}, _from, state) do
    case Map.fetch(state.sessions, session_id) do
      {:ok, session} ->
        closed_at = DateTime.utc_now()
        review_time = DateTime.diff(closed_at, session.opened_at, :millisecond)

        updated_session = %{session |
          status: :closed,
          decision: decision,
          rationale: rationale,
          modifications: modifications,
          closed_at: closed_at
        }

        HAIEvents.emit(:review_resolved, session_id, %{
          discovery_id: session.discovery_id,
          decision: decision,
          review_time_ms: review_time
        })

        new_avg =
          if state.total_decisions == 0 do
            review_time
          else
            (state.avg_review_time_ms * state.total_decisions + review_time) / (state.total_decisions + 1)
          end

        decision_increment = case decision do
          :approved -> %{approval_count: 1}
          :rejected -> %{rejection_count: 1}
          :modified -> %{modification_count: 1}
          _ -> %{}
        end

        new_state = %{state |
          sessions: Map.put(state.sessions, session_id, updated_session),
          history: [updated_session | state.history] |> Enum.take(500),
          total_decisions: state.total_decisions + 1,
          avg_review_time_ms: new_avg
        }

        new_state = Enum.reduce(decision_increment, new_state, fn {key, val}, acc ->
          Map.update(acc, key, val, &(&1 + val))
        end)

        {:reply, :ok, new_state}

      :error ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call({:add_comment, session_id, reviewer_id, comment}, _from, state) do
    case Map.fetch(state.sessions, session_id) do
      {:ok, session} ->
        new_comment = %{
          reviewer_id: reviewer_id,
          comment: comment,
          at: DateTime.utc_now()
        }

        updated = %{session | comments: session.comments ++ [new_comment]}
        {:reply, :ok, %{state | sessions: Map.put(state.sessions, session_id, updated)}}

      :error ->
        {:reply, {:error, :session_not_found}, state}
    end
  end

  @impl true
  def handle_call(:active_sessions, _from, state) do
    active = state.sessions |> Map.values() |> Enum.filter(&(&1.status == :active))
    {:reply, active, state}
  end

  @impl true
  def handle_call({:history, discovery_id}, _from, state) do
    history = Enum.filter(state.history, &(&1.discovery_id == discovery_id))
    {:reply, history, state}
  end

  @impl true
  def handle_call(:metrics, _from, state) do
    {:reply, %{
      total_sessions: state.total_sessions,
      total_decisions: state.total_decisions,
      approval_count: state.approval_count,
      rejection_count: state.rejection_count,
      modification_count: state.modification_count,
      approval_rate: safe_div(state.approval_count, state.total_decisions),
      avg_review_time_ms: state.avg_review_time_ms,
      active_sessions: state.sessions |> Map.values() |> Enum.count(&(&1.status == :active))
    }, state}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}

  defp safe_div(_n, 0), do: 0.0
  defp safe_div(n, d), do: n / d
end
