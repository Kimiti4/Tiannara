defmodule Tiannara.WorldServer do
  @moduledoc """
  Independent ecological simulation environment inside a universe.
  Runs localized physics/logic rules, hosts civilizations and agents.
  """
  use GenServer

  defstruct [
    :id,
    :universe,
    :civilizations,
    :state_tensor,
    :entropy,
    :resource_field,
    :drift_vector
  ]

  # API
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via(opts[:id]))
  end

  def spawn_civilization(world_pid, civ_id) do
    GenServer.call(world_pid, {:spawn_civ, civ_id})
  end

  # INIT
  def init(opts) do
    state = %__MODULE__{
      id: opts[:id],
      universe: opts[:universe],
      civilizations: %{},
      state_tensor: %{},
      entropy: 0.5,
      resource_field: %{},
      drift_vector: {0, 0, 0}
    }

    {:ok, state}
  end

  # WORLD TICK
  def handle_cast(:world_tick, state) do
    new_state =
      state
      |> evolve_resources()
      |> update_entropy()
      |> compute_drift()
      |> propagate_to_civilizations()

    {:noreply, new_state}
  end

  # CIVILIZATION CREATION
  def handle_call({:spawn_civ, civ_id}, _from, state) do
    {:ok, pid} =
      Tiannara.CivilizationServer.start_link(%{
        id: civ_id,
        world: state.id
      })

    civs = Map.put(state.civilizations, civ_id, pid)

    {:reply, :ok, %{state | civilizations: civs}}
  end

  # INTERNAL DYNAMICS
  defp evolve_resources(state), do: state
  defp update_entropy(state), do: %{state | entropy: :rand.uniform()}
  defp compute_drift(state), do: %{state | drift_vector: {0.1, 0.2, 0.3}}

  defp propagate_to_civilizations(state) do
    Enum.each(state.civilizations, fn {_id, pid} ->
      GenServer.cast(pid, :civ_tick)
    end)

    state
  end

  defp via(id), do: {:via, Registry, {Tiannara.Registry, {:world, id}}}
end
