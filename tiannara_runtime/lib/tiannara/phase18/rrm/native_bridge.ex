defmodule Tiannara.Phase18.RRM.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for symbolic rule search & JIT compilation.
  BEAM orchestrates; Native handles rule optimization & target codegen on dirty schedulers.

  The native library is declared in application configuration and loaded
  through `TiannaraRuntime.NativeBridge`, which is the single implementation
  of native loading for this runtime. This module only names the accelerator
  and the native entry point it exposes.
  """
  use GenServer

  @nif_module :rrm_native_jit

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
  @spec jit_compile(rules :: term(), target :: term()) :: {:ok, term()} | {:error, term()}
  def jit_compile(rules, target) do
    TiannaraRuntime.NativeBridge.call(@nif_module, :compile_and_optimize, [rules, target])
  end

  @doc "Load the NIF library for this accelerator."
  @spec load_nif() :: :ok | {:error, term()}
  def load_nif, do: TiannaraRuntime.NativeBridge.load(@nif_module)
end
