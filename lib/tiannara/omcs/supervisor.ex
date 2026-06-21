defmodule Tiannara.OMCS.Supervisor do
  @moduledoc """
  Supervisor for the Ontological Memory Continuity System (OMCS).
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.OMCS.Engine
    ]

    Logger.info("Initializing OMCS Supervisor")

    Supervisor.init(children, strategy: :one_for_one)
  end
end
