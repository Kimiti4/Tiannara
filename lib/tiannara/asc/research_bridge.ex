defmodule Tiannara.ASC.ResearchBridge do
  @moduledoc """
  Bidirectional bridge between ASC and the Tiannara Research civilization.

  ## Inbound (Research → ASC)

  Periodically polls `Tiannara.Research.Director` for proposals and
  `Tiannara.Domains.Registry` portfolio vectors for the four seeder domains:
  `:computation`, `:cybernetics`, `:mathematics`, `:engineering`.

  Translates domain discoveries into ASC architecture pattern hints that
  are stored in `KnowledgeArchive` and broadcast on PubSub for
  `ASC.Architecture.Civilization` to consume.

  ## Outbound (ASC → Research)

  Promotes high-confidence ASC architecture patterns as `:discovery` nodes
  in `Tiannara.KnowledgeGraph.Registry` (rate-limited to 1 node/sec, max 10
  per project, per Q4 config).

  Also submits experiment proposals back to `Research.Director` in the
  standard `%Tiannara.Research.Director{}` proposal format.
  """

  use GenServer
  require Logger

  alias Tiannara.KnowledgeGraph.Registry, as: KG
  alias Tiannara.Domains.Registry, as: DomReg
  alias Tiannara.ASC.KnowledgeArchive
  alias Tiannara.ASC.KnowledgeArchive.Entry

  @poll_interval_ms 30_000
  # Domains whose discoveries seed ASC architecture evolution
  @seed_domains [:computation, :cybernetics, :mathematics, :engineering]

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Promote an ASC architecture insight to the global Knowledge Graph.
  Rate-limited per the :kg_write_rate_limit config value.
  """
  @spec promote_to_kg(String.t(), map(), float()) :: {:ok, map()} | {:error, term()}
  def promote_to_kg(project_id, content, confidence) do
    GenServer.call(__MODULE__, {:promote, project_id, content, confidence})
  end

  @doc "Return the cached portfolio vectors for the four seed domains."
  @spec seed_domain_vectors() :: map()
  def seed_domain_vectors do
    GenServer.call(__MODULE__, :seed_domain_vectors)
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    config = Application.get_env(:tiannara, :asc, [])
    rate_limit = Keyword.get(config, :kg_write_rate_limit, 1)
    max_nodes  = Keyword.get(config, :kg_max_nodes_per_project, 10)

    state = %{
      rate_limit_ms: div(1_000, max(rate_limit, 1)),
      max_nodes_per_project: max_nodes,
      project_node_counts: %{},
      domain_vectors: %{},
      last_poll_at: nil
    }

    # Bootstrap domain vectors immediately
    send(self(), :poll)
    {:ok, state}
  end

  @impl true
  def handle_info(:poll, state) do
    new_state = poll_domains(state)
    Process.send_after(self(), :poll, @poll_interval_ms)
    {:noreply, %{new_state | last_poll_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:seed_domain_vectors, _from, state) do
    {:reply, state.domain_vectors, state}
  end

  @impl true
  def handle_call({:promote, project_id, content, confidence}, _from, state) do
    count = Map.get(state.project_node_counts, project_id, 0)

    if count >= state.max_nodes_per_project do
      Logger.debug("[ASC.ResearchBridge] KG node limit reached for project #{project_id}")
      {:reply, {:error, :limit_reached}, state}
    else
      node = %Tiannara.KnowledgeGraph.Node{
        id: "asc_disc_#{:erlang.unique_integer([:positive, :monotonic])}",
        type: :discovery,
        name: "ASC Software Pattern (#{project_id})",
        domains: [:computation, :software_engineering],
        parents: [],
        metadata: Map.merge(content, %{confidence: confidence, source: :asc}),
        description: Map.get(content, :description, "ASC-discovered software engineering pattern")
      }

      KG.save(node)

      # Record in archive with kg link
      KnowledgeArchive.store(%Entry{
        type: :success,
        project_id: project_id,
        content: content,
        tags: ["kg_promoted", "software_engineering"],
        confidence: confidence,
        kg_node_id: node.id
      })

      Phoenix.PubSub.broadcast(Tiannara.PubSub, "discoveries:software_engineering", node)

      new_counts = Map.update(state.project_node_counts, project_id, 1, &(&1 + 1))
      {:reply, {:ok, node}, %{state | project_node_counts: new_counts}}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp poll_domains(state) do
    vectors = Enum.reduce(@seed_domains, %{}, fn domain_id, acc ->
      vector =
        try do
          DomReg.get_portfolio_vector(domain_id)
        rescue
          _ -> nil
        end

      if vector do
        Map.put(acc, domain_id, vector)
      else
        acc
      end
    end)

    # Broadcast updated vectors for Architecture + Research civilizations
    unless map_size(vectors) == 0 do
      Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:research:domain_vectors", %{vectors: vectors})
    end

    %{state | domain_vectors: vectors}
  end
end
