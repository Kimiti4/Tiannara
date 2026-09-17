defmodule Tiannara.Runtime.CRA.OntologicalForkingReflex do
  @moduledoc """
  Phase 5F.10 — Ontological Forking Reflex

  Monitors and coordinates immediate branch creation (forking) when high
  veto or collapse risk is detected in a cluster.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @doc """
  Resets the reflex state.
  """
  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  @doc """
  Evaluates cluster risk and triggers an ontological fork if threshold is exceeded.
  """
  def cluster_veto_risk(cluster_id, risk_score) do
    GenServer.call(__MODULE__, {:cluster_veto_risk, cluster_id, risk_score})
  end

  # --- GenServer Callbacks ---

  @impl true
  def handle_call(:reset, _from, state) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:cluster_veto_risk, cluster_id, risk_score}, _from, state) do
    if risk_score >= 0.8 do
      # Fetch OLEF pressures dynamically if Field is started
      pressures =
        case Process.whereis(Tiannara.Runtime.OLEF.Field) do
          nil -> %{}
          _pid -> :sys.get_state(Tiannara.Runtime.OLEF.Field).pressures
        end

      remaining_pressures = Map.delete(pressures, cluster_id)
      remaining_nodes = Map.keys(remaining_pressures)

      equilibrium_pressure =
        if Enum.empty?(remaining_nodes) do
          0.0
        else
          Enum.sum(Map.values(remaining_pressures)) / map_size(remaining_pressures)
        end

      event = %{
        action: :ontological_fork,
        cluster_id: cluster_id,
        isolation: %{mode: :frozen_snapshot},
        fork: %{
          excluded_cluster: cluster_id,
          continuity_mode: :full_rebind_olef,
          dependency_rebinding: %{
            excluded: cluster_id,
            remaining_nodes: remaining_nodes,
            equilibrium_pressure: equilibrium_pressure
          }
        }
      }

      # Register fork in RedundancyMesh
      Tiannara.Runtime.CRA.RedundancyMesh.register_fork(cluster_id, event.fork)

      {:reply, {:forked, event}, state}
    else
      event = %{
        action: :monitor,
        cluster_id: cluster_id
      }
      {:reply, {:monitored, event}, state}
    end
  end
end
