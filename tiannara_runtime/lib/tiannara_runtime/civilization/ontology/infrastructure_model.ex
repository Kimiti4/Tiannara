defmodule TiannaraRuntime.Civilization.Ontology.InfrastructureModel do
  @moduledoc "Phase 19.2 — Civilizational ontology struct: InfrastructureModel"
  defstruct [:id, :civilization_id, :energy, :transport, :communication, :water, :food, :manufacturing, :digital, :scientific, :medical, :security, :fingerprint]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.2"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      civilization_id: Map.get(fields, :civilization_id),
      energy: Map.get(fields, :energy, %{}),
      transport: Map.get(fields, :transport, %{}),
      communication: Map.get(fields, :communication, %{}),
      water: Map.get(fields, :water, %{}),
      food: Map.get(fields, :food, %{}),
      manufacturing: Map.get(fields, :manufacturing, %{}),
      digital: Map.get(fields, :digital, %{}),
      scientific: Map.get(fields, :scientific, %{}),
      medical: Map.get(fields, :medical, %{}),
      security: Map.get(fields, :security, %{})
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :civilization_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "im_#{hash}"
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
