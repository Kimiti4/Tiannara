defmodule ObservationBus.Event do
  @moduledoc """
  The canonical constitutional event struct.

  Every event in the Tiannara ecosystem conforms to this structure
  when flowing through the Constitutional Observation Bus.

  ## Constitutional properties

    * **Observable** — every event is emitted and traceable
    * **Replayable** — every event carries replay metadata
    * **Immutable** — events are never mutated after creation
    * **Addressable** — every event has a globally unique ID
    * **Certifiable** — every event carries evidence and optional certificate
    * **Composable** — events can be merged, split, and aggregated
    * **Auditable** — full lineage and source tracking
    * **Lineage-preserving** — parent/cause/evidence chains
    * **Deterministic** — ordering sequences guarantee consistency
    * **Distributed** — events are designed for multi-node propagation
  """

  @typedoc """
  The event's priority within the constitutional hierarchy.
  """
  @type priority :: 10..100

  @typedoc """
  The event lifecycle stage.
  """
  @type stage :: :created | :validated | :canonicalized | :certified | :ordered | :routed | :observed | :stored | :replayed | :archived

  @typedoc """
  The fully-typed Constitutional Event.
  """
  @type t :: %__MODULE__{
    id: String.t(),
    lineage: String.t() | nil,
    timestamp: DateTime.t(),
    generation: non_neg_integer(),
    runtime: String.t(),
    constitution: String.t(),
    domain: String.t(),
    source: String.t(),
    destination: String.t(),
    priority: priority(),
    payload: term(),
    evidence: list(String.t()),
    replay_hash: String.t() | nil,
    certificate: String.t() | nil,
    global_sequence: non_neg_integer() | nil,
    local_sequence: non_neg_integer() | nil,
    replay_sequence: non_neg_integer() | nil,
    causal_sequence: non_neg_integer() | nil,
    parent_id: String.t() | nil,
    cause_id: String.t() | nil,
    stage: stage(),
    signature: String.t() | nil,
    metadata: map()
  }

  defstruct [
    :id, :lineage, :timestamp, :generation, :runtime, :constitution,
    :domain, :source, :destination, :payload,
    :replay_hash, :certificate,
    :global_sequence, :local_sequence, :replay_sequence, :causal_sequence,
    :parent_id, :cause_id, :signature,
    priority: 20,
    evidence: [],
    stage: :created,
    metadata: %{}
  ]

  @doc """
  Creates a new Constitutional Event with auto-populated fields.

  Required fields: `domain`, `source`, `payload`.

  Auto-populated: `id` (UUID), `timestamp`, `stage`, `constitution`.
  """
  @spec new(keyword()) :: t()
  def new(fields \\ []) do
    now = DateTime.utc_now()

    struct!(__MODULE__, [
      id: fields[:id] || uuid_v4(),
      lineage: fields[:lineage],
      timestamp: fields[:timestamp] || now,
      generation: fields[:generation] || 0,
      runtime: fields[:runtime] || "unknown",
      constitution: fields[:constitution] || "1.0.0",
      domain: fields[:domain],
      source: fields[:source],
      destination: fields[:destination] || "broadcast",
      priority: fields[:priority] || 20,
      payload: fields[:payload] || %{},
      evidence: List.wrap(fields[:evidence]),
      replay_hash: fields[:replay_hash],
      certificate: fields[:certificate],
      parent_id: fields[:parent_id],
      cause_id: fields[:cause_id],
      stage: :created,
      metadata: fields[:metadata] || %{}
    ])
  end

  @doc """
  Returns the canonical topic string for this event.

  Pattern: `constitution.<domain>.<action>` where action is derived
  from the payload's `:action` key or defaults to `"event"`.
  """
  def topic(%__MODULE__{domain: domain} = event) do
    action = Map.get(event.payload, :action, "event")
    "constitution.#{domain}.#{action}"
  end

  @doc """
  Advances the event to the next lifecycle stage.
  """
  def advance(%__MODULE__{} = event, next_stage) do
    %{event | stage: next_stage}
  end

  defp uuid_v4 do
    <<a::64, b::64>> = :crypto.strong_rand_bytes(16)
    <<u1::48, _::4, u2::12, _::2, u3::62>> = <<a::64, b::64>>
    <<u1::48, 4::4, u2::12, 2::2, u3::62>>
    |> Base.encode16(case: :lower)
    |> then(fn s ->
      "#{String.slice(s, 0, 8)}-#{String.slice(s, 8, 4)}-#{String.slice(s, 12, 4)}-#{String.slice(s, 16, 4)}-#{String.slice(s, 20, 12)}"
    end)
  end
end
