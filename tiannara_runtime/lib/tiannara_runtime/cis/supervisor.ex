defmodule TiannaraRuntime.CIS.Supervisor do
  use GenServer

  defstruct safety_mode: :normal

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def set_safety_mode(mode) do
    GenServer.call(__MODULE__, {:set_safety_mode, mode})
  end

  def get_safety_mode do
    GenServer.call(__MODULE__, :get_safety_mode)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:set_safety_mode, mode}, _from, state) do
    {:reply, :ok, %{state | safety_mode: mode}}
  end

  @impl true
  def handle_call(:get_safety_mode, _from, state) do
    {:reply, state.safety_mode, state}
  end
end
