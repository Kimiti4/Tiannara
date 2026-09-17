defmodule TiannaraRuntime.CIS.ExecutionController do
  use GenServer

  alias TiannaraRuntime.CIS.Supervisor, as: CISSup
  alias Tiannara.Meta.ChronogramMatrix
  alias Tiannara.GCK.ChronogramGate

  defstruct execution_count: 0, deny_count: 0

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def execute(action, target, reason, severity) do
    GenServer.call(__MODULE__, {:execute, action, target, reason, severity})
  end

  def execute_emergency_shutdown(reason) do
    GenServer.cast(__MODULE__, {:emergency_shutdown, reason})
    :initiated
  end

  def register_chronogram_observer(observer_id, parent_id \\ nil) do
    ChronogramMatrix.register_observer(observer_id, parent_id)
  end

  def execute_memory_write(observer_id, state) do
    case ChronogramGate.validate_write(observer_id, state) do
      {:allow, :ok} ->
        ChronogramMatrix.write(observer_id, state)
        {:ok, :written}

      {:reject, reason} ->
        {:error, :gck_rejected, reason}
    end
  end

  def execute_memory_read(observer_id, coordinate) do
    ChronogramMatrix.read(observer_id, coordinate)
  end

  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:execute, action, target, reason, severity}, _from, state) do
    safety_mode =
      case Process.whereis(CISSup) do
        nil -> :normal
        _ -> CISSup.get_safety_mode()
      end

    case safety_mode do
      :lockdown ->
        {:reply, {:error, :denied_by_cis}, %{state | deny_count: state.deny_count + 1}}
      _ ->
        {:reply, :ok, %{state | execution_count: state.execution_count + 1}}
    end
  end

  @impl true
  def handle_cast({:emergency_shutdown, _reason}, state) do
    {:noreply, state}
  end
end
