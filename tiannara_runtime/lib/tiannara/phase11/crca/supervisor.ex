defmodule Tiannara.Phase11.CRCA.Supervisor do
  @moduledoc """
  Cross-Reality Causal Arbitration (CRCA) Supervisor.
  [Original Concept: Temporal Boundary Harmonization Engine]
  
  Coordinates cross-partition temporal alignment, multi-history DAG synchronization,
  paradox resolution, and causal monotonicity enforcement.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase11_crca_nats
  @stream "crca_arbitration_events"

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
      subjects: ["tiannara.crca.harmonize.>", "tiannara.crca.sync.*"],
      max_msgs: 2_000_000
    )

    children = [
      {Tiannara.Phase11.CRCA.TemporalHarmonizer, [connection_name: @nats_conn]},
      {Tiannara.Phase11.CRCA.MultiHistorySync, [connection_name: @nats_conn]},
      {Tiannara.Phase11.CRCA.ParadoxResolver, []},
      {Tiannara.Phase11.CRCA.BoundaryAllocator, [connection_name: @nats_conn]},
      {Tiannara.Phase11.CRCA.NativeBridge, []},
      {Tiannara.Phase11.CRCA.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Submit cross-reality temporal arbitration request"
  @spec request_arbitration(partition_a :: String.t(), partition_b :: String.t(), context :: map()) :: 
    {:ok, arbitration_id :: String.t()} | {:error, String.t()}
  def request_arbitration(a, b, context), 
    do: Tiannara.Phase11.CRCA.TemporalHarmonizer.initiate_alignment(a, b, context)
end