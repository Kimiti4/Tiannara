defmodule Tiannara.Omega.RuntimeHealthAggregator do
  @moduledoc """
  Runtime Health Aggregator — unified health view across all Ω subsystems.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec full_status() :: map()
  def full_status do
    GenServer.call(__MODULE__, :full_status, 30_000)
  end

  @spec health() :: map()
  def health do
    GenServer.call(__MODULE__, :health, 15_000)
  end

  @impl true
  def init(_opts) do
    {:ok, %{last_check: nil, cached_health: nil}}
  end

  @impl true
  def handle_call(:full_status, _from, state) do
    status = collect_full_status()
    {:reply, status, %{state | last_check: DateTime.utc_now()}}
  end

  @impl true
  def handle_call(:health, _from, state) do
    health = collect_health()
    {:reply, health, %{state | last_check: DateTime.utc_now(), cached_health: health}}
  end

  defp collect_full_status do
    %{
      executive: safe_health(Tiannara.Executive.ExecutiveMemory, & &1.health()),
      sentinel: safe_health(Tiannara.Sentinel.SentinelRuntime, & &1.health()),
      research: safe_health(Tiannara.Research.ResearchDirector, & &1.health()),
      interface: safe_health(Tiannara.Interface.CognitiveInterface, & &1.health()),
      autonomy: safe_health(Tiannara.Autonomy.ConstitutionalAutonomy, & &1.health()),
      ecr: safe_health(Tiannara.Executive.Cognitive.ExecutiveCognitiveRuntime, & &1.health()),
      agency_loop: safe_health(Tiannara.Omega.AgencyLoop, & &1.status()),
      vm: vm_health(),
      timestamp: DateTime.utc_now()
    }
  end

  defp collect_health do
    full = collect_full_status()

    subsystems = [full.executive, full.sentinel, full.research, full.interface, full.autonomy, full.ecr]
    all_healthy = Enum.all?(subsystems, fn s -> s[:status] == :healthy end)
    any_degraded = Enum.any?(subsystems, fn s -> s[:status] == :degraded end)

    overall = cond do
      all_healthy -> :healthy
      any_degraded -> :degraded
      true -> :partial
    end

    %{status: overall, subsystems_healthy: Enum.count(subsystems, fn s -> s[:status] == :healthy end), subsystems_total: length(subsystems), vm: full.vm, agency_loop: full.agency_loop, timestamp: full.timestamp}
  end

  defp safe_health(module, fun) do
    case Process.whereis(module) do
      nil -> %{status: :not_running, module: module}
      _pid ->
        try do
          fun.(module)
        catch
          _, _ -> %{status: :unreachable, module: module}
        end
    end
  end

  defp vm_health do
    %{total_memory: :erlang.memory(:total), processes: :erlang.system_info(:process_count), atom_count: :erlang.system_info(:atom_count), run_queue: :erlang.statistics(:run_queue), uptime_seconds: :erlang.statistics(:wall_clock) |> elem(0) |> div(1000)}
  end
end
