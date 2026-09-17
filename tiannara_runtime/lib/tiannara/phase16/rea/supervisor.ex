defmodule Tiannara.Phase16.REA.Supervisor do
  @moduledoc """
  Recursive Epistemic Arbitration (REA) Supervisor.
  [Original Concept: Cross-Domain Axiom Harmonization & Unified Constraint Resolution]
  
  Maps incompatible domain axioms into a unified constraint hypergraph.
  Resolves conflicts via recursive fixed-point iteration with rollback guarantees.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase16_rea_nats
  @stream "rea_arbitration_events"

  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    {:ok, _} = Gnat.start_link(%{
      name: @nats_conn,
      host: System.get_env("NATS_HOST", "nats"),
      port: String.to_integer(System.get_env("NATS_PORT", "4222"))
    })

    TiannaraRuntime.NATS.JetStreamHelper.ensure_stream(@nats_conn,
      name: @stream,
      subjects: ["tiannara.phase16.rea.arbitrate.*", "tiannara.phase16.rea.harmonized.*"],
      max_msgs: 1_000_000
    )

    children = [
      {Tiannara.Phase16.REA.DomainRegistry, []},
      {Tiannara.Phase16.REA.ConstraintUnifier, []},
      {Tiannara.Phase16.REA.ArbitrationLoop, [connection_name: @nats_conn]},
      {Tiannara.Phase16.REA.ConflictResolver, []},
      {Tiannara.Phase16.REA.ConvergenceMonitor, []},
      {Tiannara.Phase16.REA.NativeBridge, []},
      {Tiannara.Phase16.REA.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Initiate cross-domain arbitration for a set of axioms"
  @spec arbitrate(domains :: [atom()], axiom_maps :: map()) :: 
    {:ok, harmonization_id :: String.t()} | {:error, String.t()}
  def arbitrate(domains, axioms), 
    do: Tiannara.Phase16.REA.ArbitrationLoop.start_harmonization(domains, axioms)
end