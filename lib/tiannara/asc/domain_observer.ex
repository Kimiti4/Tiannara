defmodule Tiannara.ASC.DomainObserver do
  @moduledoc """
  PubSub subscriber that monitors all Tiannara domain discovery events
  and forwards them into the ASC research and architecture pipelines.

  Subscribes to:
    - `"discoveries:*"` — any KG discovery committed from any domain
    - `"asc:research:domain_vectors"` — ResearchBridge portfolio vector refreshes

  On receiving a discovery from a seed domain (computation, cybernetics,
  mathematics, engineering), it:
    1. Stores the discovery hint in `KnowledgeArchive`
    2. Broadcasts `"asc:architecture:hint"` for the Architecture Civilization
    3. Broadcasts `"asc:research:hint"` for the Research Civilization
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.KnowledgeArchive
  alias Tiannara.ASC.KnowledgeArchive.Entry

  @seed_domains [:computation, :cybernetics, :engineering, :software_engineering]
  @subscribed_topics ["discoveries:software_engineering", "asc:research:domain_vectors"]

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    # Subscribe to relevant PubSub topics
    Enum.each(@subscribed_topics, fn topic ->
      Phoenix.PubSub.subscribe(Tiannara.PubSub, topic)
    end)

    # Also subscribe to all discovery topics from seed domains
    Enum.each(@seed_domains, fn domain ->
      Phoenix.PubSub.subscribe(Tiannara.PubSub, "discoveries:#{domain}")
    end)

    Logger.info("[ASC.DomainObserver] Subscribed to #{length(@subscribed_topics) + length(@seed_domains)} PubSub topics")
    {:ok, %{hints_received: 0}}
  end

  @impl true
  def handle_info({:discovery, node}, state) do
    handle_discovery(node)
    {:noreply, %{state | hints_received: state.hints_received + 1}}
  end

  # Handle raw node maps (PubSub may deliver the struct directly)
  @impl true
  def handle_info(%{type: :discovery} = node, state) do
    handle_discovery(node)
    {:noreply, %{state | hints_received: state.hints_received + 1}}
  end

  @impl true
  def handle_info(%{vectors: _vectors} = msg, state) do
    # Domain vector refresh — forward to architecture civilization
    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:architecture:domain_context", msg)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp handle_discovery(node) do
    domains = Map.get(node, :domains, [])
    relevant = Enum.any?(domains, &(&1 in @seed_domains))

    if relevant do
      Logger.debug("[ASC.DomainObserver] Received relevant discovery: #{inspect(Map.get(node, :id))}")

      # Archive the hint
      KnowledgeArchive.store(%Entry{
        type: :insight,
        project_id: nil,
        content: %{
          source_domain: List.first(domains),
          discovery_id: Map.get(node, :id),
          discovery_name: Map.get(node, :name),
          metadata: Map.get(node, :metadata, %{})
        },
        tags: ["domain_discovery", "research_feed"],
        confidence: get_in(node, [:metadata, :confidence]) || 0.75
      })

      # Broadcast to ASC sub-civilizations
      Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:architecture:hint", %{
        source: :domain_observer,
        discovery: node
      })

      Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:research:hint", %{
        source: :domain_observer,
        discovery: node
      })
    end
  end
end
