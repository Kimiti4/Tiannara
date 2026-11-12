defmodule Tiannara.Phase14.REG.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy symbolic search & type unification.
  BEAM orchestrates; Native handles graph matching & constraint solving on dirty schedulers.

  The native library is declared in application configuration and loaded
  through `TiannaraRuntime.NativeBridge`, which is the single implementation
  of native loading for this runtime. This module only names the accelerator
  and the native entry point it exposes.
  """
  use GenServer

  @nif_module :reg_native_symbolic

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
  @spec mutate(axioms :: term(), domain :: term()) :: {:ok, term()} | {:error, term()}
  def mutate(axioms, domain) do
    TiannaraRuntime.NativeBridge.call(@nif_module, :symbolic_mutate, [axioms, domain])
  end

  @doc "Load the NIF library for this accelerator."
  @spec load_nif() :: :ok | {:error, term()}
  def load_nif, do: TiannaraRuntime.NativeBridge.load(@nif_module)
end
