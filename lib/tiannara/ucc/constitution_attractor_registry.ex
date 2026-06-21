defmodule Tiannara.UCC.ConstitutionAttractorRegistry do
  @moduledoc """
  The Seed Bank for REA-X.
  Stores discovered constitutional attractors that govern adaptation successfully.
  """
  use GenServer

  alias Tiannara.UCC.ConstitutionGenome

  defmodule Attractor do
    @derive Jason.Encoder
    defstruct [:id, :genome, :fri, :trh, :ee, :universes_observed]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def register_attractor(id, %ConstitutionGenome{} = genome, fri, trh, ee) do
    GenServer.cast(__MODULE__, {:register, id, genome, fri, trh, ee})
  end

  def get_attractor(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def list_attractors() do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:register, id, genome, fri, trh, ee}, state) do
    attractor = Map.get(state, id, %Attractor{
      id: id,
      genome: genome,
      fri: fri,
      trh: trh,
      ee: ee,
      universes_observed: 0
    })

    updated_attractor = %{attractor |
      universes_observed: attractor.universes_observed + 1,
      # In reality, we might compute moving averages for fitness metrics here.
      fri: max(attractor.fri, fri),
      ee: max(attractor.ee, ee)
    }

    {:noreply, Map.put(state, id, updated_attractor)}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, Map.get(state, id), state}
  end

  @impl true
  def handle_call(:list, _from, state) do
    {:reply, Map.values(state), state}
  end
end
