defmodule Tiannara.OPC.CoreSupervisor do
  @moduledoc """
  EXECUTION KERNEL ONLY
  
  Minimal execution substrate under RootSupervisor → Execution.Supervisor.
  Supervises GRCC state generation kernel only.
  
  Infrastructure (PubSub, NATS, etc.) and Telemetry are owned by Infrastructure.Supervisor.
  Interface/observability are owned by Infrastructure.Supervisor.
  
  Does NOT start Ecology, Constraint, or Meta layers—those are flat siblings under RootSupervisor.
  """
  use Supervisor
  use TiannaraRuntime.Layer, authority: :execution, can_call: [:ecology], can_receive: [:ecology, :constraint]

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # GRCC state generation kernel (supervision only; ecology state lives in UniverseSupervisor)
      {Tiannara.GRCC.StateGeneratorSupervisor, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
