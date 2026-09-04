defmodule Tiannara.Sentinel.Cognition.KnowledgeIntegrator do
  @moduledoc "Upgrades memory from data -> information -> knowledge -> patterns -> principles."
  use GenServer

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, %{}, opts)
  def integrate(pid, experiment_result), do: GenServer.cast(pid, {:integrate, experiment_result})

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_cast({:integrate, result}, state) do
    principle = "Maintain exploration and pruning pressure during optimization to prevent monoculture."
    Tiannara.RealityGraph.add_node(:principle, %{
      principle: principle, derived_from: result.experiment_id, confidence: result.confidence
    })
    {:noreply, state}
  end
end
