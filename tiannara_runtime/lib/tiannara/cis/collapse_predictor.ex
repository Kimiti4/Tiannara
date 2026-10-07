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
    {:ok, %{risk: :unknown, last_snapshot: nil}}
  end

  def assess_risk(snapshot), do: compute_risk(snapshot)
  def status, do: GenServer.call(__MODULE__, :status)

  def handle_call(:status, _from, state), do: {:reply, %{risk: state.risk, last_snapshot: state.last_snapshot}, state}

  def handle_info({:snapshot, snapshot}, state) do
    case compute_risk(snapshot) do
      {:ok, risk} ->
        if risk > 0.8, do: EventBus.broadcast("immune.response", {:collapse_risk, %{risk: risk, snapshot: snapshot}})
        {:noreply, %{state | risk: risk, last_snapshot: snapshot}}
      {:error, :insufficient_evidence} ->
        {:noreply, %{state | risk: :unknown, last_snapshot: snapshot}}
    end
  end

  defp compute_risk(snapshot) when is_map(snapshot) do
    metrics = [
      Map.get(snapshot, :pressure),
      Map.get(snapshot, :entropy),
      Map.get(snapshot, :divergence),
      Map.get(snapshot, :cascade_rate)
    ]

    values = Enum.filter(metrics, &is_number/1)
    if values == [] do
      {:error, :insufficient_evidence}
    else
      {:ok, Enum.sum(Enum.map(values, &clamp/1)) / length(values)}
    end
  end

  defp compute_risk(_), do: {:error, :insufficient_evidence}

  defp clamp(value), do: max(0.0, min(1.0, value))
end
