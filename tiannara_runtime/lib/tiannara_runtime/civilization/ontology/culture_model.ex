defmodule TiannaraRuntime.Civilization.Ontology.CultureModel do
  @moduledoc "Phase 19.2 — Civilizational ontology struct: CultureModel"
  defstruct [:id, :civilization_id, :values, :norms, :language, :education, :knowledge_transmission, :innovation_tolerance, :cooperation, :fingerprint]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.2"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      civilization_id: Map.get(fields, :civilization_id),
      values: Map.get(fields, :values, []),
      norms: Map.get(fields, :norms, []),
      language: Map.get(fields, :language),
      education: Map.get(fields, :education, %{}),
      knowledge_transmission: Map.get(fields, :knowledge_transmission, %{}),
      innovation_tolerance: Map.get(fields, :innovation_tolerance, 0.5),
      cooperation: Map.get(fields, :cooperation, 0.5)
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :civilization_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "cm_#{hash}"
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
