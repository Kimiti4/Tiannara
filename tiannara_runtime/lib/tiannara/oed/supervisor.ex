defmodule Tiannara.OED.Supervisor do
  @moduledoc """
  🛡️ Main OED (Ontological Evolution & Defense) Supervisor.

  Orchestrates the lifecycles of all validation, quarantine, rollback,
  crucible, and budget tracking child services.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Logger.info("🛡️ [OED] Booting Ontological Evolution & Defense Safety Membrane...")

    children = [
      # 1. Budget tracking infrastructure
      {Tiannara.OED.BudgetController, opts},

      # 2. Quarantine registries and trackers
      Tiannara.OED.Quarantine.ContradictionTracker,
      Tiannara.OED.Quarantine.SuspendedTheories,
      Tiannara.OED.Quarantine.QuarantineRegistry,

      # 3. Rollback safety managers and snapshots
      Tiannara.OED.Rollback.OntologySnapshots,
      Tiannara.OED.Rollback.RollbackController,

      # 4. Universal Meta-Stability Controller
      Tiannara.OED.UMSC.StabilityController,

      # 5. Specialized Subsystem Supervisors
      Tiannara.OED.ACM.CrucibleSupervisor,
      Tiannara.OED.OAVL.ValidationSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
