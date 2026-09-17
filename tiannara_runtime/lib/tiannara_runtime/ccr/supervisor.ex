defmodule TiannaraRuntime.CCR.Supervisor do
  @moduledoc """
  Cosmological Compiler Reflection (CCR) Supervisor.
  
  Supervises the CCR trace graph recording and introspection subsystems.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🌌 [CCR] Supervisor starting")

    children = [
      {TiannaraRuntime.CCR.Tracker, []},
      {TiannaraRuntime.CCR.Bridge, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
