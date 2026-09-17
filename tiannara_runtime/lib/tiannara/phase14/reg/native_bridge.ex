defmodule Tiannara.Phase14.REG.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy symbolic search & type unification.
  BEAM orchestrates; Native handles graph matching & constraint solving on dirty schedulers.
  """
  use GenServer

  @nif_module :reg_native_symbolic

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @spec mutate(axioms :: map(), domain :: atom()) :: map()
  def mutate(axioms, domain), do: apply(@nif_module, :symbolic_mutate, [axioms, domain])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase14, "priv/native/reg_native_symbolic")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end