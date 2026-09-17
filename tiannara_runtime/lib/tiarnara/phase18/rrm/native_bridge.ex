defmodule Tiarnara.Phase18.RRM.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for symbolic rule search & JIT compilation.
  BEAM orchestrates; Native handles rule optimization & target codegen on dirty schedulers.
  """
  use GenServer

  @nif_module :rrm_native_jit

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @spec jit_compile(rules :: map(), target :: atom()) :: binary()
  def jit_compile(rules, target), do: apply(@nif_module, :compile_and_optimize, [rules, target])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiarnara_phase18, "priv/native/rrm_native_jit")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end