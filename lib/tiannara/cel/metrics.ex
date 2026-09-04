defmodule Tiannara.CEL.Metrics do
  use GenServer
  require Logger

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def healthy?, do: GenServer.call(__MODULE__, :healthy)

  def constitutional_score, do: GenServer.call(__MODULE__, :constitutional_score)

  @impl true
  def init(_opts) do
    Logger.info("Metrics: stub service initialized (Phase 4).")
    {:ok, %{}}
  end

  @impl true
  def handle_call(:healthy, _from, state), do: {:reply, true, state}

  @impl true
  def handle_call(:constitutional_score, _from, state) do
    {:reply, Tiannara.CEL.Kernel.ConstitutionalScore.default(:executive_metrics), state}
  end
end
