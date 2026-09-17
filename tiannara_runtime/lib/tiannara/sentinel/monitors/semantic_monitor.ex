defmodule Tiannara.Sentinel.Monitors.SemanticMonitor do
  @moduledoc """
  Monitors OCM ontology drift and consensus fragmentation.
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
