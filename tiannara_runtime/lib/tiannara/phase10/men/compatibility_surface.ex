defmodule Tiannara.Phase10.MEN.CompatibilitySurface do
  @moduledoc """
  Temporary interaction boundary allocator.
  [Original Concept: Temporary Compatibility Surface Generator]
  """
  use GenServer

  @base_lifetime_ms 300_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(opts), do: {:ok, %{conn_name: opts[:connection_name], active_surfaces: %{}}}

  @doc "Allocate surface based on negotiation equilibrium"
  @spec allocate(neg_id :: String.t(), a :: String.t(), b :: String.t(), n_eq :: float(), conn_name :: atom()) :: 
    {:ok, surface_id :: String.t()}
  def allocate(neg_id, a, b, n_eq, conn_name) do
    surface_id = "surface_#{neg_id}"
    lifetime_ms = trunc(@base_lifetime_ms * n_eq)
    
    Gnat.pub(conn_name, "tiannara.men.surface.allocated",
             Jason.encode!(%{surface_id: surface_id, partitions: [a, b], lifetime_ms: lifetime_ms}))
             
    {:ok, surface_id}
  end
end