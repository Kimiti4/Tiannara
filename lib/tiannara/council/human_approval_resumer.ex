defmodule Tiannara.Council.HumanApprovalResumer do
  @moduledoc """
  Supervised resumption of human-approved decisions.

  A human approval is a *record*, not an authorisation. This process takes the
  approval that has just been recorded and re-evaluates the parked decision
  with the human grant applied, so that the constitutional evaluation - not
  the approval record - decides the outcome (F-GOV-004).

  The resumption runs in its own supervised process rather than inside the
  approval call, so that the approval call never blocks on the Council while
  the Council may be blocked on the queue. The resumer reads the request from
  the queue, re-evaluates it through the Council, and writes the resulting
  decision back to the queue.
  """

  use GenServer
  require Logger

  alias Tiannara.Council.{AuditLog, HumanApprovalQueue}

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  @doc "Asks the resumer to resume a decision whose human approval was recorded."
  def resume(request_id), do: GenServer.cast(__MODULE__, {:resume, request_id})

  @impl true
  def init(_opts) do
    {:ok, %{resumed: 0}}
  end

  @impl true
  def handle_cast({:resume, request_id}, state) do
    case HumanApprovalQueue.get(request_id) do
      %{status: :approved, decision_type: decision_type, context: payload} ->
        auth = Tiannara.Council.resume_human_approval(request_id, decision_type, payload)

        # Keep the request id on the decision so a caller can correlate the
        # authorisation with the approval it came from.
        auth = %{auth | metadata: Map.put(auth.metadata, :request_id, request_id)}

        HumanApprovalQueue.record_resume(request_id, auth)

        AuditLog.append(:human_approval_resumed, :council, %{
          request_id: request_id,
          decision_type: decision_type,
          decision: auth.decision
        })

        Logger.info(
          "HumanApprovalResumer: #{request_id} resumed as #{inspect(auth.decision)} (#{decision_type})"
        )

        {:noreply, %{state | resumed: state.resumed + 1}}

      other ->
        Logger.warning(
          "HumanApprovalResumer: #{request_id} is not resumable (#{inspect(other, limit: 3)})"
        )

        {:noreply, state}
    end
  end
end
