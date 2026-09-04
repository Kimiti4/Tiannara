defmodule TiannaraOS.RuntimeAtlas do
  @moduledoc """
  Runtime Atlas for Research Institutions.
  
  Tracks all active institutions in the system for discoverability and monitoring.
  Uses ETS for lock-free concurrent access.
  """
  
  use GenServer
  require Logger
  
  @table_name :runtime_atlas_institutions
  
  # Start the Runtime Atlas supervisor
  @spec start_link(keyword()) :: {:ok, pid()} | {:error, term()}
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(_opts) do
    # Create ETS table for institution registration
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true])
    
    Logger.info("[RuntimeAtlas] Institution registry initialized")
    {:ok, %{}}
  end
  
  # Register an institution
  @spec register(atom(), map()) :: :ok
  def register(institution_id, metadata) do
    record = %{
      id: institution_id,
      registered_at: DateTime.utc_now(),
      metadata: metadata
    }
    
    :ets.insert(@table_name, {institution_id, record})
    Logger.info("[RuntimeAtlas] Registered institution: #{inspect(institution_id)}")
    :ok
  end
  
  # Get institution details
  @spec get(atom()) :: map() | nil
  def get(institution_id) do
    case :ets.lookup(@table_name, institution_id) do
      [{^institution_id, record}] -> record
      [] -> nil
    end
  end
  
  # List all registered institutions
  @spec list() :: [map()]
  def list do
    :ets.tab2list(@table_name)
    |> Enum.map(fn {_id, record} -> record end)
  end
  
  # Unregister an institution
  @spec unregister(atom()) :: :ok
  def unregister(institution_id) do
    :ets.delete(@table_name, institution_id)
    Logger.info("[RuntimeAtlas] Unregistered institution: #{inspect(institution_id)}")
    :ok
  end
  
  # Check if institution is registered
  @spec registered?(atom()) :: boolean()
  def registered?(institution_id) do
    :ets.member(@table_name, institution_id)
  end
  
  # Count registered institutions
  @spec count() :: integer()
  def count do
    :ets.info(@table_name, :size)
  end
end
