defmodule Tiannara.Omega.GovernanceGateServer do
  @moduledoc """
  The terminal constitutional authority in the Ω tree. Receives certificates and
  enforces governance rules. The decisive rule: deployment requires HUMAN
  authorization. This server never grants deployment autonomously.

  AUTHORITY BOUNDARY: this is the control point. It can HOLD a proposal pending
  human authorization, but it can NEVER authorize deployment on its own. This is
  the constitutional backstop that keeps autonomy subordinate to human judgment.

  Constitutional basis: augmentation clause (final constitutional clause),
  Safety and Reliability ("Capability must never outpace verification"),
  "Maintain audit trails."
  """
  use GenServer

  alias Tiannara.Sentinel.EpistemicEvent

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Return governance decisions (audit trail)."
  def decisions(server), do: GenServer.call(server, :decisions)

  @impl true
  def init(opts) do
    bus = Keyword.fetch!(opts, :bus)
    Tiannara.Runtime.EventBus.subscribe(bus, self())
    {:ok, %{bus: bus, decisions: []}}
  end

  @impl true
  def handle_info({:epistemic_event, %EpistemicEvent{type: :knowledge_updated} = event}, state) do
    # Governance rule: any improvement reaching this point is HELD pending human
    # authorization. We never auto-deploy.
    decision = %{
      for: event.payload,
      status: :held_pending_human_authorization,
      reason: :deployment_requires_human_authorization,
      timestamp: System.system_time(:second)
    }

    {:noreply, %{state | decisions: [decision | state.decisions]}}
  end

  def handle_info({:epistemic_event, _event}, state), do: {:noreply, state}

  @impl true
  def handle_call(:decisions, _from, state) do
    {:reply, Enum.reverse(state.decisions), state}
  end
end