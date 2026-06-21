defmodule Tiannara.Physics.IRD.Supervisor do
  @moduledoc """
  IRD (Intervention Resonance Dampener) supervisor.

  Coordinates resonance dampening, distributed intervention management, and NATS/JetStream integration.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main IRD system
      {Tiannara.Physics.IRD, []},
      
      # Resonance calculator
      {Tiannara.Physics.IRD.ResonanceCalculator, []},
      
      # Dampening engine
      {Tiannara.Physics.IRD.DampeningEngine, []},
      
      # Coordinator
      {Tiannara.Physics.IRD.Coordinator, []},
      
      # NATS/JetStream integration
      {Tiannara.Physics.IRD.NATSIntegration, []}
    ]

    Logger.info("Initializing IRD supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end