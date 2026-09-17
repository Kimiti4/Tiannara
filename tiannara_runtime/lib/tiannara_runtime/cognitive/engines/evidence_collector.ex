defmodule TiannaraRuntime.Cognitive.Engines.EvidenceCollector do
  @moduledoc "Phase 18.2 — Evidence collection and consolidation engine"

  alias TiannaraRuntime.Cognitive.{EvidenceReference, CognitiveSerializer}

  def collect_transition(mission_id, from, to) do
    hash =
      :crypto.hash(:sha256, "#{mission_id}_#{from}_#{to}")
      |> Base.encode16(case: :lower)
    {:ok, ref} = EvidenceReference.new(%{
      ledger: :transition,
      hash: hash,
      origin: %{mission_id: mission_id, from: from, to: to}
    })
    {:ok, ref}
  end

  def collect_execution(exec_result, context) do
    {:ok, ref} = EvidenceReference.new(%{
      ledger: :execution,
      hash: exec_result.fingerprint,
      origin: %{execution_result_id: exec_result.id, context_id: context.id}
    })
    {:ok, ref}
  end

  def finalize(evidence_list) do
    combined =
      evidence_list
      |> Enum.map(&CognitiveSerializer.serialize/1)
      |> Enum.join("|")
    hash = :crypto.hash(:sha256, combined) |> Base.encode16(case: :lower)
    {:ok, hash}
  end
end
