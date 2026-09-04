defmodule Tiannara.Omega.ResearchDirectorServer do
  @moduledoc """
  Wraps the evidence-driven Research Director in a supervised GenServer.
  Receives research-relevant epistemic events, runs the investigation, and
  publishes proposals back to the EventBus.

  AUTHORITY BOUNDARY: investigates and proposes only. Does NOT execute,
  deploy, or escalate.

  Constitutional basis: Scientific Method, Evidence Before Confidence,
  augmentation clause.
  """
  use GenServer

  alias Tiannara.Runtime.EventBus
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Research.Director.EvidenceDriven

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Return the list of investigations produced so far (observability)."
  def investigations(server), do: GenServer.call(server, :investigations)

  @impl true
  def init(opts) do
    bus = Keyword.fetch!(opts, :bus)
    {:ok, %{bus: bus, investigations: []}}
  end

  @impl true
  def handle_info({:investigate, %EpistemicEvent{} = event}, state) do
    investigation = EvidenceDriven.investigate(event)

    # Publish proposals to the bus for downstream (sandbox, governance).
    Enum.each(investigation.proposals, fn proposal ->
      EventBus.publish(state.bus, %EpistemicEvent{
        type: :research_opportunity,
        severity: :medium,
        payload: %{proposal: proposal, from_investigation: investigation.opportunity.id},
        confidence: investigation.uncertainty,
        evidence: investigation.evidence_assessment.available
      })
    end)

    {:noreply, %{state | investigations: [investigation | state.investigations]}}
  end

  @impl true
  def handle_call(:investigations, _from, state) do
    {:reply, Enum.reverse(state.investigations), state}
  end
end