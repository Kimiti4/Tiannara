defmodule Tiannara.CIS.CollapsePredictor do
  @moduledoc """
  Predicts topological and semantic collapse risks.
  Subscribes to EventBus constraint snapshots.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    EventBus.subscribe("constraint.snapshot")
    {:ok, %{risk: 0.0}}
  end

  def handle_info({:snapshot, snapshot}, state) do
    risk = compute_risk(snapshot)
    if risk > 0.8 do
      EventBus.broadcast("immune.response", :collapse_risk)
    end
    {:noreply, %{state | risk: risk}}
  end

  defp compute_risk(_snapshot), do: :rand.uniform()
end
