defmodule Tiannara.OED.ACM.CrucibleSupervisor do
  @moduledoc """
  ⚔️ ACM Crucible Supervisor.

  Manages child validation and generator actors under the Adversarial Crucible Matrix.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("⚔️ [ACM Crucible] Booting Adversarial Crucible Matrix services...")

    children = [
      Tiannara.OED.ACM.CivilizationGenerator,
      Tiannara.OED.ACM.CivilizationDiscriminator,
      Tiannara.OED.ACM.ObserverExploitEngine,
      Tiannara.OED.ACM.LatentSimulation
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
