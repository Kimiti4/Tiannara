defmodule TiannaraRuntime.OS.Observatory.ArtifactStorage do
  @moduledoc """
  First-Class Artifact Storage

  Every event becomes a searchable, replayable artifact.
  Artifacts are timestamped, hashed, and indexed for fast retrieval.

  Storage is in-memory with optional persistence.
  """

  @type artifact :: %{
    type: atom(),
    data: map(),
    metadata: map(),
    timestamp: integer(),
    hash: String.t()
  }

  @type storage :: %{
    artifacts: [artifact()],
    index: %{atom() => [integer()]},  # type -> artifact indices
    time_index: [{integer(), integer()}]  # timestamp -> index
  }

  @doc """
  Creates a new empty artifact storage.
  """
  @spec new() :: storage()
  def new() do
    %{
      artifacts: [],
      index: %{},
      time_index: []
    }
  end

  @doc """
  Adds an artifact to storage.
  """
  @spec add(storage(), artifact()) :: storage()
  def add(storage, artifact) do
    index = length(storage.artifacts)
    
    # Update artifacts list
    new_artifacts = [artifact | storage.artifacts]
    
    # Update type index
    type = artifact.type
    new_type_indices = Map.get(storage.index, type, [])
    new_index = Map.put(storage.index, type, [index | new_type_indices])
    
    # Update time index
    new_time_index = [{artifact.timestamp, index} | storage.time_index]
    
    %{
      artifacts: new_artifacts,
      index: new_index,
      time_index: new_time_index
    }
  end

  @doc """
  Searches artifacts by query.
  Query supports:
  - type: filter by artifact type
  - since: filter by timestamp (milliseconds)
  - until: filter by timestamp (milliseconds)
  - hash: filter by exact hash
  """
  @spec search(storage(), map()) :: [artifact()]
  def search(storage, query) do
    storage.artifacts
    |> Enum.filter(fn artifact ->
      matches_query?(artifact, query)
    end)
    |> Enum.reverse()  # Most recent first
  end

  @doc """
  Returns all artifacts of a specific type.
  """
  @spec get_by_type(storage(), atom()) :: [artifact()]
  def get_by_type(storage, type) do
    indices = Map.get(storage.index, type, [])
    Enum.map(indices, fn idx ->
      Enum.at(storage.artifacts, idx)
    end)
  end

  @doc """
  Returns artifacts within a time range.
  """
  @spec get_in_time_range(storage(), integer(), integer()) :: [artifact()]
  def get_in_time_range(storage, since, until_ts) do
    storage.artifacts
    |> Enum.filter(fn artifact ->
      artifact.timestamp >= since and artifact.timestamp <= until_ts
    end)
  end

  @doc """
  Returns the count of all artifacts.
  """
  @spec count(storage()) :: integer()
  def count(storage) do
    length(storage.artifacts)
  end

  @doc """
  Returns the count of artifacts by type.
  """
  @spec count_by_type(storage(), atom()) :: integer()
  def count_by_type(storage, type) do
    storage.index
    |> Map.get(type, [])
    |> length()
  end

  # ── Internal Functions ──────────────────────────────────────

  defp matches_query?(artifact, query) do
    type_match = case Map.get(query, :type) do
      nil -> true
      t -> artifact.type == t
    end

    since_match = case Map.get(query, :since) do
      nil -> true
      since -> artifact.timestamp >= since
    end

    until_match = case Map.get(query, :until) do
      nil -> true
      until_ts -> artifact.timestamp <= until_ts
    end

    hash_match = case Map.get(query, :hash) do
      nil -> true
      hash -> artifact.hash == hash
    end

    type_match and since_match and until_match and hash_match
  end
end
