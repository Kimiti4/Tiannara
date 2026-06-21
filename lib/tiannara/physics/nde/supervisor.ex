defmodule Tiannara.Physics.NDE.Supervisor do
  @moduledoc """
  NDE (Negentropic Differentiation Engine) supervisor.

  Coordinates negentropic processes, chaos reduction, and order creation mechanisms.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Main NDE system
      {Tiannara.Physics.NDE, []},
      
      # Chaos analyzer
      {Tiannara.Physics.NDE.ChaosAnalyzer, []},
      
      # Differentiation engine
      {Tiannara.Physics.NDE.DifferentiationEngine, []},
      
      # Negentropy calculator
      {Tiannara.Physics.NDE.NegentropyCalculator, []},
      
      # Pattern optimizer
      {Tiannara.Physics.NDE.PatternOptimizer, []}
    ]

    Logger.info("Initializing NDE supervisor")

    Supervisor.init(children, strategy: :one_for_all, max_restarts: 5, max_seconds: 10)
  end
end