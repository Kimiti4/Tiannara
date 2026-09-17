defmodule Rbac.Audit.Ledger do
  @moduledoc """
  Immutable Audit Ledger — blockchain-linked, cryptographically signed.

  Every entry records:
    Actor → Intent → Action → Evidence → Decision → Result → SideEffects → ReplayHash → Signature

  Entries are linked in a chain via previous_hash, creating an immutable audit trail
  that supports replay, archaeology, and certification.
  """

  use GenServer
  alias Rbac.Audit.Entry

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(attrs) do
    GenServer.call(__MODULE__, {:record, attrs})
  end

  def get(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def list(opts \\ []) do
    GenServer.call(__MODULE__, {:list, opts})
  end

  def tail(n \\ 10) do
    GenServer.call(__MODULE__, {:tail, n})
  end

  def verify_chain do
    GenServer.call(__MODULE__, :verify_chain)
  end

  def chain_stats do
    GenServer.call(__MODULE__, :chain_stats)
  end

  @impl true
  def init(_opts) do
    genesis = Entry.genesis()
    {:ok, %{entries: %{genesis.id => genesis}, chain: [genesis], by_actor: %{}, by_resource: %{}}}
  end

  @impl true
  def handle_call({:record, attrs}, _from, state) do
    previous = List.last(state.chain)
    entry = Entry.new(attrs, previous)

    new_entries = Map.put(state.entries, entry.id, entry)
    new_chain = state.chain ++ [entry]

    by_actor = Map.update(state.by_actor, entry.actor, [entry.id], fn ids -> [entry.id | ids] end)

    by_resource =
      Map.update(state.by_resource, entry.resource, [entry.id], fn ids -> [entry.id | ids] end)

    {:reply, {:ok, entry},
     %{
       state
       | entries: new_entries,
         chain: new_chain,
         by_actor: by_actor,
         by_resource: by_resource
     }}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, Map.get(state.entries, id), state}
  end

  @impl true
  def handle_call({:tail, n}, _from, state) do
    {:reply, Enum.take(state.chain, -n), state}
  end

  @impl true
  def handle_call({:list, _opts}, _from, state) do
    {:reply, state.chain, state}
  end

  @impl true
  def handle_call(:verify_chain, _from, state) do
    result =
      Enum.reduce_while(state.chain, nil, fn entry, prev_hash ->
        if entry.previous_hash == prev_hash and Entry.verify(entry) do
          {:cont, entry.current_hash}
        else
          {:halt, {:chain_broken, entry.id}}
        end
      end)

    {:reply, if(result == nil, do: :empty_chain, else: {:ok, chain_intact: true}), state}
  end

  @impl true
  def handle_call(:chain_stats, _from, state) do
    {:reply,
     %{
       entry_count: length(state.chain),
       actors: map_size(state.by_actor),
       resources: map_size(state.by_resource)
     }, state}
  end
end

defmodule Rbac.Audit.Entry do
  @moduledoc "A single audit entry with cryptographic chain linkage."

  defstruct [
    :id,
    :timestamp,
    :actor,
    :intent,
    :action,
    :resource,
    :evidence,
    :decision,
    :result,
    :side_effects,
    :latency_ms,
    :request_id,
    :session_id,
    :runtime_generation,
    :constitution_version,
    :previous_hash,
    :current_hash,
    :signature,
    :delta,
    :metadata
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          timestamp: DateTime.t(),
          actor: String.t(),
          intent: String.t(),
          action: String.t(),
          resource: String.t(),
          evidence: String.t(),
          decision: String.t(),
          result: String.t(),
          side_effects: map(),
          latency_ms: non_neg_integer(),
          request_id: String.t(),
          session_id: String.t(),
          runtime_generation: non_neg_integer(),
          constitution_version: String.t(),
          previous_hash: String.t(),
          current_hash: String.t(),
          signature: String.t(),
          delta: [map()],
          metadata: map()
        }

  @genesis_id "00000000-0000-0000-0000-000000000000"

  def genesis do
    ts = ~U[2024-01-01 00:00:00Z]
    h = hash(%{id: @genesis_id, timestamp: ts, previous_hash: nil})

    %__MODULE__{
      id: @genesis_id,
      timestamp: ts,
      actor: "observatory",
      intent: "genesis",
      action: "GENESIS",
      resource: "chain",
      evidence: "Audit ledger genesis block",
      decision: "granted",
      result: "created",
      previous_hash: nil,
      current_hash: h,
      signature: sign(h),
      constitution_version: "1.0.0"
    }
  end

  def new(attrs, previous \\ nil) do
    now = DateTime.utc_now()
    prev_hash = if previous, do: previous.current_hash, else: nil

    entry = %__MODULE__{
      id: Ecto.UUID.generate(),
      timestamp: now,
      actor: attrs[:actor] || "unknown",
      intent: attrs[:intent] || "unspecified",
      action: attrs[:action] || "unknown",
      resource: attrs[:resource] || "unknown",
      evidence: attrs[:evidence] || "",
      decision: attrs[:decision] || "granted",
      result: attrs[:result] || "success",
      side_effects: attrs[:side_effects] || %{},
      latency_ms: attrs[:latency_ms] || 0,
      request_id: attrs[:request_id] || Ecto.UUID.generate(),
      session_id: attrs[:session_id] || "",
      runtime_generation: Application.get_env(:observatory_core, :generation, 1),
      constitution_version: "1.0.0",
      previous_hash: prev_hash,
      metadata: attrs[:metadata] || %{}
    }

    h = hash(entry)
    %{entry | current_hash: h, signature: sign(h)}
  end

  def verify(%__MODULE__{current_hash: h, signature: sig} = entry) do
    expected_hash = hash(%{entry | signature: nil, current_hash: nil})
    expected_sig = sign(expected_hash)
    h == expected_hash and sig == expected_sig
  end

  def hash(entry) do
    :crypto.hash(:sha256, :erlang.term_to_binary(entry))
    |> Base.encode16(case: :lower)
  end

  defp sign(data) do
    secret = Application.get_env(:observatory_core, :jwt_secret, "dev-secret")
    :crypto.mac(:hmac, :sha256, secret, data) |> Base.encode16(case: :lower)
  end
end
