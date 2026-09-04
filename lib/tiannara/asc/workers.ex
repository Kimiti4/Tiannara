defmodule Tiannara.ASC.Workers.Metrics do
  @moduledoc "Observation worker. Returns REAL VM telemetry — no mocks needed."

  def handle_request(:snapshot, state) do
    {:reply,
     {:ok,
      %{
        at: System.system_time(:millisecond),
        memory: :erlang.memory(),
        run_queue: :erlang.statistics(:run_queue),
        reductions: elem(:erlang.statistics(:reductions), 1),
        process_count: :erlang.system_info(:process_count)
      }}, state}
  end
end

defmodule Tiannara.ASC.Workers.Research do
  @moduledoc """
  MOCK-LEVEL at B: retrieval over the KnowledgeStore. Real corpus ingestion
  is Milestone C.
  """

  alias Tiannara.ASC.Core.KnowledgeStore

  def handle_request({:query, trace_id, topic}, state) do
    hits = KnowledgeStore.search(topic)

    {:reply,
     {:ok,
      %{
        trace_id: trace_id,
        topic: topic,
        hit_count: length(hits),
        source: :knowledge_store,
        confidence: :mock_level
      }}, state}
  end
end

defmodule Tiannara.ASC.Workers.SelfEvaluation do
  @moduledoc "Runs the standing self-evaluation questions against a subject."

  def handle_request({:assess, subject}, state) do
    report = %{
      subject: subject,
      assumptions: ["B-scope handlers are mock-level", "KnowledgeStore is ETS-only (no DETS persistence yet)"],
      contradictions: [],
      largest_bottleneck: :knowledge_persistence,
      missing_knowledge: ["real corpus statistics", "worker crash-rate under load"],
      next_experiment: "Persist KnowledgeStore through the Milestone A DETS layer"
    }

    {:reply, {:ok, report}, state}
  end
end

defmodule Tiannara.ASC.Workers.Evolution do
  @moduledoc """
  MOCK-LEVEL at B: deterministic trivial candidates. Real
  generate/benchmark loop is Milestone C.
  """

  def handle_request({:generate, n}, state) when is_integer(n) and n > 0 do
    candidates =
      for i <- 1..n,
          do: %{id: {:candidate, i}, genome: [rem(i, 3), rem(i, 5)], origin: :mock_level}

    {:reply, {:ok, candidates}, state}
  end
end