defmodule Tiannara.Phase10.MEN.Supervisor do
  @moduledoc """
  Meta-Existence Negotiation (MEN) Supervisor.
  [Original Concept: Meta-Reality Negotiation Lattice]
  
  Coordinates cross-axiomatic arbitration, compatibility surface allocation,
  distributed quorum validation, and causal latency enforcement.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase10_men_nats
  @stream "men_negotiation_events"

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
      subjects: ["tiannara.men.arbitrate.>", "tiannara.men.quorum.*"],
      max_msgs: 2_000_000
    )

    children = [
      {Tiannara.Phase10.MEN.NegotiationEngine, [connection_name: @nats_conn]},
      {Tiannara.Phase10.MEN.CompatibilitySurface, [connection_name: @nats_conn]},
      {Tiannara.Phase10.MEN.ConflictResolver, []},
      {Tiannara.Phase10.MEN.ConsensusQuorum, [connection_name: @nats_conn]},
      {Tiannara.Phase10.MEN.LatencyValidator, []},
      {Tiannara.Phase10.MEN.NativeBridge, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Submit cross-partition negotiation request"
  @spec initiate_negotiation(partition_a :: String.t(), partition_b :: String.t(), context :: map()) :: 
    {:ok, negotiation_id :: String.t()} | {:error, String.t()}
  def initiate_negotiation(a, b, context), 
    do: Tiannara.Phase10.MEN.NegotiationEngine.request_arbitration(a, b, context)
end