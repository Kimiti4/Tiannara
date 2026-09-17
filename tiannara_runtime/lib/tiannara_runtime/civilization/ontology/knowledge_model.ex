defmodule TiannaraRuntime.Civilization.Ontology.KnowledgeModel do
  @moduledoc "Phase 19.2 — Civilizational ontology struct: KnowledgeModel"
  defstruct [:id, :civilization_id, :repositories, :research_programs, :theories, :proofs, :scientific_capital, :knowledge_entropy, :knowledge_continuity, :fingerprint]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.2"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      civilization_id: Map.get(fields, :civilization_id),
      repositories: Map.get(fields, :repositories, []),
      research_programs: Map.get(fields, :research_programs, []),
      theories: Map.get(fields, :theories, []),
      proofs: Map.get(fields, :proofs, []),
      scientific_capital: Map.get(fields, :scientific_capital, 0.0),
      knowledge_entropy: Map.get(fields, :knowledge_entropy, 0.0),
      knowledge_continuity: Map.get(fields, :knowledge_continuity, 1.0)
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :civilization_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "km_#{hash}"
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
