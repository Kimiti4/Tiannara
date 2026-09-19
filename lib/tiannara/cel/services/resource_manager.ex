defmodule Tiannara.CEL.Services.ResourceManager do
  use Tiannara.ExecutiveService.Base
  use GenServer
  require Logger

  @sustainability_reserve 0.20

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def allocate(service_id, request) do
    GenServer.call(__MODULE__, {:allocate, service_id, request})
  end

  def release(service_id, resources) do
    GenServer.cast(__MODULE__, {:release, service_id, resources})
  end

  def status, do: GenServer.call(__MODULE__, :status)
  def pool, do: GenServer.call(__MODULE__, :pool)
  def allocation(service_id), do: GenServer.call(__MODULE__, {:allocation, service_id})

  @impl true
  def id, do: :resource_manager

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities, do: [:resource_allocation, :sustainability_enforcement, :capacity_planning]

  @impl true
  def health, do: :healthy

  @impl true
  def constitutional_score do
    %Tiannara.CEL.Kernel.ConstitutionalScore{
      service_id: :resource_manager,
      health: 1.0,
      constitutional_alignment: 0.95,
      transparency: 0.9,
      explainability: 0.85,
      evidence_quality: 0.85,
      human_oversight: 0.7,
      computed_at: DateTime.utc_now()
    }
  end

  def ready?, do: GenServer.call(__MODULE__, :ready?)

  @impl true
  def init(_opts) do
    state = %{
      total: nil,
      allocated: %{},
      reservations: %{},
      pools: %{},
      ready: false,
      started_at: DateTime.utc_now(),
      sustainability_reserve: @sustainability_reserve
    }

    state =
      try do
        pools = init_pools()
        total = %{cpu: 100, memory_mb: 65_536, gpu: 8, storage_gb: 10_000}
        Logger.info("ResourceManager: Initialized. Total resources: #{inspect(total)}")

        %{
          state
          | total: total,
            allocated: %{cpu: 0, memory_mb: 0, gpu: 0, storage_gb: 0},
            pools: pools,
            ready: true,
            sustainability_reserve: @sustainability_reserve
        }
      rescue
        e ->
          Logger.warning("ResourceManager: pool init deferred (#{inspect(e)})")
          state
      end

    {:ok, state}
  end

  @impl true
  def handle_call(:ready?, _from, state), do: {:reply, state.ready, state}

  @impl true
  def handle_call({:allocate, _service_id, _request}, _from, %{ready: false} = state) do
    case ensure_ready(state) do
      {:ok, new_state} -> handle_call({:allocate, nil, nil}, nil, new_state)
      _ -> {:reply, {:error, :not_ready}, state}
    end
  end

  def handle_call({:allocate, service_id, request}, _from, state) do
    request_pct = compute_percentage(request, state.total)

    if request_pct > 0.50 do
      auth =
        Tiannara.Council.authorize(:resource_reallocation, %{
          service_id: service_id,
          resource_request: request,
          percentage: request_pct
        })

      case auth.decision do
        d when d in [:approved, :conditional] ->
          do_allocate(service_id, request, state)

        _ ->
          {:reply, {:error, :council_denied, auth.explanation}, state}
      end
    else
      do_allocate(service_id, request, state)
    end
  end

  @impl true
  def handle_call(:status, _from, state) do
    available = compute_available(state)
    {:reply, %{total: state.total, allocated: state.allocated, available: available}, state}
  end

  @impl true
  def handle_call(:pool, _from, state), do: {:reply, state.total, state}

  @impl true
  def handle_call({:allocation, service_id}, _from, state) do
    {:reply, Map.get(state.reservations, service_id, %{}), state}
  end

  @impl true
  def handle_cast({:release, service_id, resources}, state) do
    new_allocated = release_resources(state.allocated, resources)
    new_reservations = Map.delete(state.reservations, service_id)
    Logger.info("ResourceManager: Released resources from #{service_id}")
    {:noreply, %{state | allocated: new_allocated, reservations: new_reservations}}
  end

  defp do_allocate(service_id, request, state) do
    available = compute_available(state)

    with :ok <- check_available(request, available) do
      new_allocated = add_resources(state.allocated, request)

      new_state = %{
        state
        | allocated: new_allocated,
          reservations: Map.put(state.reservations, service_id, request)
      }

      Logger.info("ResourceManager: Allocated #{inspect(request)} to #{service_id}")

      :telemetry.execute([:tiannara, :cel, :resource, :allocated], %{}, %{
        service_id: service_id,
        request: request
      })

      {:reply, {:ok, request}, new_state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp check_available(request, available) do
    resource_types = [:cpu, :memory_mb, :gpu, :storage_gb]

    Enum.reduce_while(resource_types, :ok, fn type, _acc ->
      amount = Map.get(request, type, 0)
      pool = Map.get(available, type, 0)

      if amount <= pool do
        {:cont, :ok}
      else
        {:halt, {:error, {:insufficient, type, available: pool, requested: amount}}}
      end
    end)
  end

  defp compute_available(state) do
    reserve_factor = 1.0 - @sustainability_reserve

    %{
      cpu: max(0, round(state.total.cpu * reserve_factor) - state.allocated.cpu),
      memory_mb: max(0, round(state.total.memory_mb * reserve_factor) - state.allocated.memory_mb),
      gpu: max(0, round(state.total.gpu * reserve_factor) - state.allocated.gpu),
      storage_gb: max(0, round(state.total.storage_gb * reserve_factor) - state.allocated.storage_gb)
    }
  end

  defp compute_percentage(request, total) do
    ratios =
      Enum.map(request, fn {type, amount} ->
        case type do
          :cpu -> amount / total.cpu
          :memory_mb -> amount / total.memory_mb
          :gpu -> amount / total.gpu
          :storage_gb -> amount / total.storage_gb
          _ -> 0.0
        end
      end)

    Enum.max(ratios, fn -> 0.0 end)
  end

  defp init_pools do
    %{}
  end

  defp ensure_ready(%{ready: false} = state) do
    try do
      pools = init_pools()
      total = %{cpu: 100, memory_mb: 65_536, gpu: 8, storage_gb: 10_000}

      {:ok,
       %{
         state
         | total: total,
           allocated: %{cpu: 0, memory_mb: 0, gpu: 0, storage_gb: 0},
           pools: pools,
           ready: true,
           sustainability_reserve: @sustainability_reserve
       }}
    rescue
      _ -> {:error, :init_failed}
    end
  end

  defp ensure_ready(state), do: {:ok, state}

  defp add_resources(allocated, request) do
    resource_types = [:cpu, :memory_mb, :gpu, :storage_gb]
    request = Map.take(request, resource_types)
    Map.merge(allocated, request, fn _k, v1, v2 -> v1 + v2 end)
  end

  defp release_resources(allocated, resources) do
    resource_types = [:cpu, :memory_mb, :gpu, :storage_gb]
    resources = Map.take(resources, resource_types)
    Map.merge(allocated, resources, fn _k, v1, v2 -> max(0, v1 - v2) end)
  end
end
