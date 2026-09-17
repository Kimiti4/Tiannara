defmodule TiannaraOS.Provenance.IdentityAuthority do
  @moduledoc """
  Canonical execution identity authority.

  Stage 1 of the forward provenance integration (Council-authorized). Exactly ONE
  authority decides what an `execution_id` names. Every execution id that enters
  the forward provenance universe must be MINTED through this authority (forward
  producers) or CLAIMED through it (adopted legacy producers). An id that two
  producers both consider theirs is a collision and is REJECTED.

  Semantics:
    * mint(producer)  -> new authority-controlled id, first-writer in the registry
    * claim(id, producer) -> :ok on first registration; {:error, :duplicate,
      %{existing record}} if the id already belongs to someone else. A repeat
      claim by ANY producer (including the same one) is a collision, because an
      execution id must name exactly one execution.
    * resolve(id) -> {:ok, record} | {:error, :unregistered}

  Concurrency:
    * authoritative uniqueness: an ETS named set table, insert_new is atomic
    * audit: one canonical-JSON line appended to the identity authority ledger
      (best-effort; the registry, not the ledger, is authoritative)
    * fail-closed: if the authority cannot guarantee uniqueness it returns an
      error, it never silently accepts a duplicate

  The registry answers `export/0` so the Stage 2 Runtime Contract can bind any
  execution id in a graph node to exactly one registered execution.
  """

  alias TiannaraOS.Provenance.{Canon, Identity}

  @table :tiannaraos_fp_identity_authority
  @authority "tiannara-fp-identity-v1"
  @max_mint_attempts 32
  @ledger_env :identity_authority_ledger_path

  @format_specs %{
    "forward_exec_v1" => "^exec_[0-9]{13}_[0-9a-f-]{13}$",
    "phase4_exec_v1" => "^exec_[0-9]{10,}_[0-9]+$",
    "opc_integer" => "^[0-9]+$"
  }

  @doc "Authority and id-format specification (machine-readable)."
  def spec do
    %{
      "authority" => @authority,
      "formats" => @format_specs,
      "first_writer_wins" => true,
      "duplicate_claim" => "reject"
    }
  end

  defp formats do
    case :persistent_term.get({__MODULE__, :formats}, nil) do
      nil ->
        compiled = Map.new(@format_specs, fn {k, v} -> {k, Regex.compile!(v)} end)
        :persistent_term.put({__MODULE__, :formats}, compiled)
        compiled

      compiled ->
        compiled
    end
  end

  @doc "Create the registry (idempotent) and load any persisted ledger entries."
  def ensure_started(opts \\ []) do
    case :ets.whereis(@table) do
      :undefined ->
        ledger = Keyword.get_lazy(opts, :ledger_path, &default_ledger_path/0)

        try do
          :ets.new(@table, [:named_table, :set, :public, {:read_concurrency, true}, {:write_concurrency, true}])
          :ets.insert(@table, {:__ledger_path, ledger})
          replay_ledger(ledger)
          :ok
        rescue
          ArgumentError ->
            if :ets.whereis(@table) == :undefined, do: raise("identity authority unavailable")
            :ok
        end

      _table ->
        :ok
    end
  end

  @doc "Mint a new authority-controlled execution id under `producer`."
  def mint(producer, opts \\ []) do
    ensure_started(opts)
    ledger = ledger_path(opts)
    producer = producer || "unknown_producer"
    claimed_at = DateTime.utc_now() |> DateTime.to_iso8601()

    case mint_unique(ledger, producer, claimed_at, @max_mint_attempts) do
      {:ok, id, record} -> {id, record}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Claim an externally produced id. First writer wins; any repeat claim (even by
  the same producer) is a collision and is rejected.
  """
  def claim(id, producer, opts \\ []) when is_binary(id) and is_binary(producer) do
    ensure_started(opts)
    ledger = ledger_path(opts)
    claimed_at = DateTime.utc_now() |> DateTime.to_iso8601()

    record = register(id, producer, "claim", claimed_at)

    case :ets.insert_new(@table, {id, record}) do
      true ->
        append_ledger(ledger, record)
        {:ok, record}

      false ->
        {:error, :duplicate, existing(id)}
    end
  end

  @doc "Resolve a registered id to its authority record."
  def resolve(id), do: (existing(id) && {:ok, existing(id)}) || {:error, :unregistered}

  @doc "True when `id` is registered with the authority."
  def registered?(id), do: table?() && :ets.member(@table, id)

  @doc """
  Simulate a node restart: destroy the current registry and re-create it by
  replaying `ledger_path` (Stage 4 distributed semantics). Unlike reset/1,
  a restarted node has no memory of the previous registry, so the ledger is the
  durable cross-node source of truth: a parent minted on node A resolves on
  node B after B replays the shared ledger.
  """
  def restart(ledger_path) do
    if table?(), do: :ets.delete(@table)
    ensure_started(ledger_path: ledger_path)
    :ok
  end

  @doc "Snapshot of all registered ids (excluding ledger-path bookkeeping)."
  def export do
    if table?() do
      @table
      |> :ets.tab2list()
      |> Enum.reject(fn
        {:__ledger_path, _} -> true
        _ -> false
      end)
      |> Enum.map(fn {id, record} -> %{record | "execution_id" => id} end)
      |> Enum.sort_by(fn r -> {r["claimed_at"], r["execution_id"]} end)
    else
      []
    end
  end

  @doc """
  Recreate the registry from `ledger_path`. Only permitted when the current
  registry was created for that same ledger (or none exists), so a test/operator
  can never clobber a registry owned by a different ledger.
  """
  def reset(ledger_path) do
    case table?() and :ets.lookup(@table, :__ledger_path) do
      false -> :ok
      [{:__ledger_path, ^ledger_path}] -> :ets.delete(@table)
      [{:__ledger_path, other}] -> raise ArgumentError, "registry belongs to another ledger: #{inspect(other)}"
    end

    ensure_started(ledger_path: ledger_path)
    :ok
  end

  defp mint_unique(_ledger, _producer, _claimed_at, 0) do
    {:error, %{reason: "collision_exhausted"}}
  end

  defp mint_unique(ledger, producer, claimed_at, attempts) do
    execution_id =
      "exec_" <>
        Integer.to_string(System.system_time(:millisecond)) <> "_" <> String.slice(Identity.uuid(), 0, 13)

    record = register(execution_id, producer, "mint", claimed_at)

    case :ets.insert_new(@table, {execution_id, record}) do
      true ->
        append_ledger(ledger, record)
        {:ok, execution_id, record}

      false ->
        mint_unique(ledger, producer, claimed_at, attempts - 1)
    end
  end

  defp register(id, producer, source, claimed_at) do
    %{
      "execution_id" => id,
      "producer" => producer,
      "authority" => @authority,
      "source" => source,
      "claimed_at" => claimed_at,
      "id_format" => id_format(id)
    }
  end

  defp id_format(id) do
    fmts = formats()
    cond do
      Regex.match?(fmts["forward_exec_v1"], id) -> "forward_exec_v1"
      Regex.match?(fmts["phase4_exec_v1"], id) -> "phase4_exec_v1"
      Regex.match?(fmts["opc_integer"], id) -> "opc_integer"
      true -> "other"
    end
  end

  defp existing(id) do
    if table?() do
      case :ets.lookup(@table, id) do
        [{^id, record}] -> record
        _ -> nil
      end
    else
      nil
    end
  end

  defp table?, do: :ets.whereis(@table) != :undefined

  defp ledger_path(opts) do
    Keyword.get_lazy(opts, :ledger_path, &default_ledger_path/0)
  end

  defp default_ledger_path do
    case Application.get_env(:forward_provenance, @ledger_env) do
      nil -> Path.expand("data/identity_authority_ledger.jsonl")
      path -> Path.expand(path)
    end
  end

  defp append_ledger(path, record) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.open(path, [:append, :utf8], fn io ->
      :io.put_chars(io, [Canon.canon(record), "\n"])
    end)
  rescue
    _ -> :ok
  end

  defp replay_ledger(path) do
    if File.regular?(path) do
      path
      |> File.stream!([], :line)
      |> Enum.each(fn line ->
        line = String.trim(line)

        if line != "" do
          rec = :json.decode(line)

          record = %{
            "execution_id" => Map.fetch!(rec, "execution_id"),
            "producer" => Map.fetch!(rec, "producer"),
            "authority" => Map.get(rec, "authority", @authority),
            "source" => Map.get(rec, "source", "replay"),
            "claimed_at" => Map.get(rec, "claimed_at"),
            "id_format" => Map.get(rec, "id_format", "other")
          }

          :ets.insert_new(@table, {record["execution_id"], record})
        end
      end)
    end
  rescue
    _ -> :ok
  end
end