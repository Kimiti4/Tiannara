defmodule Tiannara.Sentinel.DiscoveryEvidenceArchive do
  @moduledoc """
  Content-addressed, append-only archive for discovery verification evidence.

  Records are immutable: an existing hash can never be replaced with different
  content. The archive is DETS-backed so the evidence survives process restart.
  """

  use GenServer

  @table :tiannara_discovery_evidence_archive
  @default_file "data/discovery_evidence_archive.dets"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  def append(record, parents \\ []) when is_map(record) and is_list(parents) do
    ensure_started()
    GenServer.call(__MODULE__, {:append, record, parents})
  end

  def get(hash) do
    ensure_started()
    GenServer.call(__MODULE__, {:get, hash})
  end

  def all do
    ensure_started()
    GenServer.call(__MODULE__, :all)
  end

  def verify(hash) do
    ensure_started()
    GenServer.call(__MODULE__, {:verify, hash})
  end

  @impl true
  def init(opts) do
    path = Keyword.get(opts, :file, Application.get_env(:tiannara, :discovery_evidence_archive_file, @default_file))
    File.mkdir_p!(Path.dirname(path))
    case :dets.open_file(@table, type: :set, file: String.to_charlist(path), repair: true) do
      {:ok, _} -> {:ok, %{path: path}}
      {:error, reason} -> {:stop, {:archive_open_failed, reason}}
    end
  end

  @impl true
  def handle_call({:append, record, parents}, _from, state) do
    with :ok <- validate_record(record),
         :ok <- validate_parents(parents),
         {:ok, archived} <- build_record(record, parents),
         :ok <- insert_immutable(archived) do
      {:reply, {:ok, archived}, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:get, hash}, _from, state) do
    reply = case :dets.lookup(@table, hash) do
      [{^hash, record}] -> {:ok, record}
      [] -> {:error, :archive_not_found}
    end
    {:reply, reply, state}
  end

  def handle_call(:all, _from, state) do
    records = :dets.traverse(@table, fn {_hash, record} -> {:continue, record} end)
    {:reply, records, state}
  end

  def handle_call({:verify, hash}, _from, state) do
    {:reply, verify_archive_chain(hash, MapSet.new()), state}
  end

  defp build_record(record, parents) do
    parent_hashes = Enum.map(parents, &Map.get(&1, :hash))
    canonical = Map.drop(record, [:hash, :archived_at])
    hash = :crypto.hash(:sha256, :erlang.term_to_binary({parent_hashes, canonical}))
      |> Base.encode16(case: :lower)
    {:ok, Map.merge(record, %{hash: hash, parent_hashes: parent_hashes, archived_at: DateTime.utc_now(), archive_status: :append_only})}
  end

  defp hash_record(record) do
    parent_hashes = Map.get(record, :parent_hashes, [])
    canonical = Map.drop(record, [:hash, :archived_at, :archive_status, :parent_hashes])
    :crypto.hash(:sha256, :erlang.term_to_binary({parent_hashes, canonical}))
    |> Base.encode16(case: :lower)
  end

  defp insert_immutable(record) do
    hash = record.hash
    case :dets.lookup(@table, hash) do
      [] -> :dets.insert(@table, {hash, record})
      [{^hash, ^record}] -> :ok
      [{^hash, _}] -> {:error, :immutable_archive_conflict}
    end
  end

  defp validate_record(record) do
    required = [:id, :kind, :status, :artifact, :provenance]
    case Enum.find(required, &(not Map.has_key?(record, &1))) do
      nil -> :ok
      key -> {:error, {:missing_archive_field, key}}
    end
  end

  defp validate_parents(parents) do
    Enum.reduce_while(parents, :ok, fn parent, :ok ->
      cond do
        not is_map(parent) or not is_binary(Map.get(parent, :hash)) ->
          {:halt, {:error, :invalid_parent_evidence}}

        true ->
          case verify_archive_chain(parent.hash, MapSet.new()) do
            :ok -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, {:invalid_parent_archive, parent.hash, reason}}}
          end
      end
    end)
  end

  # Verify the entire immutable ancestry, not merely the leaf's content hash.
  # A leaf remains invalid if any referenced parent is missing, corrupt, or
  # participates in a cycle.
  defp verify_archive_chain(hash, seen) when is_binary(hash) do
    cond do
      MapSet.member?(seen, hash) ->
        {:error, {:archive_parent_cycle, hash}}

      true ->
        case :dets.lookup(@table, hash) do
          [{^hash, record}] ->
            if hash_record(record) != hash do
              {:error, :archive_hash_mismatch}
            else
              parents = Map.get(record, :parent_hashes, [])
              next_seen = MapSet.put(seen, hash)

              Enum.reduce_while(parents, :ok, fn parent_hash, :ok ->
                case verify_archive_chain(parent_hash, next_seen) do
                  :ok -> {:cont, :ok}
                  {:error, reason} -> {:halt, {:error, {:invalid_parent_archive, parent_hash, reason}}}
                end
              end)
            end

          [] ->
            {:error, :archive_not_found}
        end
    end
  end

  defp verify_archive_chain(_hash, _seen), do: {:error, :invalid_archive_hash}

  defp ensure_started do
    case Process.whereis(__MODULE__) do
      nil ->
        case start_link([]) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
          {:error, reason} -> raise "discovery evidence archive unavailable: #{inspect(reason)}"
        end
      _ -> :ok
    end
  end
end
