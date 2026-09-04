defmodule Tiannara.Omega.CognitiveInterfaceServer do
  @moduledoc """
  Produces human-facing communication decisions for every epistemic event.
  Wraps the Communication Director. This is the Ω.3 layer: it prepares
  explanations and authorization requests, but does NOT notify humans directly
  or act autonomously.

  AUTHORITY BOUNDARY: prepares communication decisions. Actual delivery and
  judgment remain with the human.

  Constitutional basis: augmentation clause (final constitutional clause),
  Explainability, "Uncertainty should never be hidden."
  """
  use GenServer

  alias Tiannara.Sentinel.EpistemicEvent
  alias Tiannara.Communication.Director, as: CommDirector

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.fetch!(opts, :name))
  end

  @doc "Return accumulated communication decisions (observability)."
  def decisions(server), do: GenServer.call(server, :decisions)

  @impl true
  def init(opts) do
    {:ok, %{bus: Keyword.fetch!(opts, :bus), decisions: []}}
  end

  @impl true
  def handle_info({:epistemic_event, %EpistemicEvent{} = event}, state) do
    decision = CommDirector.decide(event, %{})
    {:noreply, %{state | decisions: [decision | state.decisions]}}
  end

  @impl true
  def handle_call(:decisions, _from, state) do
    {:reply, Enum.reverse(state.decisions), state}
  end
end