defmodule Tiannara.ROS.ShardManager do
  @moduledoc """
  Manager for Regional Ontological Shards (ROS).
  
  Tracks the active epistemic branches (shards) and provides the API
  to spawn new ones, suspend them, and query their status.
  """

  use GenServer
  require Logger

  # State
  defstruct [
    active_shards: %{}, # shard_id => metadata
    total_spawned: 0
  ]

  # ============================================================================
  # Public API
  # ============================================================================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Spawn a new epistemic branch (Shard).
  """
  def spawn_shard(shard_id, config \\ %{}) do
    GenServer.call(__MODULE__, {:spawn_shard, shard_id, config})
  end

  @doc """
  List all active shards.
  """
  def list_shards() do
    GenServer.call(__MODULE__, :list_shards)
  end

  # ============================================================================
  # GenServer Callbacks
  # ============================================================================

  @impl true
  def init(_opts) do
    Logger.info("🌌 [ROS] ShardManager initialized (Phase ROS-1 Active)")
    {:ok, %__MODULE__{
      active_shards: %{
        # By default, Canonical World-0 is tracked but not spawned dynamically here,
        # it is part of the core supervision tree.
        world_0: %{status: :canonical, created_at: System.system_time(:second)}
      }
    }}
  end

  @impl true
  def handle_call({:spawn_shard, shard_id, config}, _from, state) do
    if Map.has_key?(state.active_shards, shard_id) do
      {:reply, {:error, :already_exists}, state}
    else
      # 1. Ask the dynamic supervisor to boot the WorldModel supervision tree
      case Tiannara.ROS.ShardSupervisor.start_shard(shard_id) do
        {:ok, _pid} ->
          metadata = %{
            status: :active,
            config: config,
            created_at: System.system_time(:second)
          }
          new_state = %{state |
            active_shards: Map.put(state.active_shards, shard_id, metadata),
            total_spawned: state.total_spawned + 1
          }
          {:reply, {:ok, shard_id}, new_state}
          
        {:error, reason} ->
          Logger.error("Failed to spawn shard #{shard_id}: #{inspect(reason)}")
          {:reply, {:error, reason}, state}
      end
    end
  end

  @impl true
  def handle_call(:list_shards, _from, state) do
    {:reply, state.active_shards, state}
  end
end
