defmodule Tiannara.Phase17.UCC.SurfaceCompiler do
  @moduledoc """
  Lowers substrate-agnostic IR to target-specific execution surfaces.
  """
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts) do
    {:ok, %{conn_name: opts[:connection_name], active_surfaces: %{}}}
  end

  @doc "Lower IR to target bytecode/kernel"
  @spec lower(ir :: map(), surface_id :: String.t(), target :: atom()) :: :ok
  def lower(ir, surface_id, target) do
    bytecode = Tiannara.Phase17.UCC.NativeBridge.compile_to_target(ir, target)
    
    Gnat.pub(:tiannara_phase17_ucc_nats, "tiannara.phase17.ucc.surface.#{surface_id}",
             Jason.encode!(%{surface_id: surface_id, bytecode: bytecode, target: target}))
    
    GenServer.cast(__MODULE__, {:register, surface_id, target})
    :ok
  end

  @impl true
  def handle_cast({:register, id, target}, state) do
    {:noreply, %{state | active_surfaces: Map.put(state.active_surfaces, id, %{target: target, status: :compiled})}}
  end
end