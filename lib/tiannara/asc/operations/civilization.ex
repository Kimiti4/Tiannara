defmodule Tiannara.ASC.Operations.Supervisor do
  use Supervisor
  def start_link(opts \\ []), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  @impl true
  def init(_), do: Supervisor.init([Tiannara.ASC.Operations.Civilization], strategy: :one_for_one)
end

defmodule Tiannara.ASC.Operations.Civilization do
  @moduledoc """
  Operations Civilization (Phase H).

  Continuous monitoring of deployed projects across:
    - Latency, Errors, Cost, Security, Capacity, Incidents

  Detects: Anomalies, Regressions, Bottlenecks.

  On anomaly detection:
    - Emits `"asc:operations:anomaly"` on PubSub
    - Triggers `ASC.Repair` pipeline
    - Updates `long_term_stability` in Observatory

  ## Current Status: fail-closed (Phase H stub remediated).

  `run/1` previously returned `{:ok, :stub}` — a success-shaped stub
  (capability ledger C5). Now reports unavailability so no caller can
  mistake it for a real operations execution.
  """

  use GenServer
  require Logger

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @spec run(Tiannara.ASC.Project.t()) :: {:error, :unavailable}
  def run(_project), do: {:error, :unavailable}

  @impl true
  def init(_opts) do
    Logger.info("[ASC.Operations] Civilization initialized (Phase H stub)")
    {:ok, %{monitored_projects: []}}
  end
end
