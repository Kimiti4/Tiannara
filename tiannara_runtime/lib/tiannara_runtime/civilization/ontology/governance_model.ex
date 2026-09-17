defmodule TiannaraRuntime.Civilization.Ontology.GovernanceModel do
  @moduledoc "Phase 19.2 — Civilizational ontology struct: GovernanceModel"
  defstruct [:id, :civilization_id, :constitutional_model, :decision_model, :escalation_paths, :authority_graph, :oversight_graph, :policy_graph, :fingerprint]

  @schema_version 1
  @ontology_version 1
  @created_with_phase "19.2"

  def new(fields) do
    id = generate_id(fields)
    struct = %__MODULE__{
      id: id,
      civilization_id: Map.get(fields, :civilization_id),
      constitutional_model: Map.get(fields, :constitutional_model),
      decision_model: Map.get(fields, :decision_model),
      escalation_paths: Map.get(fields, :escalation_paths, []),
      authority_graph: Map.get(fields, :authority_graph, %{}),
      oversight_graph: Map.get(fields, :oversight_graph, %{}),
      policy_graph: Map.get(fields, :policy_graph, %{})
    }
    fingerprint = compute_fingerprint(struct)
    {:ok, %{struct | fingerprint: fingerprint}}
  end

  def generate_id(fields) do
    base = "#{Map.get(fields, :civilization_id)}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "gm_#{hash}"
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
