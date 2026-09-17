defmodule TiannaraRuntime.Civilization.Runtime.InstitutionCoordinator do
  def initialize() do
    {:ok, %{institutions: [], collaborations: [], activity_log: []}}
  end

  def activate(coordinator, institution) do
    {:ok, %{coordinator | institutions: [institution | coordinator.institutions]}}
  end

  def coordinate(coordinator, inst_a, inst_b, domain) do
    collaboration = %{
      id: :erlang.unique_integer([:positive]),
      inst_a: inst_a,
      inst_b: inst_b,
      domain: domain,
      timestamp: :erlang.unique_integer([:positive])
    }
    {:ok, %{coordinator | collaborations: [collaboration | coordinator.collaborations]}}
  end

  def synchronize(coordinator, discoveries) do
    updated = Enum.reduce(discoveries, coordinator, fn discovery, acc ->
      distributed = Enum.reduce(acc.institutions, [], fn inst, discoveries_acc ->
        [%{institution: inst, discovery: discovery} | discoveries_acc]
      end)
      %{acc | activity_log: distributed ++ acc.activity_log}
    end)
    {:ok, updated}
  end

  def metrics(coordinator) do
    {:ok, %{
      institution_count: length(coordinator.institutions),
      collaboration_count: length(coordinator.collaborations),
      activity_count: length(coordinator.activity_log)
    }}
  end

  def validate(coordinator) do
    ids = Enum.map(coordinator.institutions, fn inst -> Map.get(inst, :id) end)
    duplicates = ids -- Enum.uniq(ids)
    if duplicates == [] do
      :ok
    else
      {:error, duplicates}
    end
  end
end
