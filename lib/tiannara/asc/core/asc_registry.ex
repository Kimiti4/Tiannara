defmodule Tiannara.ASC.Core.Registry do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def register(service_id, module, capabilities, phase) do
    GenServer.call(__MODULE__, {:register, service_id, module, capabilities, phase})
  end

  def unregister(service_id) do
    GenServer.cast(__MODULE__, {:unregister, service_id})
  end

  def find_by_capability(capability) do
    GenServer.call(__MODULE__, {:find_by_capability, capability})
  end

  def find_by_phase(phase) do
    GenServer.call(__MODULE__, {:find_by_phase, phase})
  end

  def all_services, do: GenServer.call(__MODULE__, :all)

  def health_report, do: GenServer.call(__MODULE__, :health_report)

  def whereis(service_id) do
    case GenServer.call(__MODULE__, {:get, service_id}) do
      nil -> nil
      svc -> svc.pid
    end
  end

  def count, do: length(all_services())

  @impl true
  def init(_opts) do
    {:ok, %{services: %{}, started_at: DateTime.utc_now()}}
  end

  @impl true
  def handle_call({:register, service_id, module, capabilities, phase}, _from, state) do
    service = %{
      id: service_id,
      module: module,
      capabilities: capabilities,
      phase: phase,
      registered_at: DateTime.utc_now(),
      pid: Process.whereis(module)
    }

    {:reply, :ok, put_in(state.services[service_id], service)}
  end

  @impl true
  def handle_call({:find_by_capability, capability}, _from, state) do
    results =
      state.services
      |> Map.values()
      |> Enum.filter(fn svc -> capability in svc.capabilities end)

    {:reply, results, state}
  end

  @impl true
  def handle_call({:find_by_phase, phase}, _from, state) do
    results =
      state.services
      |> Map.values()
      |> Enum.filter(fn svc -> svc.phase == phase end)

    {:reply, results, state}
  end

  @impl true
  def handle_call({:get, service_id}, _from, state) do
    {:reply, Map.get(state.services, service_id), state}
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.values(state.services), state}
  end

  @impl true
  def handle_call(:health_report, _from, state) do
    report =
      Map.new(state.services, fn {id, svc} ->
        alive = svc.pid != nil and Process.alive?(svc.pid)
        {id, %{alive: alive, phase: svc.phase, capabilities: svc.capabilities}}
      end)

    {:reply, report, state}
  end

  @impl true
  def handle_cast({:unregister, service_id}, state) do
    {:noreply, %{state | services: Map.delete(state.services, service_id)}}
  end

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
