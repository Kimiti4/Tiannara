defmodule TiannaraRuntime.Civilization.Coordination.CivilizationCoordinator do
  def initialize() do
    {:ok, %{domains: [], collaborations: [], objectives: [], sync_state: %{}}}
  end

  def coordinate(coordinator, domain_a, domain_b, action) do
    record = %{domain_a: domain_a, domain_b: domain_b, action: action, id: :erlang.unique_integer([:positive])}
    {:ok, %{coordinator | collaborations: coordinator.collaborations ++ [record]}}
  end

  def synchronize(coordinator, state) do
    {:ok, %{coordinator | sync_state: state}}
  end

  def metrics(coordinator) do
    {:ok, %{domains: length(coordinator.domains), collaborations: length(coordinator.collaborations), objectives: length(coordinator.objectives)}}
  end
end
