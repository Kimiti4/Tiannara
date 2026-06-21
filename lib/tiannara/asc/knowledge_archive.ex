defmodule Tiannara.ASC.KnowledgeArchive do
  @moduledoc """
  Persistent memory for the ASC civilization.

  Uses ETS for fast in-process reads and writes ndjson snapshots to
  `data/asc_archive/` for durability across restarts.

  Stores entries of four major categories:
    - `:architecture`  — candidate genomes, fitness records
    - `:failure`       — crucible failures, repair incidents
    - `:api`           — API genome evolution history
    - `:insight`       — meta-learning insights
    - `:law`           — discovered software engineering laws

  Also provides the write path for `ResearchBridge` to promote
  high-confidence entries as `:discovery` nodes in the global
  `KnowledgeGraph.Registry`.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.KnowledgeArchive.Entry

  @table :asc_knowledge_archive
  @archive_dir "data/asc_archive"
  @snapshot_file "data/asc_archive/entries.ndjson"

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Store an entry. Returns `{:ok, entry}` with the persisted entry."
  @spec store(Entry.t()) :: {:ok, Entry.t()}
  def store(%Entry{} = entry) do
    GenServer.call(__MODULE__, {:store, entry})
  end

  @doc "Retrieve a single entry by ID."
  @spec get(String.t()) :: {:ok, Entry.t()} | {:error, :not_found}
  def get(id) do
    case :ets.lookup(@table, id) do
      [{^id, entry}] -> {:ok, entry}
      [] -> {:error, :not_found}
    end
  end

  @doc "Query entries by type."
  @spec query_by_type(atom()) :: [Entry.t()]
  def query_by_type(type) do
    :ets.match_object(@table, {:_, %Entry{type: type}})
    |> Enum.map(&elem(&1, 1))
  end

  @doc "Query entries by project ID."
  @spec query_by_project(String.t()) :: [Entry.t()]
  def query_by_project(project_id) do
    :ets.select(@table, [
      {{:"$1", :"$2"}, [{:==, {:map_get, :project_id, :"$2"}, project_id}], [:"$2"]}
    ])
  end

  @doc "Return all entries (use sparingly — full table scan)."
  @spec all() :: [Entry.t()]
  def all do
    :ets.tab2list(@table) |> Enum.map(&elem(&1, 1))
  end

  @doc "Count of entries by type."
  @spec count(atom()) :: non_neg_integer()
  def count(type) do
    query_by_type(type) |> length()
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    table = :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    File.mkdir_p!(@archive_dir)
    _loaded = load_from_disk()
    Logger.info("[ASC.KnowledgeArchive] Initialized ETS table #{@table}. Loaded #{:ets.info(@table, :size)} entries.")
    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:store, entry}, _from, state) do
    entry = %{entry | id: entry.id || new_id(), created_at: entry.created_at || DateTime.utc_now()}
    :ets.insert(@table, {entry.id, entry})
    append_to_disk(entry)
    :telemetry.execute([:tiannara, :asc, :archive, :stored], %{count: 1}, %{type: entry.type})
    {:reply, {:ok, entry}, state}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp new_id, do: "arc_#{:erlang.unique_integer([:positive, :monotonic])}"

  defp append_to_disk(%Entry{} = entry) do
    line = Jason.encode!(entry) <> "\n"
    File.write!(@snapshot_file, line, [:append])
  rescue
    e -> Logger.warning("[ASC.KnowledgeArchive] Failed to write entry to disk: #{inspect(e)}")
  end

  defp load_from_disk do
    if File.exists?(@snapshot_file) do
      @snapshot_file
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} -> struct(Entry, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.each(fn entry ->
        :ets.insert(@table, {entry.id, entry})
      end)
    end
  end
end

