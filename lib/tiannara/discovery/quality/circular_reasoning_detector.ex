defmodule Tiannara.Discovery.Quality.CircularReasoningDetector do
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Discovery.Quality.Domain.QualityCheck

  @spec detect(Discovery.t()) :: QualityCheck.t()
  def detect(%Discovery{} = disc) do
    cycles = []

    hyp_cycles = detect_hypothesis_cycles(disc)
    cycles = cycles ++ hyp_cycles

    self_refs = detect_evidence_self_reference(disc)
    cycles = cycles ++ self_refs

    lineage_loops = detect_lineage_loops(disc)
    cycles = cycles ++ lineage_loops

    score = if cycles == [], do: 1.0, else: max(0.0, 1.0 - length(cycles) * 0.3)

    QualityCheck.new(%{
      name: "Circular Reasoning Detection",
      category: :circular_reasoning,
      passed: cycles == [],
      score: score,
      details: if(cycles == [], do: "No circular reasoning detected", else: "#{length(cycles)} circular dependencies found"),
      evidence: cycles
    })
  end

  defp detect_hypothesis_cycles(%Discovery{hypotheses: hypotheses}) do
    hyp_ids = MapSet.new(Enum.map(hypotheses, & &1.id))

    Enum.filter(hypotheses, fn hyp ->
      Map.get(hyp.metadata, :depends_on, []) |> Enum.any?(&MapSet.member?(hyp_ids, &1))
    end)
    |> Enum.map(fn hyp ->
      %{type: :hypothesis_cycle, hypothesis_id: hyp.id, detail: "Hypothesis references itself or creates a cycle"}
    end)
  end

  defp detect_evidence_self_reference(%Discovery{evidence: evidence}) do
    Enum.filter(evidence, fn result ->
      result.experiment_id != nil and
      Enum.any?(result.evidence, fn ev ->
        Map.get(ev, :source) == result.experiment_id
      end)
    end)
    |> Enum.map(fn result ->
      %{type: :evidence_self_reference, result_id: result.id, experiment_id: result.experiment_id}
    end)
  end

  defp detect_lineage_loops(%Discovery{lineage: lineage}) do
    timestamps = Enum.map(lineage, &Map.get(&1, :at))

    non_monotonic =
      timestamps
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.filter(fn [a, b] ->
        a != nil and b != nil and DateTime.compare(a, b) == :gt
      end)

    Enum.map(non_monotonic, fn [a, b] ->
      %{type: :lineage_temporal_loop, from: a, to: b, detail: "Lineage events are not temporally ordered"}
    end)
  end
end
