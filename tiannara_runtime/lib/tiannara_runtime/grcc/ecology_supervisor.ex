defmodule TiannaraRuntime.GRCC.EcologySupervisor do
  @moduledoc """
  GRCC Ecology Supervisor
  
  Manages the population of identity lineage processes.
  Uses DynamicSupervisor to spawn and monitor identity processes dynamically.
  
  Responsibilities:
  - Spawn new identity lineages on demand
  - Monitor identity process health
  - Enforce maximum identity count
  - Track lineage genealogy
  """
  
  use DynamicSupervisor
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Spawn a new identity lineage process.
  
  ## Parameters
  - id: Unique identity identifier
  - lineage_id: Lineage grouping identifier
  - initial_genome: Semantic genome configuration map
  
  ## Returns
  - {:ok, pid} on success
  - {:error, reason} on failure
  """
  def spawn_identity(id, lineage_id, initial_genome) do
    # Check if we've reached max capacity
    current_count = count_active_identities()
    max_identities = Application.get_env(:tiannara_runtime, __MODULE__)[:max_identities] || 100
    
    if current_count >= max_identities do
      Logger.warning("⚠️  Maximum identity count reached (#{max_identities}). Cannot spawn #{id}")
      {:error, :max_identities_reached}
    else
      child_spec = {TiannaraRuntime.GRCC.IdentityLineage, {id, lineage_id, initial_genome}}
      
      case DynamicSupervisor.start_child(__MODULE__, child_spec) do
        {:ok, pid} ->
          Logger.info("✅ Spawned identity #{id} (lineage: #{lineage_id}, total: #{current_count + 1})")
          {:ok, pid}
        
        {:error, reason} ->
          Logger.error("❌ Failed to spawn identity #{id}: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  @doc """
  Terminate an identity lineage process.
  """
  def terminate_identity(id) do
    case GenServer.whereis({:via, Registry, {TiannaraRuntime.GRCC.Registry, id}}) do
      nil ->
        {:error, :not_found}
      
      pid ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)
        Logger.info("🗑️  Terminated identity #{id}")
        :ok
    end
  end

  @doc """
  Get count of active identities.
  """
  def count_active_identities() do
    DynamicSupervisor.count_children(__MODULE__)
    |> Map.get(:active, 0)
  end

  @doc """
  List all active identity IDs.
  """
  def list_active_identities() do
    # Query registry for all registered identities
    # This is a simplified implementation
    []
  end
end
