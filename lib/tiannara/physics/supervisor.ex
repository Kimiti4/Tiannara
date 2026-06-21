defmodule Tiannara.Physics.Supervisor do
  @moduledoc """
  Physics compilation and reflection supervisor.

  Manages OPC, ACF, and CCR subsystems.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Observer physics compilation
      {Tiannara.Physics.OPC.Supervisor, []},

      # Negentropic dynamics
      {Tiannara.Physics.NDE.Supervisor, []},

      # Temporal waveform processing
      {Tiannara.Physics.TWP.Supervisor, []},

      # Intervention resonance dampening
      {Tiannara.Physics.IRD.Supervisor, []}
    ]

    Logger.info("Initializing physics compilation supervisor")

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 45)
  end
end