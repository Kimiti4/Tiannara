defmodule Tiannara.Phase14.REG.Supervisor do
  @moduledoc """
  Recursive Epistemic Generation Engine (REG) Supervisor.
  [Original Concept: Continuous Axiom/Math Framework Evolution]
  
  Generates novel axiomatic systems within bounded drift & consistency thresholds.
  Routes validated frameworks to Phase 9 MES, Phase 10 MEN, and 6F Federation.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase14_reg_nats
  @stream "reg_epistemic_stream"

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
      subjects: ["tiannara.reg.generate.*", "tiannara.reg.compiled.*"],
      max_msgs: 1_000_000
    )

    children = [
      {Tiannara.Phase14.REG.GenerationLoop, [connection_name: @nats_conn]},
      {Tiannara.Phase14.REG.ConsistencyProver, []},
      {Tiannara.Phase14.REG.DriftController, []},
      {Tiannara.Phase14.REG.FederationPublisher, [connection_name: @nats_conn]},
      {Tiannara.Phase14.REG.NativeBridge, []},
      {Tiannara.Phase14.REG.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Initiate recursive epistemic generation cycle"
  @spec initiate_generation(domain :: atom(), base_axioms :: map()) :: 
    {:ok, generation_id :: String.t()} | {:error, String.t()}
  def initiate_generation(domain, base), 
    do: Tiannara.Phase14.REG.GenerationLoop.start_cycle(domain, base)
end