defmodule Tiannara.Phase10.MEN.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy constraint solving & surface optimization.
  BEAM orchestrates; Native handles graph matching & adjunction mapping on dirty schedulers.
  """
  use GenServer

  @nif_module :men_native_solver

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @doc "Solve cross-axiomatic constraint relaxation"
  @spec relax_constraints(axiom_set_a :: map(), axiom_set_b :: map(), tolerance :: float()) :: 
    {:ok, map()} | {:error, String.t()}
  def relax_constraints(a, b, tol), do: apply(@nif_module, :solve_constraint_relaxation, [a, b, tol])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase10, "priv/native/men_native_solver")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end