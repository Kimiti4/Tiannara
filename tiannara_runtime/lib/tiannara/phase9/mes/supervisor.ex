defmodule Tiannara.Phase9.MES.Supervisor do
  @moduledoc """
  Meta-Existence Synthesis (MES) Supervisor.
  [Original Concept: Axiomatic Genesis Kernel]
  
  Coordinates novel axiom generation, consistency validation, existence compilation,
  and isolated deployment. Enforces substrate-independent representation boundaries.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase9_mes_nats
  @stream "mes_axiom_streams"

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
      subjects: ["tiannara.mes.axioms.>", "tiannara.mes.compiled.*"],
      max_msgs: 1_000_000
    )

    children = [
      {Tiannara.Phase9.MES.Kernel, [connection_name: @nats_conn]},
      {Tiannara.Phase9.MES.AxiomaticGenerator, []},
      {Tiannara.Phase9.MES.ConsistencyValidator, []},
      {Tiannara.Phase9.MES.ExistenceCompiler, [connection_name: @nats_conn]},
      {Tiannara.Phase9.MES.ContainmentSandbox, []},
      {Tiannara.Phase9.MES.RepresentationLayer, []},
      {Tiannara.Phase9.MES.NativeBridge, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Submit novel axiom generation request"
  @spec generate_axioms(params :: map()) :: {:ok, axiom_set_id :: String.t()} | {:error, String.t()}
  def generate_axioms(params), do: Tiannara.Phase9.MES.Kernel.request_generation(params)
end