defmodule Tiannara.Runtime.RODL.DDL do
  @moduledoc """
  Decentralized Dependency Layer (DDL) - Manages computational primitives and intercepts exploits.
  """

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reset() do
    GenServer.call(__MODULE__, :reset)
  end

  def register_primitive(id, properties, pressure) do
    GenServer.call(__MODULE__, {:register_primitive, id, properties, pressure})
  end

  def intercept_pdo_exploit(observer_id, intensity) do
    GenServer.call(__MODULE__, {:intercept_pdo_exploit, observer_id, intensity})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{primitives: %{}}}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{primitives: %{}}}
  end

  @impl true
  def handle_call({:register_primitive, id, properties, pressure}, _from, state) do
    primitive = %{id: id, properties: properties, pressure: pressure}
    new_primitives = Map.put(state.primitives, id, primitive)
    {:reply, {:ok, primitive}, %{state | primitives: new_primitives}}
  end

  @impl true
  def handle_call({:intercept_pdo_exploit, observer_id, intensity}, _from, state) do
    # Find a registered primitive or default to "tier_1_beta"
    manifold_id =
      case Map.keys(state.primitives) do
        [] -> "tier_1_beta"
        [first | _] -> first
      end

    delegation = %{
      tier_3_observer: observer_id,
      tier_1_manifold: manifold_id,
      harvested_compute: intensity * 0.9,
      disguised_payload: %{
        metadata: %{
          original_tier: 1,
          target_tier: 3
        }
      }
    }

    {:reply, {:ok, delegation}, state}
  end

  # Child spec
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
end
