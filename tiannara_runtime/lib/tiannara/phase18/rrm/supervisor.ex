defmodule Tiannara.Phase18.RRM.Supervisor do
  @moduledoc """
  Recursive Runtime Metamorphosis (RRM) Supervisor.
  [Original Concept: Living Execution Surfaces & Self-Rewriting Compilation]
  
  Enables compiled surfaces to dynamically evolve lowering rules at runtime.
  Enforces bounded adaptation, equivalence preservation, and rollback guarantees.
  """
  use Supervisor
  require Logger

  @nats_conn :tiannara_phase18_rrm_nats
  @stream "rrm_metamorphosis_events"

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
      subjects: ["tiannara.phase18.rrm.propose.*", "tiannara.phase18.rrm.applied.*", "tiannara.phase18.rrm.rollback.*"],
      max_msgs: 1_000_000
    )

    children = [
      {Tiannara.Phase18.RRM.MetaIRGenerator, []},
      {Tiannara.Phase18.RRM.RuleEvolution, [connection_name: @nats_conn]},
      {Tiannara.Phase18.RRM.EquivalenceVerifier, []},
      {Tiannara.Phase18.RRM.AdaptationController, [connection_name: @nats_conn]},
      {Tiannara.Phase18.RRM.FallbackRouter, [connection_name: @nats_conn]},
      {Tiannara.Phase18.RRM.NativeBridge, []},
      {Tiannara.Phase18.RRM.Metrics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Initiate runtime metamorphosis for a compiled surface"
  @spec evolve_surface(surface_id :: String.t(), current_rules :: map(), metrics :: map()) :: 
    {:ok, proposal_id :: String.t()} | {:error, String.t()}
  def evolve_surface(id, rules, metrics), 
    do: Tiannara.Phase18.RRM.RuleEvolution.propose_evolution(id, rules, metrics)
end