defmodule Tiannara.Phase19.TCL.Supervisor do
  @moduledoc """
  Transfinite Consensus Lattice (TCL) Supervisor.
  [Original Concept: Cross-Instance Rule Synchronization & Fixed-Point Adoption]
  
  Synchronizes evolved execution rules across distributed Tiannara instances.
  Enforces equivalence convergence, partition tolerance, and rollback guarantees.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase19_tcl_nats
  @stream "tcl_sync_events"

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
      subjects: ["tiannara.phase19.tcl.sync.*", "tiannara.phase19.tcl.adopt.*", "tiannara.phase19.tcl.rollback.*"],
      max_msgs: 1_000_000
    )

    children = [
      {Tiannara.Phase19.TCL.LatticeState, []},
      {Tiannara.Phase19.TCL.SyncPropagation, [connection_name: @nats_conn]},
      {Tiannara.Phase19.TCL.FixedPointVerifier, []},
      {Tiannara.Phase19.TCL.PartitionHandler, [connection_name: @nats_conn]},
      {Tiannara.Phase19.TCL.AdoptionController, [connection_name: @nats_conn]},
      {Tiannara.Phase19.TCL.FallbackRouter, [connection_name: @nats_conn]},
      {Tiannara.Phase19.TCL.NativeBridge, []},
      {Tiannara.Phase19.TCL.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Initiate cross-instance rule synchronization cycle"
  @spec initiate_sync(surface_id :: String.t(), local_rules :: map()) :: 
    {:ok, sync_id :: String.t()} | {:error, String.t()}
  def initiate_sync(id, rules), 
    do: Tiannara.Phase19.TCL.SyncPropagation.start_cycle(id, rules)
end