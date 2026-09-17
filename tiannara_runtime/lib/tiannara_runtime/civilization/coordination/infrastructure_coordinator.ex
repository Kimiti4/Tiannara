defmodule TiannaraRuntime.Civilization.Coordination.InfrastructureCoordinator do
  def initialize() do
    {:ok, %{shared_resources: %{}, allocations: %{}, requests: []}}
  end

  def request(coordinator, institution, resource, amount) do
    req = %{id: :erlang.unique_integer([:positive]), institution: institution, resource: resource, amount: amount, status: :pending}
    {:ok, %{coordinator | requests: coordinator.requests ++ [req]}}
  end

  def allocate(coordinator, request_id) do
    req = Enum.find(coordinator.requests, fn r -> Map.get(r, :id) == request_id end)
    case req do
      nil -> {:ok, coordinator}
      r ->
        resource = Map.get(r, :resource)
        amount = Map.get(r, :amount)
        available = Map.get(coordinator.shared_resources, resource, 0)
        if available >= amount do
          shared_resources = Map.put(coordinator.shared_resources, resource, available - amount)
          allocations = Map.put(coordinator.allocations, request_id, Map.put(r, :status, :allocated))
          {:ok, %{coordinator | shared_resources: shared_resources, allocations: allocations}}
        else
          {:error, :unavailable}
        end
    end
  end

  def metrics(coordinator) do
    {:ok, %{total_requests: length(coordinator.requests), total_allocations: map_size(coordinator.allocations), shared_resources: map_size(coordinator.shared_resources)}}
  end
end
