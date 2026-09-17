defmodule Tiannara.Phase15.SMCP.Supervisor do
  @moduledoc """
  Self-Modifying Consensus Protocol (SMCP) Supervisor.
  [Original Concept: Living Consensus & Adaptive Governance Layer]
  
  Dynamically adjusts federation consensus parameters within strict BFT bounds.
  Preserves safety, liveness, and rollback guarantees during runtime evolution.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase15_smcp_nats
  @stream "smcp_adaptation_stream"

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
      subjects: ["tiannara.smcp.propose.*", "tiannara.smcp.applied.*", "tiannara.smcp.rollback.*"],
      max_msgs: 500_000
    )

    children = [
      {Tiannara.Phase15.SMCP.RuleEvolution, [connection_name: @nats_conn]},
      {Tiannara.Phase15.SMCP.SafetyVerifier, []},
      {Tiannara.Phase15.SMCP.AdaptationEngine, [connection_name: @nats_conn]},
      {Tiannara.Phase15.SMCP.FallbackController, [connection_name: @nats_conn]},
      {Tiannara.Phase15.SMCP.NativeBridge, []},
      {Tiannara.Phase15.SMCP.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Trigger consensus adaptation evaluation cycle"
  @spec evaluate_adaptation(current_params :: map(), metrics :: map()) :: 
    {:ok, proposal_id :: String.t()} | {:error, String.t()}
  def evaluate_adaptation(params, metrics), 
    do: Tiannara.Phase15.SMCP.RuleEvolution.propose_adjustment(params, metrics)
end