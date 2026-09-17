defmodule TiannaraRuntime.MSG.Supervisor do
  @moduledoc """
  Meta-Stability Governor (MSG) Supervisor.

  Supervises the MSG Governor that monitors and throttles stabilizer loops.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [MSG Supervisor] Starting MSG supervision tree")

    children = [
      {TiannaraRuntime.MSG.Governor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
