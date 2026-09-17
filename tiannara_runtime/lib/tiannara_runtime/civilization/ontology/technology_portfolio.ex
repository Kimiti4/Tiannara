defmodule TiannaraRuntime.Civilization.Ontology.TechnologyPortfolio do
  @moduledoc "Phase 19.2 — Civilizational ontology struct: TechnologyPortfolio"
  defstruct [:id, :civilization_id, :technologies, :maturity, :dependencies, :replacement_graph, :evolution_graph, :risk, :fingerprint]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.2"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      civilization_id: Map.get(fields, :civilization_id),
      technologies: Map.get(fields, :technologies, []),
      maturity: Map.get(fields, :maturity, %{}),
      dependencies: Map.get(fields, :dependencies, %{}),
      replacement_graph: Map.get(fields, :replacement_graph, %{}),
      evolution_graph: Map.get(fields, :evolution_graph, %{}),
      risk: Map.get(fields, :risk, 0.0)
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :civilization_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "tp_#{hash}"
  end

  def compute_fingerprint(%__MODULE__{} = struct) do
    canonical =
      struct
      |> Map.from_struct()
      |> Map.drop([:id])
      |> Enum.sort_by(fn {k, _} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}:#{inspect(v)}" end)
      |> Enum.join("|")
    :crypto.hash(:sha256, canonical) |> Base.encode16(case: :lower)
  end

  def validate(%__MODULE__{} = _struct) do
    :ok
  end
end
