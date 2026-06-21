defmodule Tiannara.Core.Supervisor do
  @moduledoc """
  Core subsystem supervisor.

  Manages the foundational ontology and causality systems.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Ontology management
      {Tiannara.Core.Ontology.Cache, []},
      {Tiannara.Core.Ontology.Index, []}
    ]

    Logger.info("Initializing core subsystem supervisor")

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 30)
  end
end