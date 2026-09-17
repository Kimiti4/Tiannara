defmodule Tiannara.Phase15.SMCP.NativeBridge do
  @moduledoc """
  Rustler NIF boundary for heavy metric aggregation & proposal simulation.
  BEAM orchestrates; Native handles consensus parameter search space evaluation.
  """
  use GenServer

  @nif_module :smcp_native_simulator

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts), do: {:ok, %{}}

  @doc "Simulate consensus performance under candidate parameters"
  @spec simulate_performance(candidate :: map(), network_metrics :: map()) :: float()
  def simulate_performance(candidate, metrics), 
    do: apply(@nif_module, :simulate_consensus_stability, [candidate, metrics])

  @doc "Load NIF module (called during app startup)"
  @spec load_nif() :: :ok | {:error, String.t()}
  def load_nif do
    path = Application.app_dir(:tiannara_phase15, "priv/native/smcp_native_simulator")
    :erlang.load_nif(path, 0)
    :ok
  rescue
    e -> {:error, "NIF load failed: #{inspect(e)}"}
  end
end