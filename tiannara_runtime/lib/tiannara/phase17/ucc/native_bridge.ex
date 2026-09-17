defmodule Tiannara.Phase17.UCC.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy IR optimization & target-specific kernel generation.
  BEAM orchestrates; Native handles DAG scheduling & GPU/WASM lowering on dirty schedulers.
  """
  use GenServer

  @nif_module :ucc_native_compiler

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @spec compile_to_target(ir :: map(), target :: atom()) :: binary()
  def compile_to_target(ir, target), do: apply(@nif_module, :lower_to_bytecode, [ir, target])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase17, "priv/native/ucc_native_compiler")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end