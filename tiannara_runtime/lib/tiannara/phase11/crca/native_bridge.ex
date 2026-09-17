defmodule Tiannara.Phase11.CRCA.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy DAG alignment, cycle detection, and temporal mapping.
  BEAM orchestrates; Native handles graph algorithms on dirty schedulers.
  """
  use GenServer

  @nif_module :crca_native_aligner

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @doc "Align temporal sequences across partitions"
  @spec align_temporal_sequences(seq_a :: [integer()], seq_b :: [integer()], tolerance :: float()) :: 
    {:ok, map()} | {:error, String.t()}
  def align_temporal_sequences(a, b, tol), 
    do: apply(@nif_module, :align_sequences, [a, b, tol])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase11, "priv/native/crca_native_aligner")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end