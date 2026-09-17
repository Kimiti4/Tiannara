defmodule Tiannara.Phase9.MES.ContainmentSandbox do
  @moduledoc """
  Isolated execution surface + kill switches.
  [Original Concept: Meta-Existence Quarantine]
  """
  use GenServer
  require Logger

  @containment_threshold 0.80
  @leakage_timeout_ms 30_000

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{active_surfaces: %{}, monitoring_timers: %{}}}

  @doc "Deploy compiled axiom set to isolated surface"
  @spec deploy(compiled :: map(), conn_name :: atom()) :: :ok
  def deploy(compiled, conn_name), do: GenServer.cast(__MODULE__, {:deploy, compiled, conn_name})

  @impl true
  def handle_cast({:deploy, compiled, conn_name}, state) do
    surface_id = "sandbox_#{compiled.axiom_set_id}"
    Logger.info("🔒 MES: Deploying to isolated surface #{surface_id}")
    
    # Publish deployment to NATS for surface allocator
    Gnat.pub(conn_name, "tiannara.mes.sandbox.deploy", 
             Jason.encode!(%{surface_id: surface_id, compiled: compiled}))
    
    timer = Process.send_after(self(), {:evaluate_containment, surface_id}, @leakage_timeout_ms)
    
    new_surfaces = Map.put(state.active_surfaces, surface_id, compiled)
    new_timers = Map.put(state.monitoring_timers, surface_id, timer)
    
    {:noreply, %{state | active_surfaces: new_surfaces, monitoring_timers: new_timers}}
  end

  @impl true
  def handle_info({:evaluate_containment, surface_id}, state) do
    compiled = Map.get(state.active_surfaces, surface_id)
    if is_nil(compiled), do: {:noreply, state}
    
    leakage = simulate_leakage_check(compiled)
    integrity = 1.0 - leakage
    containment_metric = integrity / (leakage + 1.0e-6)
    
    if containment_metric >= @containment_threshold do
      Logger.info("✅ MES: Surface #{surface_id} containment stable. Promoting to active substrate.")
      promote_to_active_surface(surface_id, state)
    else
      Logger.warning("🚨 MES: Surface #{surface_id} containment breach. Triggering quarantine.")
      quarantine_surface(surface_id)
    end
    
    {:noreply, Map.delete(state.active_surfaces, surface_id) |> Map.delete(:monitoring_timers)}
  end

  defp simulate_leakage_check(_compiled), do: :rand.uniform() * 0.15
  defp promote_to_active_surface(surface_id, _state), do: :ok # NATS routing to Phase 8 RTL
  defp quarantine_surface(surface_id), do: :ok # NATS routing to ORB horizon guard
end