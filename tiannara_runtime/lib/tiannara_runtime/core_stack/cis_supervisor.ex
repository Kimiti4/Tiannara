defmodule Tiannara.CIS.ConstraintEnforcementSupervisor do
  @moduledoc """
  CONSTRAINT LAYER KERNEL (DEPRECATED NESTED CHAIN)
  
  IMPORTANT: This supervisor is NO LONGER used for starting SafetyCortex or MetaSOPL.
  
  With the new flat authority architecture (RootSupervisor):
  - SafetyCortex is supervised by RootSupervisor → Constraint.Supervisor
  - MetaSOPL is supervised by RootSupervisor → Meta.Supervisor
  - CIS itself may contain constraint enforcement logic, but supervision is flat
  
  This module is retained for backward compatibility but starts no children.
  All constraint and meta supervision now flows directly from RootSupervisor.
  
  To be phased out: Move any CIS enforcement logic to Constraint.Supervisor role hierarchy.
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # No children: SafetyCortex and MetaSOPL are supervised by RootSupervisor directly
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
