defmodule Tiannara.Phase17.UCC.Supervisor do
  @moduledoc """
  Universal Constraint Compiler (UCC) Supervisor.
  [Original Concept: Substrate-Independent Execution Surface Generation]
  
  Compiles harmonized axioms into target-agnostic execution DAGs.
  Enforces resource bounds, execution equivalence, and fallback routing.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase17_ucc_nats
  @stream "ucc_compilation_events"

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
      subjects: ["tiannara.phase17.ucc.compile.*", "tiannara.phase17.ucc.surface.*", "tiannara.phase17.ucc.shard.*"],
      max_msgs: 1_000_000
    )

    children = [
      {Tiannara.Phase17.UCC.IRGenerator, []},
      {Tiannara.Phase17.UCC.ResourceAllocator, []},
      {Tiannara.Phase17.UCC.SurfaceCompiler, [connection_name: @nats_conn]},
      {Tiannara.Phase17.UCC.EquivalenceVerifier, []},
      {Tiannara.Phase17.UCC.FallbackRouter, [connection_name: @nats_conn]},
      {Tiannara.Phase17.UCC.NativeBridge, []},
      {Tiannara.Phase17.UCC.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Submit harmonized constraint hypergraph for compilation"
  @spec compile_constraints(harmonized_id :: String.t(), hypergraph :: map(), target :: atom()) :: 
    {:ok, surface_id :: String.t()} | {:error, String.t()}
  def compile_constraints(harm_id, graph, target), 
    do: Tiannara.Phase17.UCC.IRGenerator.start_compilation(harm_id, graph, target)
end