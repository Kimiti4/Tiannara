defmodule Tiannara.Sentinel.Shadow.ShadowCleanup do
  @moduledoc """
  Ensures immediate destruction of the epistemic shadow sandbox once results are extracted.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def destroy_sandbox(seed) do
    GenServer.cast(__MODULE__, {:destroy, seed})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:destroy, seed}, state) do
    Logger.debug("Destroying epistemic shadow sandbox for recommendation #{seed.recommendation.id}")
    # In C.1A there are no live processes to kill, so this is just a formal log/cleanup step.
    {:noreply, state}
  end
end
