defmodule Tiannara.ASC.L3.Probe do
  @moduledoc """
  Bounded READ-ONLY cross-subsystem mission.

    Observe -> Research -> Hypothesis -> Design -> Evaluate -> Select
      -> Record knowledge -> Evaluate outcome

  Writes ONLY to the KnowledgeStore (evidence trail). No production code is
  modified — that gate belongs to Milestone C. Hypothesis/design/scoring
  steps are deterministic heuristics, honestly flagged as such.
  """

  alias Tiannara.ASC.Core.{KnowledgeStore, Worker}

  @steps [:observe, :research, :hypothesize, :design, :evaluate, :select, :record, :outcome]

  def run do
    trace_id = "L3-" <> (:crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false))

    with {:ok, snap, trail} <- observe(trace_id, %{}),
         {:ok, research, trail} <- research(trace_id, trail),
         {:ok, hypotheses, trail} <- hypothesize(trace_id, snap, research, trail),
         {:ok, designs, trail} <- design(trace_id, hypotheses, trail),
         {:ok, scored, trail} <- evaluate(trace_id, designs, snap, trail),
         {:ok, selection, trail} <- select(trace_id, scored, trail),
         {:ok, knowledge_id, trail} <- record(trace_id, selection, trail),
         {:ok, verdict} <- outcome(trace_id, knowledge_id, trail) do
      {:ok, verdict}
    else
      {:error, step, reason, trail} ->
        {:error, %{failed_at: step, reason: reason, trace_id: trace_id, trail: trail}}
    end
  end

  defp observe(trace_id, trail) do
    step(trace_id, :observe, trail, fn ->
      {:ok, pid} = Worker.whereis(:metrics)
      {:ok, snap} = Worker.call(:metrics, :snapshot)
      {:ok, snap, %{observe_pid: pid}}
    end)
  end

  defp research(trace_id, trail) do
    step(trace_id, :research, trail, fn ->
      {:ok, pid} = Worker.whereis(:research)
      {:ok, res} = Worker.call(:research, {:query, trace_id, "bottleneck"})
      {:ok, res, %{research_pid: pid}}
    end)
  end

  defp hypothesize(trace_id, snap, research, trail) do
    step(trace_id, :hypothesize, trail, fn ->
      bottleneck =
        case snap.run_queue > 2 do
          true -> :scheduling_pressure
          false -> :memory_footprint
        end

      hyps = [
        %{
          id: :h_batch,
          claim: "Batching worker dispatch reduces run-queue pressure",
          target: bottleneck,
          confidence: :heuristic_v0
        },
        %{
          id: :h_cache,
          claim: "Caching repeated research queries reduces reductions",
          target: bottleneck,
          confidence: :heuristic_v0
        }
      ]

      {:ok, %{hypotheses: hyps, context: research}, %{}}
    end)
  end

  defp design(trace_id, %{hypotheses: hyps} = ctx, trail) do
    step(trace_id, :design, trail, fn ->
      designs =
        Enum.map(hyps, fn h ->
          %{id: {:design, h.id}, hypothesis: h, cost_estimate: 1.0}
        end)

      {:ok, %{designs: designs, context: ctx}, %{}}
    end)
  end

  defp evaluate(trace_id, %{designs: designs} = ctx, snap, trail) do
    step(trace_id, :evaluate, trail, fn ->
      {:ok, se_pid} = Worker.whereis(:self_evaluation)
      {:ok, report} = Worker.call(:self_evaluation, {:assess, :probe_designs})

      scored =
        Enum.map(designs, fn d ->
          d
          |> Map.put(:score, 1.0 / (1.0 + d.cost_estimate))
          |> Map.put(:method, :heuristic_v0)
        end)

      {:ok,
       %{scored: scored, self_evaluation: report, snapshot: snap},
       %{self_evaluation_pid: se_pid}}
    end)
  end

  defp select(trace_id, %{scored: scored} = ctx, trail) do
    step(trace_id, :select, trail, fn ->
      best = Enum.max_by(scored, & &1.score)
      {:ok, %{selection: best, rationale: :argmax_score, context: ctx}, %{}}
    end)
  end

  defp record(trace_id, %{selection: sel} = ctx, trail) do
    step(trace_id, :record, trail, fn ->
      {:ok, id} =
        KnowledgeStore.put(
          :l3_decision,
          %{selection: sel, trace_id: trace_id, read_only: true},
          trace_id: trace_id
        )

      {:ok, id, %{knowledge_id: id}}
    end)
  end

  defp outcome(trace_id, knowledge_id, trail) do
    entries = KnowledgeStore.by_trace(trace_id)
    worker_pids = MapSet.new([trail.observe_pid, trail.research_pid, trail.self_evaluation_pid])

    checks = %{
      trail_complete:
        Enum.all?(@steps -- [:outcome], fn s ->
          Enum.any?(entries, fn {_id, _t, _k, payload, _par, _seq, _ts} ->
            payload |> Map.get(:step) == s
          end)
        end),
      distinct_subsystems: MapSet.size(worker_pids) == 3,
      knowledge_persisted: match?({:ok, _}, KnowledgeStore.get(knowledge_id)),
      lineage_present: length(entries) >= length(@steps),
      read_only_respected:
        Enum.all?(entries, fn {_id, _t, kind, _p, _par, _seq, _ts} ->
          kind in [:evidence, :l3_decision]
        end)
    }

    if Enum.all?(Map.values(checks)) do
      {:ok,
       %{
         verdict: :pass,
         trace_id: trace_id,
         checks: checks,
         subsystems: [:metrics, :research, :self_evaluation, :knowledge_store],
         evidence_entries: length(entries)
       }}
    else
      {:error, :outcome, {:checks_failed, checks}, trail}
    end
  end

  defp step(trace_id, name, trail, fun) do
    case fun.() do
      {:ok, result, extra} ->
        {:ok, _} =
          KnowledgeStore.put(:evidence, %{step: name, summary: summarize(result)},
            trace_id: trace_id
          )

        {:ok, result, Map.merge(trail, extra)}

      {:ok, result} ->
        {:ok, _} =
          KnowledgeStore.put(:evidence, %{step: name, summary: summarize(result)},
            trace_id: trace_id
          )

        {:ok, result, trail}

      {:error, reason} ->
        {:error, name, reason, trail}
    end
  end

  defp summarize(result) when is_map(result) do
    Map.take(result, [:hit_count, :rationale, :score, :id])
    |> Map.put(:keys, Map.keys(result))
  end

  defp summarize(other), do: other
end