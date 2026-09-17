defmodule TiannaraRuntime.Cognitive.CognitiveSerializer do
  @moduledoc "Phase 18.1 — Canonical serialization for cognitive ontology"

  alias TiannaraRuntime.Shared.Canonical

  def serialize(struct) do
    struct
    |> Map.from_struct()
    |> Map.drop([:id, :fingerprint, :created_at])
    |> Canonical.to_canonical_map()
    |> Canonical.encode!()
  end

  def deserialize(binary, module) do
    case Jason.decode(binary, keys: :atoms) do
      {:ok, map} ->
        {:ok, struct(module, map)}
      {:error, reason} ->
        {:error, "Deserialization failed: #{inspect(reason)}"}
    end
  end

  def stable_hash(struct) do
    struct
    |> serialize()
    |> sha256_hex()
  end

  defp sha256_hex(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end
end
