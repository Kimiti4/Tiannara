defmodule Tiannara.Omega.Loop do
  @moduledoc """
  The Ω-layer integration loop, now wired to the FULL evidence-driven Ω.2
  Research Director by default. Subscribes to the epistemic EventBus and routes:

    * research-relevant events -> Ω.2 evidence-driven Research Director
        (stores the full investigation: evidence assessment, hypotheses,
         falsifiers, ranked experiments, AND the extracted proposals)
    * improvement_proposed     -> Ω.4 improvement queue
    * significant events       -> Ω.3 Communication Director (decision only)

  The loop PROPOSES and DECIDES; it never executes, deploys, or notifies.

  Constitutional basis: augmentation clause, "Capability must never outpace
  verification", Observability, "Maintain audit trails".
  """
  use GenServer

  alias Tiannara.Runtime.EventBus
  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Research.Director.EvidenceDriven

  def start_link(opts) do
    case Keyword.get(opts, :name) do
      nil -> GenServer.start_link(__MODULE__, opts)
      name -> GenServer.start_link(__MODULE__, opts, name: name)
    end
  end

  # --- public API ---

  def proposals(server \\ __MODULE__), do: GenServer.call(server, :proposals)
  def investigations(server \\ __MODULE__), do: GenServer.call(server, :investigations)
  def notification_decisions(server \\ __MODULE__), do: GenServer.call(server, :notification_decisions)
  def improvement_queue(server \\ __MODULE__), do: GenServer.call(server, :improvement_queue)
  def status(server \\ __MODULE__), do: GenServer.call(server, :status)

  # --- callbacks ---

  @impl true
  def init(opts) do
    bus = Keyword.fetch!(opts, :bus)
    comm_director = Keyword.get(opts, :comm_director)
    research_director = Keyword.get(opts, :research_director, EvidenceDriven)

    EventBus.subscribe(bus, self())

    {:ok,
     %{bus: bus, comm_director: comm_director, research_director: research_director,
       investigations: [], proposals: [], notification_decisions: [],
       improvement_queue: [], events_processed: 0}}
  end

  @impl true
  def handle_info({:epistemic_event, %EpistemicEvent{} = event}, state) do
    state = %{state | events_processed: state.events_processed + 1}

    state =
      cond do
        state.research_director.research_relevant?(event) ->
          investigation = state.research_director.investigate(event)

          %{state
           | investigations: state.investigations ++ [investigation],
             proposals: state.proposals ++ investigation.proposals}

        event.type == :improvement_proposed ->
          %{state | improvement_queue: state.improvement_queue ++ [event]}

        true ->
          state
      end

    state = maybe_communication_decision(state, event)
    {:noreply, state}
  end

  @impl true
  def handle_call(:proposals, _from, state), do: {:reply, state.proposals, state}
  def handle_call(:investigations, _from, state), do: {:reply, state.investigations, state}
  def handle_call(:notification_decisions, _from, state), do: {:reply, state.notification_decisions, state}
  def handle_call(:improvement_queue, _from, state), do: {:reply, state.improvement_queue, state}

  def handle_call(:status, _from, state) do
    {:reply,
     %{events_processed: state.events_processed,
       investigations: length(state.investigations),
       proposals: length(state.proposals),
       notification_decisions: length(state.notification_decisions),
       improvement_queue: length(state.improvement_queue)},
     state}
  end

  # --- internals ---

  defp maybe_communication_decision(state, _event) when is_nil(state.comm_director), do: state

  defp maybe_communication_decision(state, event) do
    decision = state.comm_director.decide(event, %{})
    %{state | notification_decisions: state.notification_decisions ++ [decision]}
  end
end