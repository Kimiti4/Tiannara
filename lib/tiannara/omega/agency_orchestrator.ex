defmodule Tiannara.Omega.AgencyOrchestrator do
  @moduledoc """
  Routes epistemic events from the EventBus to the appropriate Ω handler.

  Routing rules:
    * research-relevant events  → ResearchDirectorServer
    * improvement_proposed      → ImprovementSandboxServer
    * ALL events                → CognitiveInterfaceServer (for communication)

  The orchestrator only ROUTES; it does not investigate, validate, or decide.
  This preserves minimal coupling and independent replaceability.

  Constitutional basis: Architecture Philosophy (minimal coupling), Modularity,
  augmentation clause (routes to human-facing decisions, does not replace them).
  """
  use GenServer

  alias Tiannara.Runtime.EventBus
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Research.Director.EvidenceDriven

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Return routing statistics for observability."
  def stats(server), do: GenServer.call(server, :stats)

  @impl true
  def init(opts) do
    bus = Keyword.fetch!(opts, :bus)

    state = %{
      bus: bus,
      research_director: Keyword.get(opts, :research_director, Tiannara.Omega.ResearchDirectorServer),
      cognitive_interface:
        Keyword.get(opts, :cognitive_interface, Tiannara.Omega.CognitiveInterfaceServer),
      sandbox: Keyword.get(opts, :sandbox, Tiannara.Omega.ImprovementSandboxServer),
      routed: 0,
      by_type: %{}
    }

    EventBus.subscribe(bus, self())
    {:ok, state}
  end

  @impl true
  def handle_info({:epistemic_event, %EpistemicEvent{} = event}, state) do
    route(event, state)
    by_type = Map.update(state.by_type, event.type, 1, &(&1 + 1))
    {:noreply, %{state | routed: state.routed + 1, by_type: by_type}}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{routed: state.routed, by_type: state.by_type}, state}
  end

  # --- routing ------------------------------------------------------------

  defp route(%EpistemicEvent{type: :improvement_proposed} = event, state) do
    send_to(state.sandbox, {:improvement, event})
    send_to(state.cognitive_interface, {:epistemic_event, event})
  end

  defp route(%EpistemicEvent{} = event, state) do
    if EvidenceDriven.research_relevant?(event) do
      send_to(state.research_director, {:investigate, event})
    end

    send_to(state.cognitive_interface, {:epistemic_event, event})
  end

  # Graceful degradation: if a target is down, do not escalate or retry
  # autonomously. Simply skip. This honors "no autonomous escalation."
  defp send_to(target, message) do
    case Process.whereis(target) do
      nil -> :ok
      pid -> send(pid, message)
    end
  end
end