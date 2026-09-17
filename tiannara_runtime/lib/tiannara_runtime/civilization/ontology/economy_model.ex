defmodule TiannaraRuntime.Civilization.Ontology.EconomyModel do
  @moduledoc "Phase 19.2 — Civilizational ontology struct: EconomyModel"
  defstruct [:id, :civilization_id, :resources, :production, :trade, :consumption, :allocation, :reserve, :capital, :scientific_capital, :fingerprint]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.2"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      civilization_id: Map.get(fields, :civilization_id),
      resources: Map.get(fields, :resources, %{}),
      production: Map.get(fields, :production, %{}),
      trade: Map.get(fields, :trade, %{}),
      consumption: Map.get(fields, :consumption, %{}),
      allocation: Map.get(fields, :allocation, %{}),
      reserve: Map.get(fields, :reserve, %{}),
      capital: Map.get(fields, :capital, %{}),
      scientific_capital: Map.get(fields, :scientific_capital, %{})
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :civilization_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "em_#{hash}"
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
