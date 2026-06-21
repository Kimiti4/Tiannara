defmodule Tiannara.ASC.Pipeline.Phases do
  @moduledoc """
  Defines the 10-phase ASC project pipeline and the valid state transitions.

  ## Phase Ordering

  The Testing phase runs **before** Implementation. This is intentional:
  ASC first learns "what success looks like" (TestContracts from invariants and
  capabilities), then writes code that satisfies those contracts.

      requirements → research → architecture → testing → implementation
          → crucible → api_evolution → deployment → operations → completed

  Phases can loop back:
  - Crucible failure → Implementation (rework)
  - Operations anomaly → Repair → Operations

  ## Handlers

  Each phase atom maps to a sub-civilization module via `handler/1`.
  The `Pipeline.Worker` calls `handler_module.run(project)` for each phase.
  """

  @phases [
    :requirements,
    :research,
    :architecture,
    :testing,        # ← Testing before Implementation: define success criteria first
    :implementation,
    :crucible,
    :api_evolution,
    :deployment,
    :operations,
    :completed
  ]

  @transitions %{
    requirements:   [:research, :failed],
    research:       [:architecture, :failed],
    architecture:   [:testing, :failed],
    testing:        [:implementation, :failed],          # ← Testing gates Implementation
    implementation: [:crucible, :failed],
    crucible:       [:api_evolution, :implementation, :failed],  # failure → back to implementation
    api_evolution:  [:deployment, :failed],
    deployment:     [:operations, :failed],
    operations:     [:completed, :repair],
    repair:         [:operations, :failed],
    completed:      [],
    failed:         []
  }

  @type phase ::
    :requirements | :research | :architecture | :testing | :implementation
    | :crucible | :api_evolution | :deployment | :operations
    | :repair | :completed | :failed

  @doc "Return the ordered list of phases."
  def all, do: @phases

  @doc "Return valid next phases from a given phase."
  @spec valid_transitions(phase()) :: [phase()]
  def valid_transitions(phase), do: Map.get(@transitions, phase, [])

  @doc "Check if a transition is valid."
  @spec valid_transition?(phase(), phase()) :: boolean()
  def valid_transition?(from, to) do
    to in valid_transitions(from)
  end

  @doc "Map each phase to the sub-civilization module that handles it."
  @spec handler(phase()) :: module() | nil
  def handler(:requirements),   do: Tiannara.ASC.Requirements.Civilization
  def handler(:research),       do: Tiannara.ASC.Research.Civilization
  def handler(:architecture),   do: Tiannara.ASC.Architecture.Civilization
  def handler(:testing),        do: Tiannara.ASC.Testing.Civilization
  def handler(:implementation), do: Tiannara.ASC.Implementation.Civilization
  def handler(:crucible),       do: Tiannara.ASC.Crucible.Supervisor
  def handler(:api_evolution),  do: Tiannara.ASC.APIEvolution.Civilization
  def handler(:deployment),     do: Tiannara.ASC.Deployment.Civilization
  def handler(:operations),     do: Tiannara.ASC.Operations.Civilization
  def handler(:repair),         do: nil   # triggered by operations anomaly
  def handler(:completed),      do: nil
  def handler(:failed),         do: nil
end
