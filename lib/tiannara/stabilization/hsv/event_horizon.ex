defmodule Tiannara.Stabilization.HSV.EventHorizon do
  @moduledoc """
  Event Horizon Manager for HSV.

  Manages event horizons that isolate high-density regions to prevent system-wide contamination.
  """

  use GenServer
  require Logger

  # Client API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def spawn_horizon(region_id, threshold, metadata \\ %{}) do
    GenServer.call(__MODULE__, {:spawn_horizon, region_id, threshold, metadata})
  end

  def get_horizon_status(horizon_id) do
    GenServer.call(__MODULE__, {:get_horizon_status, horizon_id})
  end

  def list_active_horizons() do
    GenServer.call(__MODULE__, :list_active_horizons)
  end

  def collapse_horizon(horizon_id) do
    GenServer.call(__MODULE__, {:collapse_horizon, horizon_id})
  end

  def get_horizon_metrics() do
    GenServer.call(__MODULE__, :get_horizon_metrics)
  end

  # Server callbacks
  @impl true
  def init(_opts) do
    # Initialize ETS table for active horizons
    :ets.new(:active_horizons, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    # Initialize ETS table for horizon history
    :ets.new(:horizon_history, [
      :set,
      :public,
      :named_table,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    # Initialize metrics
    metrics = %{
      total_spawned: 0,
      total_collapsed: 0,
      active_count: 0,
      total_isolated_concepts: 0,
      avg_lifespan: 0,
      created_at: System.system_time(:millisecond)
    }

    Logger.info("Event Horizon Manager initialized")

    {:ok, metrics}
  end

  @impl true
  def handle_call({:spawn_horizon, region_id, threshold, metadata}, _from, state) do
    # Check if region already has an active horizon
    case :ets.lookup(:active_horizons, region_id) do
      [{^region_id, _}] ->
        {:reply, {:error, :horizon_already_exists}, state}

      [] ->
        # Create new horizon
        horizon_id = generate_horizon_id()
        horizon_data = create_horizon_data(region_id, threshold, metadata)

        # Store active horizon
        :ets.insert(:active_horizons, {horizon_id, horizon_data})
        :ets.insert(:active_horizons, {region_id, horizon_id})

        # Update metrics
        new_metrics = %{state |
          total_spawned: state.total_spawned + 1,
          active_count: state.active_count + 1
        }

        Logger.info("Spawned event horizon #{horizon_id} for region #{region_id} with threshold #{threshold}")

        {:reply, {:ok, horizon_id}, new_metrics}
    end
  end

  @impl true
  def handle_call({:get_horizon_status, horizon_id}, _from, state) do
    case :ets.lookup(:active_horizons, horizon_id) do
      [{^horizon_id, horizon_data}] ->
        status = %{
          id: horizon_id,
          region_id: horizon_data.region_id,
          threshold: horizon_data.threshold,
          created_at: horizon_data.created_at,
          age: System.system_time(:millisecond) - horizon_data.created_at,
          concepts_isolated: horizon_data.concepts_isolated,
          causal_isolation_active: horizon_data.causal_isolation_active,
          compression_active: horizon_data.compression_active,
          preservation_fidelity: horizon_data.preservation_fidelity,
          metadata: horizon_data.metadata
        }

        {:reply, {:ok, status}, state}

      [] ->
        {:reply, {:error, :horizon_not_found}, state}
    end
  end

  @impl true
  def handle_call(:list_active_horizons, _from, state) do
    horizons = :ets.tab2list(:active_horizons)
    |> Enum.filter(fn {key, _} -> String.starts_with?(to_string(key), "horizon_") end)
    |> Enum.map(fn {horizon_id, horizon_data} ->
      %{
        id: horizon_id,
        region_id: horizon_data.region_id,
        threshold: horizon_data.threshold,
        age: System.system_time(:millisecond) - horizon_data.created_at,
        concepts_isolated: horizon_data.concepts_isolated
      }
    end)

    {:reply, {:ok, horizons}, state}
  end

  @impl true
  def handle_call({:collapse_horizon, horizon_id}, _from, state) do
    case :ets.lookup(:active_horizons, horizon_id) do
      [{^horizon_id, horizon_data}] ->
        # Move to history
        history_entry = %{horizon_data |
          collapsed_at: System.system_time(:millisecond),
          lifespan: System.system_time(:millisecond) - horizon_data.created_at
        }

        :ets.insert(:horizon_history, {horizon_id, history_entry})

        # Remove from active horizons
        :ets.delete(:active_horizons, horizon_id)

        # Also remove region mapping
        region_id = horizon_data.region_id
        case :ets.lookup(:active_horizons, region_id) do
          [{^region_id, ^horizon_id}] ->
            :ets.delete(:active_horizons, region_id)
          _ ->
            # Already removed or different horizon
            :ok
        end

        # Update metrics
        new_metrics = %{state |
          total_collapsed: state.total_collapsed + 1,
          active_count: max(0, state.active_count - 1),
          total_isolated_concepts: state.total_isolated_concepts - horizon_data.concepts_isolated
        }

        Logger.info("Collapsed event horizon #{horizon_id} for region #{region_id}")

        {:reply, {:ok, :collapsed}, new_metrics}

      [] ->
        {:reply, {:error, :horizon_not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_horizon_metrics, _from, state) do
    # Get current active horizon count
    active_count = :ets.info(:active_horizons, :size)

    # Calculate average lifespan from history
    history_records = :ets.tab2list(:horizon_history)
    avg_lifespan = if length(history_records) > 0 do
      total_lifespan = Enum.sum(Enum.map(history_records, fn {_, record} -> 
        Map.get(record, :lifespan, 0)
      end))
      total_lifespan / length(history_records)
    else
      0
    end

    metrics = %{
      total_spawned: state.total_spawned,
      total_collapsed: state.total_collapsed,
      active_count: active_count,
      total_isolated_concepts: state.total_isolated_concepts,
      avg_lifespan: avg_lifespan,
      system_uptime: System.system_time(:millisecond) - state.created_at
    }

    {:reply, {:ok, metrics}, state}
  end

  # Helper functions
  defp generate_horizon_id() do
    "horizon_#{System.system_time(:millisecond)}_#{:crypto.strong_rand_bytes(8) |> Base.url_encode64()}"
  end

  defp create_horizon_data(region_id, threshold, metadata) do
    %{
      region_id: region_id,
      threshold: threshold,
      created_at: System.system_time(:millisecond),
      concepts_isolated: 0,  # Will be updated when concepts are processed
      causal_isolation_active: true,
      compression_active: true,
      preservation_fidelity: 0.95,
      metadata: Map.merge(metadata, %{
        horizon_type: :standard,
        isolation_mode: :causal_conceptual
      })
    }
  end
end