defmodule Tiannara.World.SourceAdapter do
  @moduledoc """
  Source Adapter Behaviour — the contract for subsystem state adapters.

  Each existing subsystem (Core.WorldModel, OS.State, CCI.CivilizationState,
  ASC.State, etc.) must implement an adapter that exposes its state in a
  canonical format for the WorldIntegrationCoordinator.

  This enables:
    - Pluggable state sources
    - Independent replacement of subsystems
    - Gradual migration from fragmented to unified state
    - No coupling between coordinator and subsystem internals
  """

  @type entity :: %{
          id: String.t(),
          type: atom(),
          subtype: atom() | nil,
          attributes: map(),
          confidence: float(),
          uncertainty: float(),
          provenance: map() | nil,
          relationships: [map()]
        }

  @doc "Returns the unique identifier for this source."
  @callback source_id() :: atom()

  @doc """
  Pulls state from the subsystem.

  `opts` contains adapter-specific options.
  `since_version` enables incremental sync.

  Returns:
    - {:ok, %{entities: [entity], version: String.t(), changes_only: boolean()}}
    - {:error, reason}
  """
  @callback pull_state(opts :: map(), since_version :: String.t() | nil) ::
              {:ok, %{entities: [entity()], version: String.t(), changes_only: boolean()}}
              | {:error, term()}

  @doc """
  Pushes a state change back to the subsystem (for bidirectional sync).
  Optional — not all subsystems support writes.
  """
  @callback push_state(entity :: entity(), opts :: map()) :: :ok | {:error, term()}

  @doc "Returns the current version of the subsystem's state."
  @callback current_version(opts :: map()) :: String.t()

  @doc "Returns metadata about the source (for observability)."
  @callback metadata() :: map()
end
