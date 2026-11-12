defmodule Tiannara.Phase17.UCC.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy IR optimization & target-specific kernel generation.
  BEAM orchestrates; Native handles DAG scheduling & GPU/WASM lowering on dirty schedulers.

  The native library is declared in application configuration and loaded
  through `TiannaraRuntime.NativeBridge`, which is the single implementation
  of native loading for this runtime. This module only names the accelerator
  and the native entry point it exposes.
  """
  use GenServer

  @nif_module :ucc_native_compiler

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    {:ok, %{accelerator: @nif_module, status: TiannaraRuntime.NativeBridge.status(@nif_module)}}
  end

  @doc "Status of the backing native accelerator."
  @spec accelerator_status() :: TiannaraRuntime.NativeBridge.status()
  def accelerator_status, do: TiannaraRuntime.NativeBridge.status(@nif_module)

  @doc "Calls the native entry point, failing closed when it is unavailable."
  @spec compile_to_target(ir :: term(), target :: term()) :: {:ok, term()} | {:error, term()}
  def compile_to_target(ir, target) do
    TiannaraRuntime.NativeBridge.call(@nif_module, :lower_to_bytecode, [ir, target])
  end

  @doc "Load the NIF library for this accelerator."
  @spec load_nif() :: :ok | {:error, term()}
  def load_nif, do: TiannaraRuntime.NativeBridge.load(@nif_module)
end
