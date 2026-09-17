defmodule TiannaraRuntime.Civilization.Portfolio.ResearchProgramRegistry do
  def initialize() do
    {:ok, %{programs: %{}, ordered_ids: []}}
  end

  def register(registry, program) do
    id = Map.get(program, :id)
    if Map.has_key?(registry.programs, id) do
      {:error, {:duplicate, id}}
    else
      {:ok, %{registry | programs: Map.put(registry.programs, id, program), ordered_ids: registry.ordered_ids ++ [id]}}
    end
  end

  def archive(registry, program_id) do
    case Map.get(registry.programs, program_id) do
      nil -> {:error, :not_found}
      program -> {:ok, %{registry | programs: Map.put(registry.programs, program_id, Map.put(program, :status, :archived))}}
    end
  end

  def lookup(registry, program_id) do
    case Map.get(registry.programs, program_id) do
      nil -> {:error, :not_found}
      program -> {:ok, program}
    end
  end

  def list_by_domain(registry, domain) do
    filtered = Enum.filter(registry.programs, fn {_id, p} -> Map.get(p, :domain) == domain end)
    {:ok, Enum.map(filtered, fn {_id, p} -> p end)}
  end

  def validate(registry) do
    errors = Enum.reduce(registry.ordered_ids, [], fn id, acc ->
      program = Map.get(registry.programs, id)
      prog_errors = cond do
        is_nil(program) -> [{:broken_reference, id}]
        is_nil(Map.get(program, :id)) -> [{:missing_field, :id}]
        is_nil(Map.get(program, :domain)) -> [{:missing_field, :domain}]
        true -> []
      end
      acc ++ prog_errors
    end)
    ids = Enum.map(registry.ordered_ids, fn id -> id end)
    duplicates = ids -- Enum.uniq(ids)
    all_errors = errors ++ Enum.map(duplicates, &{:duplicate_id, &1})
    if all_errors == [], do: :ok, else: {:error, all_errors}
  end
end
