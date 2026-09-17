defmodule Tiannara.Sentinel.Baseline.BaselineBuilder do
  @moduledoc """
  Aggregates metrics over long horizons to establish the structural "normal"
  of the runtime ontology, ecology, and pressure dynamics.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end
end
