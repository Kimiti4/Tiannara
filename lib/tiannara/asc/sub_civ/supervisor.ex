defmodule Tiannara.ASC.SubCiv.Supervisor do
  @moduledoc """
  DynamicSupervisor that manages all sub-civilization supervisors.

  Sub-civilizations are started eagerly at boot (not on demand) so their
  PubSub subscriptions and ETS tables are ready before the first project
  arrives. Each sub-civilization supervisor uses :one_for_one so a crash
  in one sub-civilization agent does not propagate to others.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.ASC.Requirements.Supervisor,
      Tiannara.ASC.Research.Supervisor,
      Tiannara.ASC.Architecture.Supervisor,
      Tiannara.ASC.Implementation.Supervisor,
      Tiannara.ASC.Testing.Supervisor,
      # Tiannara.ASC.Crucible.Supervisor,  # TODO: Create Crucible supervisor
      Tiannara.ASC.APIEvolution.Supervisor,
      Tiannara.ASC.Deployment.Supervisor,
      Tiannara.ASC.Operations.Supervisor,
      Tiannara.ASC.MetaLearning.Supervisor,
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
