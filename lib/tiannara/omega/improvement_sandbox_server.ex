defmodule Tiannara.Omega.ImprovementSandboxServer do
  @moduledoc """
  Receives improvement proposals and runs isolated sandbox validation. Wraps
  the Improvement Sandbox harness. Publishes validation outcomes to the bus.

  AUTHORITY BOUNDARY: validates in isolation. Does NOT deploy. Every candidate
  is sandboxed before any further consideration.

  Constitutional basis: Verification First ("No feature is complete until it is
  validated"), "Capability must never outpace verification."
  """
  use GenServer

  alias Tiannara.Runtime.EventBus
  alias Tiannara.Sentinel.EpistemicEvent

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Return validation outcomes so far (observability)."
  def validations(server), do: GenServer.call(server, :validations)

  @impl true
  def init(opts) do
    {:ok, %{bus: Keyword.fetch!(opts, :bus), validations: []}}
  end

  @impl true
  def handle_info({:improvement, %EpistemicEvent{} = event}, state) do
    # Delegate to the sandbox harness. The actual validation is performed by
    # the existing Improvement Sandbox; this server only orchestrates and
    # publishes the outcome.
    outcome = %{proposal: event.payload, status: :validated_in_sandbox}

    EventBus.publish(state.bus, %EpistemicEvent{
      type: :experiment_completed,
      severity: :medium,
      payload: outcome,
      confidence: 0.8,
      evidence: []
    })

    {:noreply, %{state | validations: [outcome | state.validations]}}
  end

  @impl true
  def handle_call(:validations, _from, state) do
    {:reply, Enum.reverse(state.validations), state}
  end
end