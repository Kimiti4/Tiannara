defmodule Tiannara.Phase19.TCL.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy rule-diff computation & graph reconciliation.
  BEAM orchestrates; Native handles lattice state diff on dirty schedulers.
  """
  use GenServer

  @nif_module :tcl_native_lattice

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @spec compute_levenshtein(a :: String.t(), b :: String.t()) :: integer()
  def compute_levenshtein(a, b), do: apply(@nif_module, :diff_hashes, [a, b])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase19, "priv/native/tcl_native_lattice")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end