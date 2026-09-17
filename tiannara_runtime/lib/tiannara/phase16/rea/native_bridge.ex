defmodule Tiannara.Phase16.REA.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy hypergraph unification & constraint solving.
  BEAM orchestrates; Native handles adjunction mapping on dirty schedulers.
  """
  use GenServer

  @nif_module :rea_native_unifier

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @spec unify_hypergraphs(domain_graphs :: [map()], tolerance :: float()) :: map()
  def unify_hypergraphs(graphs, tol), do: apply(@nif_module, :unify_and_relax, [graphs, tol])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase16, "priv/native/rea_native_unifier")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end