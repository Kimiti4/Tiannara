defmodule TiannaraRuntime.SharedMemory do
  @moduledoc """
  The Zero-Copy ETS Pointer Registry ("System Nervous System").
  Manages the lifecycle of the Rust ResourceArc pointing to the sharded memory structure.
  Provides fast lookup for MSCL, CIS, and other systems to access the memory reference.
  """
  use GenServer
  require Logger
  
  alias Tiannara.Native.A10

  @table_name :a10_pointer_registry
  @pointer_key :global_state_vector
  
  # Default sizes for T1 Baseline
  @total_size 100_000
  @shard_size 10_000

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the opaque Rust Resource reference directly from ETS.
  This is extremely fast and avoids GenServer bottlenecks.
  """
  def get_state_ref do
    case :ets.lookup(@table_name, @pointer_key) do
      [{@pointer_key, ref}] -> {:ok, ref}
      [] -> {:error, :not_initialized}
    end
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    Logger.info("Starting Zero-Copy ETS Pointer Registry (T1 Baseline)")
    
    # Create the ETS table for pointer registry
    # :public allows anyone to read/write if needed, but we mainly write here and read everywhere.
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true])
    
    try do
      resource_ref = A10.allocate_state(@total_size, @shard_size)
      :ets.insert(@table_name, {@pointer_key, resource_ref})
      Logger.info("Successfully allocated and registered A10 StateResource (#{@total_size} elements).")
    rescue
      e -> 
        Logger.error("Failed to allocate A10 state via NIF: #{inspect(e)}")
    end

    {:ok, %{}}
  end
end
