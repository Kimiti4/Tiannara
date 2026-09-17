defmodule Tiannara.Phase8.RTL.Supervisor do
  @moduledoc "Root supervisor for Phase 8 Recursive Transcendence Layer"
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase8_rtl_nats

  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, _} = Gnat.start_link(%{
      name: @nats_conn,
      host: System.get_env("NATS_HOST", "nats"),
      port: String.to_integer(System.get_env("NATS_PORT", "4222"))
    })

    children = [
      {Tiannara.Phase8.RTL.Kernel, [connection_name: @nats_conn]},
      {Tiannara.Phase8.RTL.UniversalRepresentation, []},
      {Tiannara.Phase8.RTL.MetaSynthesis, [connection_name: @nats_conn]},
      {Tiannara.Phase8.RTL.ObserverDissolution, []},
      {Tiannara.Phase8.RTL.TransfiniteCoherence, [connection_name: @nats_conn]},
      {Tiannara.Phase8.RTL.ExistenceCompiler, []},
      {Tiannara.Phase8.RTL.Hypertopology, []},
      {Tiannara.Phase8.RTL.IdentityPersistence, []},
      {Tiannara.Phase8.RTL.DivergenceHarmonizer, [connection_name: @nats_conn]},
      {Tiannara.Phase8.RTL.MetaRealityNegotiation, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end