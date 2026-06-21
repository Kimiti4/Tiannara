defmodule Tiannara.Stabilization.Supervisor do
  @moduledoc """
  Stabilization layer supervisor.

  Manages all stabilization systems including HSV, CTL, OCM, TWP, OSL, NDE, RRG, IRD, and DFG.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Base stabilization layers
      {Tiannara.Stabilization.HSV.Supervisor, []},
      {Tiannara.Stabilization.OCM.Supervisor, []},
      {Tiannara.Stabilization.OLEF.Supervisor, []}
    ]

    Logger.info("Initializing stabilization layer supervisor")

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 15, max_seconds: 60)
  end
end