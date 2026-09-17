defmodule TiannaraRuntime.Cognitive.Runtime.EvidenceRouter do
  def route(subsystem, stage, evidence_data) do
    input_hash = :crypto.hash(:sha256, "#{subsystem}#{stage}") |> Base.encode16(case: :lower)
    output_hash = :crypto.hash(:sha256, inspect(evidence_data)) |> Base.encode16(case: :lower)
    id = generate_id(subsystem, stage)
    evidence = %{
      id: id,
      subsystem: subsystem,
      stage: stage,
      input_hash: input_hash,
      output_hash: output_hash,
      evidence_data: evidence_data
    }
    {:ok, evidence}
  end

  def verify(evidence) do
    recomputed_input = :crypto.hash(:sha256, "#{Map.get(evidence, :subsystem)}#{Map.get(evidence, :stage)}") |> Base.encode16(case: :lower)
    recomputed_output = :crypto.hash(:sha256, inspect(Map.get(evidence, :evidence_data))) |> Base.encode16(case: :lower)
    match = recomputed_input == Map.get(evidence, :input_hash) && recomputed_output == Map.get(evidence, :output_hash)
    {:ok, match}
  end

  def chain(mission_id) when is_binary(mission_id) do
    {:ok, [%{mission_id: mission_id, type: :chain_start, sequence: :erlang.unique_integer([:positive])}]}
  end

  def append(chain, evidence) do
    {:ok, chain ++ [evidence]}
  end

  defp generate_id(subsystem, stage) do
    base = "#{subsystem}_#{stage}_#{:erlang.unique_integer([:positive])}"
    hash = :crypto.hash(:sha256, base) |> Base.encode16(case: :lower) |> String.slice(0, 16)
    "ev_#{hash}"
  end
end
