defmodule Tiannara.HSV.Supervisor do
  @moduledoc """
  Top‑level HSV supervision branch.
  Starts the lightweight monitor and the optional warm‑pool manager.
  """
  use Supervisor

  def start_link(_opts) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_args) do
    children = [
      # Always‑on monitor (lightweight)
      {Tiannara.HSV.Monitor, []},
      # DynamicSupervisor that can pre‑populate a pool of SingularityVent workers
      {Tiannara.HSV.VentPool, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
