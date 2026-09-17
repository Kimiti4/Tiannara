defmodule TiannaraRuntime.CTL.Supervisor do
  @moduledoc """
  Phase 5F.6 — Causal Tensegrity Lattice (CTL) Supervisor

  Supervises the CTL engine and reconciliation workflow that maintains
  causal consistency across distributed reality branches.
  """

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Logger.info("🧠 [CTL] Causal Tensegrity Lattice supervisor starting")

    children = [
      {TiannaraRuntime.CTL.Engine, []},
      {TiannaraRuntime.CTL.Reconciler, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
