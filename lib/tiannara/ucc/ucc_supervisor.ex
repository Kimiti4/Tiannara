defmodule Tiannara.UCC.UCCSupervisor do
  @moduledoc """
  Supervises the Universal Causal Compiler (UCC) subsystem.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Tiannara.UCC.MacroStateRegistry,
      Tiannara.UCC.ConstitutionAttractorRegistry
      # NATS Consumer would be added here once the NATS dependency is fully verified in the mix.exs
      # Tiannara.UCC.NATSConsumer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
