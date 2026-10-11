defmodule Tiannara.Sentinel.MathematicalEvidence do
  @moduledoc """
  Replayable mathematical/scientific memory for Sentinel.

  Records may be successful, false, failed, inconclusive, superseded or
  rejected. Retaining a failed reasoning chain is intentional: it is evidence
  about how a hypothesis was formed and where it failed, not evidence that the
  hypothesis was true.
  """

  use GenServer

  @type record :: %{
          id: String.t(),
          kind: atom(),
          statement: term(),
          artifact: term(),
          evidence: map(),
          status: atom(),
          assumptions: list(),
          provenance: map(),
          created_at: DateTime.t(),
          parent_ids: [String.t()],
          hash: String.t()
        }

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  def init(_opts), do: {:ok, %{records: %{}, sequence: 0, previous_hash: "GENESIS"}}

  def store(attrs) when is_map(attrs) do
    with :ok <- validate(attrs) do
      GenServer.call(__MODULE__, {:store, attrs})
    end
  end

  def get(id) when is_binary(id), do: GenServer.call(__MODULE__, {:get, id})
  def list, do: GenServer.call(__MODULE__, :list)
  def by_status(status), do: GenServer.call(__MODULE__, {:by_status, status})
  def lineage(id), do: GenServer.call(__MODULE__, {:lineage, id})
  def verify_chain, do: GenServer.call(__MODULE__, :verify_chain)

  def handle_call({:store, attrs}, _from, state) do
    id = Map.get(attrs, :id, "math-evidence-#{state.sequence + 1}")
    if Map.has_key?(state.records, id) do
      {:reply, {:error, :duplicate_evidence_id}, state}
    else
      parents = Map.get(attrs, :parent_ids, [])
      with :ok <- validate_parents(parents, state.records) do
        record0 = %{
          id: id,
          kind: attrs.kind,
          statement: attrs.statement,
          artifact: attrs.artifact,
          evidence: Map.get(attrs, :evidence, %{}),
          status: attrs.status,
          assumptions: Map.get(attrs, :assumptions, []),
          provenance: Map.get(attrs, :provenance, %{}),
          created_at: Map.get(attrs, :created_at, DateTime.utc_now()),
          parent_ids: parents
        }

        hash = hash_record(record0, state.previous_hash)
        record = Map.put(record0, :hash, hash)
        new_state = %{state |
          records: Map.put(state.records, id, record),
          sequence: state.sequence + 1,
          previous_hash: hash
        }
        {:reply, {:ok, record}, new_state}
      end
    end
  end

  def handle_call({:get, id}, _from, state) do
    case Map.fetch(state.records, id) do
      {:ok, record} -> {:reply, {:ok, record}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:list, _from, state), do: {:reply, Map.values(state.records), state}

  def handle_call({:by_status, status}, _from, state) do
    {:reply, Enum.filter(Map.values(state.records), &(&1.status == status)), state}
  end

  def handle_call({:lineage, id}, _from, state) do
    {:reply, lineage_for(id, state.records, MapSet.new()), state}
  end

  def handle_call(:verify_chain, _from, state) do
    records = state.records |> Map.values() |> Enum.sort_by(& &1.id)
    {:reply, verify_records(records), state}
  end

  defp lineage_for(id, records, seen) do
    if MapSet.member?(seen, id) do
      []
    else
      case Map.get(records, id) do
        nil -> []
        record ->
          [record | Enum.flat_map(record.parent_ids, &lineage_for(&1, records, MapSet.put(seen, id)))]
      end
    end
  end

  defp validate_parents(parents, records) do
    if Enum.all?(parents, &Map.has_key?(records, &1)), do: :ok,
      else: {:error, :unknown_parent_evidence}
  end

  defp hash_record(record, previous_hash) do
    :crypto.hash(:sha256, :erlang.term_to_binary({previous_hash, record}))
    |> Base.encode16(case: :lower)
  end

  defp verify_records([]), do: :ok
  defp verify_records(records) do
    Enum.reduce_while(records, "GENESIS", fn record, previous ->
      expected = hash_record(Map.delete(record, :hash), previous)
      if expected == record.hash, do: {:cont, record.hash}, else: {:halt, {:error, {:hash_mismatch, record.id}}}
    end)
    |> case do
      {:error, _} = error -> error
      _ -> :ok
    end
  end

  defp validate(attrs) do
    with :ok <- require_field(attrs, :kind),
         :ok <- require_field(attrs, :statement),
         :ok <- require_field(attrs, :artifact),
         :ok <- require_field(attrs, :status),
         :ok <- validate_kind(attrs.kind),
         :ok <- validate_status(attrs.kind, attrs.status) do
      :ok
    end
  end

  defp require_field(attrs, key), do: if(Map.has_key?(attrs, key), do: :ok, else: {:error, {:missing_field, key}})
  defp validate_kind(kind) when kind in [:theorem, :proof, :counterexample_search, :mathematical_test, :scientific_reasoning], do: :ok
  defp validate_kind(_), do: {:error, :invalid_mathematical_evidence_kind}
  defp validate_status(:proof, status) when status in [:candidate, :proven_under_assumptions, :rejected, :refuted, :superseded], do: :ok
  defp validate_status(:theorem, status) when status in [:conjecture, :proven_under_assumptions, :refuted, :superseded], do: :ok
  defp validate_status(:counterexample_search, status) when status in [:counterexample_found, :no_counterexample_in_domain, :inconclusive], do: :ok
  defp validate_status(:mathematical_test, status) when status in [:passed, :failed, :inconclusive], do: :ok
  defp validate_status(:scientific_reasoning, status) when status in [:candidate, :supported, :refuted, :inconclusive, :superseded], do: :ok
  defp validate_status(_, _), do: {:error, :invalid_mathematical_evidence_status}
end
