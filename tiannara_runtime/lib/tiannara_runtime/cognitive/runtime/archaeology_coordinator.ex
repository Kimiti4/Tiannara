defmodule TiannaraRuntime.Cognitive.Runtime.ArchaeologyCoordinator do
  def record(mission, evidence_chain, replay) do
    origin = "mission_#{Map.get(mission, :id)}"
    stages = Map.get(mission, :stages, [])
    subsystem_summaries =
      stages
      |> Enum.with_index()
      |> Enum.map(fn {stage, idx} ->
        "Stage #{idx + 1}: #{stage}"
      end)
    evidence_ids = Enum.map(evidence_chain || [], fn e -> Map.get(e, :id) end)
    replay_status = if Map.get(replay, :mission_root), do: :recorded, else: :missing
    archaeology = %{
      origin: origin,
      mission_narrative: mission_narrative(mission),
      subsystem_summaries: subsystem_summaries,
      evidence_lineage: evidence_ids,
      replay_verification: replay_status,
      recorded_at: :erlang.unique_integer([:positive])
    }
    {:ok, archaeology}
  end

  def explain(archaeology) do
    narrative = Map.get(archaeology, :mission_narrative, "")
    summaries = Map.get(archaeology, :subsystem_summaries, [])
    evidence_count = length(Map.get(archaeology, :evidence_lineage, []))
    replay_status = Map.get(archaeology, :replay_verification, :unknown)
    stages_text = if summaries == [], do: "No stages recorded.", else: Enum.join(summaries, "\n")
    explanation = """
    Mission Origin: #{Map.get(archaeology, :origin)}
    Narrative: #{narrative}
    Stages:
    #{stages_text}
    Evidence Items: #{evidence_count}
    Replay Status: #{replay_status}
    """
    {:ok, String.trim(explanation)}
  end

  def summarize(archaeology) do
    {:ok, %{stages: length(Map.get(archaeology, :subsystem_summaries, [])), evidence_count: length(Map.get(archaeology, :evidence_lineage, [])), origin: Map.get(archaeology, :origin)}}
  end

  defp mission_narrative(mission) do
    status = Map.get(mission, :status, :unknown)
    stages = Map.get(mission, :stages, [])
    "Mission #{Map.get(mission, :id)} was #{status} across #{length(stages)} stage(s)."
  end
end
