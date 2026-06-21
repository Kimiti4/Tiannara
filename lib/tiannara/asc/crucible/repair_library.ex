defmodule Tiannara.ASC.Crucible.RepairLibrary do
  @moduledoc """
  Repair Library — persistent repository of successful repair strategies.

  Stores and retrieves repair patterns discovered through successful repairs,
  enabling knowledge reuse across projects and generations.

  ## Features

  - Persistent storage via NDJSON (data/repair_patterns.ndjson)
  - ETS cache for fast lookups
  - Query by failure signature
  - Query by repair category
  - Query by transferability score
  - Automatic pattern statistics updates

  ## Example

      iex> {:ok, library} = Tiannara.ASC.Crucible.RepairLibrary.start_link()
      iex> Tiannara.ASC.Crucible.RepairLibrary.add_pattern(library, pattern)
      :ok
      iex> patterns = Tiannara.ASC.Crucible.RepairLibrary.query_by_signature(library, "validation_missing:user_id")
      [%RepairPattern{...}]

  """

  use GenServer

  alias Tiannara.ASC.Crucible.RepairPattern

  # ETS table name
  @table_name :repair_library

  # Persistence file
  @persistence_file "data/repair_patterns.ndjson"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Load and deduplicate persisted patterns
    {patterns, is_compacted} = load_persisted_patterns()

    # Create ETS table for O(1) reads
    :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])

    # Populate ETS cache
    Enum.each(patterns, fn pattern ->
      :ets.insert(@table_name, {pattern.id, pattern})
    end)
    
    # Store initial metrics
    persisted_count = length(patterns)
    ets_count = :ets.info(@table_name, :size)
    IO.puts("📚 RepairLibrary initialized with #{length(patterns)} patterns")
    IO.puts("📊 [RepairLibrary] :ets.info reports #{ets_count} patterns (Compacted: #{is_compacted})")
    
    if length(patterns) != ets_count do
      IO.puts("⚠️  [CRITICAL BUG] ETS POPULATION MISMATCH!")
      IO.puts("   Loaded #{length(patterns)} patterns but ETS contains #{ets_count}")
    end
    
    # Show sample signatures from ETS
    if ets_count > 0 do
      sample = :ets.first(@table_name)
      case :ets.lookup(@table_name, sample) do
        [{_id, p}] ->
          IO.puts("📋 [RepairLibrary] Sample pattern ID: #{p.id}")
          IO.puts("📋 [RepairLibrary] Sample pattern signature: #{inspect(p.failure_signature)}")
          IO.puts("📋 [RepairLibrary] Sample pattern classification: #{inspect(p.failure_classification)}")
        _ ->
          IO.puts("❌ [RepairLibrary] Could not read sample pattern from ETS")
      end
    end
    
    IO.puts("✅ [RepairLibrary] ETS inspection complete\n")

    {:ok, %{pattern_count: ets_count, initial_persisted: persisted_count}}
  end

  @doc """
  Add a new repair pattern to the library.

  ## Parameters

  - `pattern` — RepairPattern struct to add

  ## Returns

  - `:ok`
  """
  def add_pattern(%RepairPattern{} = pattern) do
    GenServer.call(__MODULE__, {:add_pattern, pattern})
  end

  @doc """
  Query patterns by failure signature.

  ## Parameters

  - `signature` — Failure signature to search for

  ## Returns

  - List of matching RepairPattern structs
  """
  def query_by_signature(signature) do
    GenServer.call(__MODULE__, {:query_by_signature, signature})
  end

  @doc """
  Query patterns by repair category.

  ## Parameters

  - `category` — Repair category (:validation, :security, etc.)

  ## Returns

  - List of matching RepairPattern structs
  """
  def query_by_category(category) do
    GenServer.call(__MODULE__, {:query_by_category, category})
  end

  @doc """
  Get high-confidence patterns (confidence > 0.7).

  ## Returns

  - List of high-confidence RepairPattern structs
  """
  def high_confidence_patterns do
    GenServer.call(__MODULE__, :high_confidence_patterns)
  end

  @doc """
  Get transferable patterns (transferability > 0.5).

  ## Returns

  - List of transferable RepairPattern structs
  """
  def transferable_patterns do
    GenServer.call(__MODULE__, :transferable_patterns)
  end

  @doc """
  Get all successful patterns (success_rate > 0.5).

  ## Returns

  - List of successful RepairPattern structs
  """
  def successful_patterns do
    GenServer.call(__MODULE__, :successful_patterns)
  end

  @doc """
  Update pattern statistics after reuse attempt.

  ## Parameters

  - `pattern_id` — ID of pattern to update
  - `success?` — Whether reuse was successful
  - `project_id` — Project where pattern was reused

  ## Returns

  - `:ok` or `{:error, :not_found}`
  """
  def update_pattern_statistics(pattern_id, success?, project_id) do
    GenServer.call(__MODULE__, {:update_statistics, pattern_id, success?, project_id})
  end

  @doc """
  Get total pattern count.

  ## Returns

  - Integer count of patterns in library
  """
  def pattern_count do
    GenServer.call(__MODULE__, :pattern_count)
  end

  @doc """
  List all patterns in the library.

  ## Returns

  - List of all RepairPattern structs
  """
  def list_all_patterns do
    GenServer.call(__MODULE__, :list_all_patterns)
  end

  @doc """
  Returns all currently loaded patterns from the ETS table.
  Used by the Expansion Campaign to evaluate the current ecology.
  """
  def get_all_patterns do
    :ets.tab2list(@table_name)
    |> Enum.map(fn {_id, pattern} -> pattern end)
  end

  @doc """
  Learns a new pattern. Optimized for high-throughput ingestion during 5C.9.
  """
  def learn(%{id: id} = pattern) when is_binary(id) do
    GenServer.call(__MODULE__, {:learn, pattern})
  end

  @doc """
  Verify memory integrity of the RepairLibrary.
  """
  def verify_integrity do
    GenServer.call(__MODULE__, :verify_integrity)
  end

  @doc """
  Get a memory population report.
  """
  def population_report do
    GenServer.call(__MODULE__, :population_report)
  end

  @doc """
  Detect and report any memory corruption.
  """
  def detect_corruption do
    GenServer.call(__MODULE__, :detect_corruption)
  end

  @impl true
  def handle_call({:add_pattern, pattern}, _from, state) do
    IO.puts("     📥 [RepairLibrary] Adding pattern #{pattern.id} with signature: #{pattern.failure_signature}")
    # Insert into ETS
    :ets.insert(@table_name, {pattern.id, pattern})
    
    # Verify insertion
    case :ets.lookup(@table_name, pattern.id) do
      [{_id, stored_pattern}] when stored_pattern.id == pattern.id ->
        IO.puts("     ✅ [RepairLibrary] Pattern successfully inserted into ETS")
      _ ->
        IO.puts("     ❌ [RepairLibrary] FAILED to insert pattern into ETS!")
    end

    # Persist to disk
    persist_pattern(pattern)

    {:reply, :ok, %{state | pattern_count: state.pattern_count + 1}}
  end

  def handle_call({:learn, pattern}, _from, state) do
    # Fast path for high-throughput learning during 5C.9
    :ets.insert(@table_name, {pattern.id, pattern})
    persist_pattern(pattern)
    {:reply, :ok, %{state | pattern_count: state.pattern_count + 1}}
  end

  def handle_call({:query_by_signature, signature}, _from, state) do
    IO.puts("     🔎 [RepairLibrary] Querying for signature: #{signature}")
    
    # Get total pattern count for debugging
    all_patterns = :ets.tab2list(@table_name)
    IO.puts("     📊 [RepairLibrary] Total patterns in ETS: #{length(all_patterns)}")
    
    # Show all signatures for debugging (first 5)
    if length(all_patterns) > 0 do
      sample_signatures = Enum.take(all_patterns, 5) |> Enum.map(fn {_id, p} -> p.failure_signature end)
      IO.puts("     📋 [RepairLibrary] Sample signatures: #{inspect(sample_signatures)}")
    end
    
    # Query ETS for matching signatures
    matches = :ets.select(@table_name, [
      {{:"$1", :"$2"}, [{:==, {:element, 2, :"$2"}, signature}], [:"$2"]}
    ])
    
    IO.puts("     📊 [RepairLibrary] Found #{length(matches)} matching patterns")

    {:reply, matches, state}
  end

  def handle_call({:query_by_category, category}, _from, state) do
    # Query ETS for matching categories
    matches = :ets.select(@table_name, [
      {{:"$1", :"$2"}, [{:==, {:element, 4, :"$2"}, category}], [:"$2"]}
    ])

    {:reply, matches, state}
  end

  def handle_call(:high_confidence_patterns, _from, state) do
    # Filter patterns with confidence > 0.7
    all_patterns = get_all_patterns()
    high_conf = Enum.filter(all_patterns, &(&1.confidence > 0.7))

    {:reply, high_conf, state}
  end

  def handle_call(:transferable_patterns, _from, state) do
    # Filter patterns with transferability > 0.5
    all_patterns = get_all_patterns()
    transferable = Enum.filter(all_patterns, &(&1.transferability > 0.5))

    {:reply, transferable, state}
  end

  def handle_call(:successful_patterns, _from, state) do
    # Filter patterns with success_rate > 0.5
    all_patterns = get_all_patterns()
    successful = Enum.filter(all_patterns, &(&1.success_rate > 0.5))

    {:reply, successful, state}
  end

  def handle_call({:update_statistics, pattern_id, success?, project_id}, _from, state) do
    case :ets.lookup(@table_name, pattern_id) do
      [{^pattern_id, pattern}] ->
        # Update pattern statistics
        updated_pattern = RepairPattern.update_statistics(pattern, success?, project_id)

        # Update ETS
        :ets.insert(@table_name, {pattern_id, updated_pattern})

        # Persist update
        persist_pattern(updated_pattern)

        {:reply, :ok, state}

      [] ->
        {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call(:pattern_count, _from, state) do
    {:reply, :ets.info(@table_name, :size), state}
  end

  def handle_call(:list_all_patterns, _from, state) do
    patterns = get_all_patterns()
    {:reply, patterns, state}
  end

  def handle_call(:verify_integrity, _from, state) do
    report = generate_population_report(state.initial_persisted)
    
    healthy = report.ets_count == report.persisted_count and 
              report.unique_ids == report.ets_count and 
              not report.has_corruption
              
    {:reply, healthy, state}
  end

  def handle_call(:population_report, _from, state) do
    {:reply, generate_population_report(state.initial_persisted), state}
  end

  def handle_call(:detect_corruption, _from, state) do
    report = generate_population_report(state.initial_persisted)
    
    corruption_details = []
    
    corruption_details = if report.nil_ids > 0 do
      [{:nil_ids, report.nil_ids} | corruption_details]
    else
      corruption_details
    end
    
    corruption_details = if report.has_corruption do
      [{:mismatch, "ets_count != persisted_count or unique_ids != ets_count"} | corruption_details]
    else
      corruption_details
    end
    
    {:reply, {report.has_corruption, corruption_details}, state}
  end

  # Private helpers

  defp generate_population_report(persisted_count) do
    patterns = get_all_patterns()
    ets_count = :ets.info(@table_name, :size)
    
    ids = Enum.map(patterns, & &1.id)
    unique_ids = MapSet.new(ids)
    nil_ids = Enum.count(ids, &is_nil/1)
    
    has_corruption = ets_count != persisted_count or 
                     MapSet.size(unique_ids) != ets_count or 
                     nil_ids > 0
                     
    %{
      persisted_count: persisted_count,
      ets_count: ets_count,
      unique_ids: MapSet.size(unique_ids),
      nil_ids: nil_ids,
      has_corruption: has_corruption
    }
  end


  defp load_persisted_patterns do
    if File.exists?(@persistence_file) do
      patterns = @persistence_file
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&Jason.decode!/1)
      |> Enum.map(fn json_map ->
        # Convert string keys to atom keys for struct conversion
        # Handle nested maps (like failure_classification) recursively
        struct_keys = Map.keys(%RepairPattern{})
        
        atom_key_map = 
          for {key, val} <- json_map,
              key in Enum.map(struct_keys, &Atom.to_string/1),
              into: %{} do
            atom_key = String.to_existing_atom(key)
            
            # Convert nested map keys to atoms if needed
            converted_val = 
              case val do
                %{} = nested_map when atom_key == :failure_classification ->
                  # Convert nested classification map keys AND values to atoms
                  for {nk, nv} <- nested_map, into: %{} do
                    # Safely convert key to atom (create if doesn't exist)
                    atom_nk = 
                      try do
                        String.to_existing_atom(nk)
                      rescue
                        ArgumentError -> String.to_atom(nk)
                      end
                    
                    # Convert string values to atoms for known atom fields
                    atom_nv = 
                      if atom_nk in [:domain, :category, :subcategory] and is_binary(nv) do
                        # Safely convert value to atom (create if doesn't exist)
                        try do
                          String.to_existing_atom(nv)
                        rescue
                          ArgumentError -> String.to_atom(nv)
                        end
                      else
                        nv
                      end
                    
                    {atom_nk, atom_nv}
                  end
                _ ->
                  val
              end
            
            {atom_key, converted_val}
          end
        
        struct(RepairPattern, atom_key_map)
      end)
      
      # Check IDs to find out how many were actually loaded
      ids = Enum.map(patterns, & &1.id)
      unique_ids = MapSet.new(ids)
      
      # Deduplicate (keep latest)
      unique_patterns = patterns
      |> Enum.reverse()
      |> Enum.uniq_by(& &1.id)
      |> Enum.reverse()

      is_compacted = if length(patterns) > length(unique_patterns) do
        compact_persistence_file(unique_patterns)
        true
      else
        false
      end

      # DEBUG: Inspect loaded patterns
      IO.puts("\n🔍 [RepairLibrary] Memory Integrity Report...")
      IO.puts("📊 Raw loaded: #{length(patterns)}")
      IO.puts("📊 Unique IDs: #{MapSet.size(unique_ids)}")
      IO.puts("📊 Deduplicated: #{length(unique_patterns)}")
      
      nil_ids = Enum.count(unique_patterns, &is_nil(&1.id))
      if nil_ids > 0 do
        IO.puts("⚠️  [CRITICAL BUG] #{nil_ids} patterns have nil IDs!")
      end
      
      {unique_patterns, is_compacted}
    else
      {[], false}
    end
  end

  defp compact_persistence_file(patterns) do
    # Ensure data directory exists
    File.mkdir_p!(Path.dirname(@persistence_file))
    
    # Overwrite with compacted NDJSON
    lines = Enum.map(patterns, fn pattern ->
      Jason.encode!(Map.from_struct(pattern)) <> "\n"
    end)
    
    File.write!(@persistence_file, lines, [:write])
    IO.puts("📦 [RepairLibrary] Compacted persistence file from to #{length(patterns)} entries.")
  end

  defp persist_pattern(pattern) do
    # Ensure data directory exists
    File.mkdir_p!(Path.dirname(@persistence_file))

    # Append pattern as NDJSON line
    json_line = Jason.encode!(Map.from_struct(pattern))
    File.write!(@persistence_file, json_line <> "\n", [:append])
  end
end
