defmodule Tiannara.Council.HumanApprovalQueue do
  use GenServer
  require Logger

  alias Tiannara.Council.{AuditLog, HumanApprovalResumer}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def enqueue(request_id, decision_type, context, explanation) do
    GenServer.call(__MODULE__, {:enqueue, request_id, decision_type, context, explanation})
  end

  def approve(request_id, human_id, notes \\ "") do
    GenServer.call(__MODULE__, {:approve, request_id, human_id, notes})
  end

  def reject(request_id, human_id, reason) do
    GenServer.call(__MODULE__, {:reject, request_id, human_id, reason})
  end

  def pending, do: GenServer.call(__MODULE__, :pending)
  def get(request_id), do: GenServer.call(__MODULE__, {:get, request_id})

  @doc "Records the decision a resumption produced for an approved request."
  def record_resume(request_id, authorization) do
    GenServer.call(__MODULE__, {:record_resume, request_id, authorization})
  end

  @doc """
  Finds an approved request for this exact decision.

  The match is on the decision type and the payload, so an approval applies to
  the decision the human saw - not to a different decision of the same type.
  """
  def approved_request(decision_type, context) do
    GenServer.call(__MODULE__, {:approved_request, decision_type, context})
  end

  @impl true
  def init(_opts) do
    {:ok, %{queue: %{}, history: []}}
  end

  @impl true
  def handle_call({:enqueue, id, type, context, explanation}, _from, state) do
    request = %{
      id: id,
      decision_type: type,
      context: context,
      explanation: explanation,
      status: :queued,
      enqueued_at: DateTime.utc_now(),
      decided_by: nil,
      decided_at: nil,
      notes: "",
      resumed_decision: nil
    }

    AuditLog.append(:human_review_queued, :council, %{request_id: id, type: type})
    Logger.info("HumanApprovalQueue: #{id} queued for human review (#{type})")

    :telemetry.execute([:tiannara, :council, :approval, :queued], %{}, %{request_id: id, type: type})
    {:reply, :ok, put_in(state, [:queue, id], request)}
  end

  @impl true
  def handle_call({:approve, id, human_id, notes}, _from, state) do
    case Map.fetch(state.queue, id) do
      {:ok, request} ->
        updated = %{
          request
          | status: :approved,
            decided_by: human_id,
            decided_at: DateTime.utc_now(),
            notes: notes,
            resumed_decision: nil
        }

        AuditLog.append(:human_approved, human_id, %{request_id: id, notes: notes})

        :telemetry.execute([:tiannara, :council, :approval, :approved], %{}, %{request_id: id, human_id: human_id})

        new_state = %{state | queue: Map.delete(state.queue, id), history: [updated | state.history]}

        # The approval is a record, not an authorisation. The supervised
        # resumer re-evaluates the parked decision with the grant applied and
        # writes the resulting decision back to the queue.
        HumanApprovalResumer.resume(id)

        {:reply, :ok, new_state}

      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:record_resume, id, authorization}, _from, state) do
    history =
      Enum.map(state.history, fn request ->
        if request.id == id, do: Map.put(request, :resumed_decision, authorization), else: request
      end)

    {:reply, :ok, %{state | history: history}}
  end

  @impl true
  def handle_call({:approved_request, decision_type, context}, _from, state) do
    match =
      Enum.find(state.history, fn request ->
        request.status == :approved and
          request.decision_type == decision_type and
          request.context == context
      end)

    case match do
      nil -> {:reply, :none, state}
      request -> {:reply, {:ok, request}, state}
    end
  end

  @impl true
  def handle_call({:reject, id, human_id, reason}, _from, state) do
    case Map.fetch(state.queue, id) do
      {:ok, request} ->
        updated = %{request | status: :rejected, decided_by: human_id, decided_at: DateTime.utc_now(), notes: reason}
        AuditLog.append(:human_rejected, human_id, %{request_id: id, reason: reason})

        new_state = %{state | queue: Map.delete(state.queue, id), history: [updated | state.history]}
        {:reply, :ok, new_state}

      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:pending, _from, state) do
    pending = state.queue |> Map.values() |> Enum.sort_by(& &1.enqueued_at)
    {:reply, pending, state}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    result = Map.get(state.queue, id) || Enum.find(state.history, &(&1.id == id))
    {:reply, result, state}
  end
end
