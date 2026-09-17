defmodule Tiannara.Meta.Evolution.TensorEvolutionEngine do
  @moduledoc """
  TensorEvolutionEngine - Starts under supervision and runs the evolution loop on laws.
  """

  use GenServer

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evolve(law) do
    GenServer.call(__MODULE__, {:evolve, law})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:evolve, law}, _from, state) do
    # Simply mutate the law (or pass it through) and assign a fitness score
    mutated_law = Map.put(law, :mutated_at, System.system_time())
    fitness = 0.95
    {:reply, {mutated_law, fitness}, state}
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
