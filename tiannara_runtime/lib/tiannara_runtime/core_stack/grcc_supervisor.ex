defmodule Tiannara.GRCC.StateGeneratorSupervisor do
  @moduledoc """
  GRCC STATE GENERATION KERNEL
  
  Owned by Execution.Supervisor (under RootSupervisor).
  
  Generates ecological state identity lineages and state transitions.
  
  IMPORTANT: UniverseSupervisor (world/civilization state) is NOT started here.
  That is supervised directly by RootSupervisor → Ecology.Supervisor.
  
  This supervisor focuses on GRCC token generation and state machine evolution only.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # GRCC generates state identity lineages without starting Ecology or Constraint layers.
    # UniverseSupervisor and higher layers are started by RootSupervisor directly.
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
