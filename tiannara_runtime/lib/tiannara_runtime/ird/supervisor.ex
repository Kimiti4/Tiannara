defmodule TiannaraRuntime.IRD.Supervisor do
  @moduledoc """
  Phase 5F.12 — Intervention Resonance Dampener (IRD) Supervisor

  Supervises all IRD subsystems responsible for coordinating stabilizer
  proposals, computing interference matrices, managing phase scheduling,
  reserving compute budget, and issuing global quiescence windows.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🛡️ [IRD] Intervention Resonance Dampener supervisor starting")

    children = [
      {TiannaraRuntime.IRD.Consumer, []},
      {TiannaraRuntime.IRD.InterferenceMatrix, []},
      {TiannaraRuntime.IRD.PhaseScheduler, []},
      {TiannaraRuntime.IRD.BudgetController, []},
      {TiannaraRuntime.IRD.QuiescenceManager, []},
      {TiannaraRuntime.IRD.Feedback, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
