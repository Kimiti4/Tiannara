defmodule Tiannara.Core.Ontology.Supervisor do
  @moduledoc """
  OMCE (Ontological Memory Compression Engine) supervisor.

  Coordinates ontology management, compression, and indexing.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main ontology manager
      {Tiannara.Core.Ontology, []},
      
      # Cache for compressed ontologies
      {Tiannara.Core.Ontology.Cache, []},
      
      # Index for fast concept lookup
      {Tiannara.Core.Ontology.Index, []},
      
      # Semantic vector management
      {Tiannara.Core.Ontology.Vector, []}
    ]

    Logger.info("Initializing OMCE supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end