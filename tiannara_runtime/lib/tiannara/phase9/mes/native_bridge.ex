defmodule Tiannara.Phase9.MES.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for IR optimization & GPU surface allocation.
  BEAM orchestrates; Native handles symbolic compilation on dirty schedulers.
  """
  use GenServer

  @nif_module :mes_native_compiler

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @spec compile_to_ir(axiom_set :: map()) :: {:ok, binary()} | {:error, String.t()}
  def compile_to_ir(axiom_set), do: apply(@nif_module, :compile_axioms_to_ir, [axiom_set])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase9, "priv/native/mes_native_compiler")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end