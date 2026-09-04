defmodule Tiannara.Diagnostics.EventSource do
  @moduledoc """
  Read-only access to immutable soak artifacts.

  ISOLATION CONTRACT (Track A / P0):
    * MUST NOT write, mutate, delete, checkpoint, or reconfigure anything.
    * MUST NOT send messages / signals to the running soak.
    * MUST only stream already-flushed, immutable artifacts
      (telemetry snapshots, logs, checkpoints, reports).

  Real implementations should read from the existing immutable checkpoint
  path or an event-store READ replica. They must never open the live writer.

  This keeps the 72h soak a controlled experiment while still allowing
  evidence extraction (Track B).
  """

  @type stage ::
          :observations
          | :gaps
          | :hypotheses
          | :ranked_hypotheses
          | :experiments_proposed
          | :experiments_scheduled
          | :experiments_started
          | :experiments_completed
          | :evidence_generated
          | :knowledge_integrated
          | :discovery_candidates
          | :validated_discoveries

  @type disposition_kind :: :promoted | :rejected | :pending | :closed | :absorbed

  @type event ::
          {:created, stage(), id :: term(), parents :: [term()]}
          | {:disposition, stage(), id :: term(), disposition_kind(), detail :: term()}
          | {:meta, stage(), id :: term(), key :: atom(), value :: term()}

  @callback stream_events(source :: term(), opts :: keyword()) :: Enumerable.t()
end

defmodule Tiannara.Diagnostics.EventSource.Mock do
  @moduledoc """
  In-memory, immutable event source for tests and dry-runs.

  Never touches the soak. Used to validate the audit logic itself
  before wiring to the real read-only artifact stream.
  """
  @behaviour Tiannara.Diagnostics.EventSource

  defstruct events: []

  def new(events) when is_list(events), do: %__MODULE__{events: events}

  @impl true
  def stream_events(%__MODULE__{events: events}, _opts \\ []), do: events
end
