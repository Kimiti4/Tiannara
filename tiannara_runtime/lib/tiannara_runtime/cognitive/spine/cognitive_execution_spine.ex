defmodule TiannaraRuntime.Cognitive.Spine.CognitiveExecutionSpine do
  @moduledoc """
  The Cognitive Execution Spine — the integration contract through which
  Tiannara's existing cognitive subsystems cooperate.

  This module is **not** a new cognitive core. It contains no reasoning of its
  own: every stage is a call into an engine that already exists in this
  runtime. What it adds is (a) an explicit, ordered contract for the cognitive
  cycle, and (b) a single traceable entry point that runs the cycle and
  records what happened at each stage.

  ## The cycle

  | Stage | Purpose | Engines used |
  |-------|---------|--------------|
  | `:context` | assemble the working context for a mission | `Cognitive.Engines.ContextBuilder` |
  | `:world_model` | build, validate, certify and deploy a model from evidence | `WorldModel.Pipeline.PipelineOrchestrator` |
  | `:hypothesis` | decompose the objective and plan the work | `Cognitive.Planning.GoalDecomposer`, `TaskPlanner` |
  | `:forecast` | estimate confidence and decompose uncertainty | `Cognitive.Metacognition.ConfidenceEstimator`, `UncertaintyAnalyzer` |
  | `:decision` | score candidate courses of action | `Cognitive.Decision.DecisionManager`, `DecisionEvaluator` |
  | `:evidence` | bind the decision to hashed evidence | `Cognitive.Runtime.EvidenceRouter` |
  | `:knowledge` | retain validated knowledge (gate) | knowledge port |
  | `:authorize` | obtain a mandate to act (gate) | authority port |

  ## Gate semantics

  The first six stages are a *chain*: a failure stops the chain and the error
  is returned with the trace that was produced up to that point.

  The last two are *gates*. They are always attempted, they never abort the
  investigation, and their refusal is a legitimate outcome. An unwired Spine
  therefore completes its investigation and reports that it could not retain
  knowledge and could not obtain a mandate — it does not pretend otherwise,
  and it does not weaken the fail-closed behaviour of the subsystems it calls.

  ## Authority

  The Spine coordinates; it never authorises. `authority` and `knowledge` are
  injected as adapters implementing `TiannaraRuntime.Cognitive.Spine.Authority`
  and `TiannaraRuntime.Cognitive.Spine.Knowledge`. The defaults refuse.
  """

  alias TiannaraRuntime.Cognitive.Decision.{DecisionEvaluator, DecisionManager}
  alias TiannaraRuntime.Cognitive.Engines.ContextBuilder
  alias TiannaraRuntime.Cognitive.Metacognition.{ConfidenceEstimator, UncertaintyAnalyzer}
  alias TiannaraRuntime.Cognitive.Planning.{GoalDecomposer, TaskPlanner}
  alias TiannaraRuntime.Cognitive.Runtime.EvidenceRouter
  alias TiannaraRuntime.Cognitive.Spine.Authority
  alias TiannaraRuntime.Cognitive.Spine.Knowledge
  alias TiannaraRuntime.WorldModel.Pipeline.PipelineOrchestrator

  @pipeline_stages [:context, :world_model, :hypothesis, :forecast, :decision, :evidence]
  @gate_stages [:knowledge, :authorize]
  @stages @pipeline_stages ++ @gate_stages

  @doc "The ordered stage list of the Spine."
  @spec stages() :: [atom()]
  def stages, do: @stages

  @doc "The chained (non-gate) stages."
  @spec pipeline_stages() :: [atom()]
  def pipeline_stages, do: @pipeline_stages

  @doc "The terminal gate stages."
  @spec gate_stages() :: [atom()]
  def gate_stages, do: @gate_stages

  @doc """
  Runs one investigation through the whole cycle.

  ## Options
    * `:authority` — module implementing `TiannaraRuntime.Cognitive.Spine.Authority`.
      Defaults to the refusing adapter.
    * `:knowledge` — module implementing `TiannaraRuntime.Cognitive.Spine.Knowledge`.
      Defaults to the refusing adapter.

  ## Returns
    `{:ok, result}` where result carries the trace, the stage outputs, and the
    list of stages that were completed and blocked. A chained-stage failure
    returns `{:error, reason, trace}`.
  """
  @spec run(map(), keyword()) :: {:ok, map()} | {:error, term(), [map()]}
  def run(request, opts \\ []) do
    authority = Keyword.get(opts, :authority, Authority.Refusing)
    knowledge = Keyword.get(opts, :knowledge, Knowledge.Refusing)
    request = normalize_request(request)

    ctx = %{request: request, trace: [], outputs: %{}}

    case run_pipeline_stages(ctx) do
      {:ok, ctx} ->
        ctx = run_gates(ctx, knowledge, authority)
        {:ok, summarize(ctx)}

      {:error, stage, reason, ctx} ->
        {:error, reason, Enum.reverse(ctx.trace) ++ [failure_entry(stage, reason)]}
    end
  end

  # ----------------------------------------------------------------- chain

  defp run_pipeline_stages(ctx) do
    Enum.reduce_while(@pipeline_stages, {:ok, ctx}, fn stage, {:ok, acc} ->
      case run_stage(stage, acc) do
        {:ok, acc} -> {:cont, {:ok, acc}}
        {:error, reason} -> {:halt, {:error, stage, reason, acc}}
      end
    end)
  end

  defp run_stage(stage, ctx) do
    case stage_fun(stage).(ctx) do
      {:ok, outputs} ->
        acc = %{
          ctx
          | trace: [ok_entry(stage, outputs) | ctx.trace],
            outputs: Map.merge(ctx.outputs, %{stage => outputs})
        }

        {:ok, acc}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error -> {:error, {:stage_raised, stage, Exception.message(error)}}
  end

  defp stage_fun(:context), do: &context_stage/1
  defp stage_fun(:world_model), do: &world_model_stage/1
  defp stage_fun(:hypothesis), do: &hypothesis_stage/1
  defp stage_fun(:forecast), do: &forecast_stage/1
  defp stage_fun(:decision), do: &decision_stage/1
  defp stage_fun(:evidence), do: &evidence_stage/1

  # --------------------------------------------------------------- stages

  defp context_stage(ctx) do
    request = ctx.request

    # `Cognitive.Engines.ContextBuilder` builds a `Cognitive.CognitiveContext`,
    # whose id is derived by interpolating the mission — so it requires a
    # String.Chars-able mission. `GoalDecomposer` requires a map. The two
    # engines disagree about the mission shape; the Spine normalises at the
    # seam rather than forcing one shape on every engine.
    {:ok, context} =
      ContextBuilder.build_context(
        mission_label(request.mission),
        request.working_memory,
        request.knowledge_refs
      )

    {:ok, %{context: context}}
  end

  defp mission_label(mission) when is_binary(mission), do: mission

  defp mission_label(mission) when is_map(mission) do
    objective = Map.get(mission, :objective)
    id = Map.get(mission, :id)

    cond do
      is_binary(objective) and is_binary(id) -> "#{id}: #{objective}"
      is_binary(objective) -> objective
      is_binary(id) -> id
      true -> inspect(mission)
    end
  end

  defp mission_label(mission), do: inspect(mission)

  defp world_model_stage(ctx) do
    request = ctx.request

    case PipelineOrchestrator.run_pipeline(
           domain: request.domain,
           name: request.model_name,
           metadata: %{spine: true}
         ) do
      {:ok, result} ->
        model = field(result, :model)
        certificate = field(result, :certificate)
        evidence_set = field(result, :evidence_set)
        variable_set = field(result, :variable_set)

        {:ok,
         %{
           model_id: field(model, :model_id),
           model_name: field(model, :name),
           status: field(model, :status),
           certificate_status: field(certificate, :overall_status),
           observation_count: field(evidence_set, :observation_count),
           variable_count: length(field(variable_set, :variables) || [])
         }}

      {:error, reason} ->
        {:error, {:world_model_pipeline_failed, reason}}
    end
  end

  # `get_in/2` requires the Access protocol, which structs do not implement.
  # Pipeline results contain structs, so fields are read with `Map.fetch/2`,
  # which works for both maps and structs.
  defp field(source, key) when is_map(source) do
    case Map.fetch(source, key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  defp field(_source, _key), do: nil

  defp hypothesis_stage(ctx) do
    request = ctx.request

    with {:ok, decomposition} <- GoalDecomposer.decompose(request.mission),
         {:ok, hierarchy} <- GoalDecomposer.get_hierarchy(decomposition),
         {:ok, plan} <- TaskPlanner.plan(hierarchy) do
      {:ok, %{goal_count: get_in(hierarchy, [:goal_count]), plan: plan}}
    else
      {:error, reason} -> {:error, {:hypothesis_planning_failed, reason}}
    end
  end

  defp forecast_stage(ctx) do
    request = ctx.request
    plan = get_in(ctx.outputs, [:hypothesis, :plan]) || %{}
    evidence = request.evidence

    # `ConfidenceEstimator.estimate/1` takes evidence records (maps carrying a
    # quality), while `UncertaintyAnalyzer.aleatoric/1` takes plain numeric
    # outcomes. The two metacognition engines disagree about the shape of the
    # same evidence, so the Spine derives the numeric series from the records.
    outcomes = Enum.map(evidence, &outcome_value/1)

    with {:ok, confidence} <- ConfidenceEstimator.estimate(evidence),
         {:ok, uncertainty} <- UncertaintyAnalyzer.analyze(request.mission, plan, outcomes) do
      {:ok, %{confidence: confidence, uncertainty: uncertainty}}
    else
      {:error, reason} -> {:error, {:forecast_failed, reason}}
    end
  end

  defp outcome_value(%{quality: value}) when is_number(value), do: value
  defp outcome_value(%{value: value}) when is_number(value), do: value
  defp outcome_value(value) when is_number(value), do: value
  defp outcome_value(_other), do: 0.0

  defp decision_stage(ctx) do
    request = ctx.request
    mission = request.mission
    plan = get_in(ctx.outputs, [:hypothesis, :plan]) || %{}

    session = DecisionManager.create_session(mission, plan)
    candidates = request.candidates

    with {:ok, session} <- DecisionManager.evaluate_candidates(session, candidates) do
      scores = Enum.map(candidates, fn candidate ->
        case DecisionEvaluator.score(candidate) do
          {:ok, score} -> score
          {:error, _reason} -> nil
        end
      end)

      {:ok,
       %{
         session_id: Map.get(session, :session_id),
         status: Map.get(session, :status),
         candidate_count: length(candidates),
         scores: Enum.reject(scores, &is_nil/1)
       }}
    else
      {:error, reason} -> {:error, {:decision_failed, reason}}
    end
  end

  defp evidence_stage(ctx) do
    decision = get_in(ctx.outputs, [:decision]) || %{}

    case EvidenceRouter.route(:cognitive_spine, :decision, decision) do
      {:ok, evidence} -> {:ok, %{evidence_id: evidence.id, input_hash: evidence.input_hash, output_hash: evidence.output_hash}}
      {:error, reason} -> {:error, {:evidence_routing_failed, reason}}
    end
  end

  # ---------------------------------------------------------------- gates

  defp run_gates(ctx, knowledge, authority) do
    ctx = gate(ctx, :knowledge, fn ->
      knowledge.promote(conclusion(ctx), evidence_summary(ctx))
    end)

    gate(ctx, :authorize, fn ->
      authority.authorize(%{
        mission: ctx.request.mission,
        conclusion: conclusion(ctx),
        evidence: evidence_summary(ctx),
        domain: ctx.request.domain
      })
    end)
  end

  defp gate(ctx, stage, fun) do
    case fun.() do
      {:ok, result} ->
        %{
          ctx
          | trace: [ok_entry(stage, result) | ctx.trace],
            outputs: Map.merge(ctx.outputs, %{stage => result})
        }

      {:error, reason} ->
        %{
          ctx
          | trace: [blocked_entry(stage, reason) | ctx.trace],
            outputs: Map.merge(ctx.outputs, %{stage => {:error, reason}})
        }
    end
  rescue
    error ->
      reason = {:gate_raised, stage, Exception.message(error)}

      %{
        ctx
        | trace: [blocked_entry(stage, reason) | ctx.trace],
          outputs: Map.merge(ctx.outputs, %{stage => {:error, reason}})
      }
  end

  # ------------------------------------------------------------- reporting

  defp conclusion(ctx) do
    %{
      domain: ctx.request.domain,
      model: get_in(ctx.outputs, [:world_model]),
      hypothesis: get_in(ctx.outputs, [:hypothesis]),
      forecast: get_in(ctx.outputs, [:forecast]),
      decision: get_in(ctx.outputs, [:decision]),
      evidence: get_in(ctx.outputs, [:evidence])
    }
  end

  defp evidence_summary(ctx) do
    %{
      confidence: get_in(ctx.outputs, [:forecast, :confidence]),
      uncertainty: get_in(ctx.outputs, [:forecast, :uncertainty]),
      evidence_id: get_in(ctx.outputs, [:evidence, :evidence_id])
    }
  end

  defp summarize(ctx) do
    trace = Enum.reverse(ctx.trace)

    %{
      trace: trace,
      outputs: ctx.outputs,
      completed_stages: Enum.filter(trace, &(&1.status == :ok)) |> Enum.map(& &1.stage),
      blocked_stages: Enum.filter(trace, &(&1.status == :blocked)) |> Enum.map(& &1.stage),
      stage_count: length(@stages)
    }
  end

  defp ok_entry(stage, outputs) do
    %{stage: stage, status: :ok, reason: nil, outputs: outputs}
  end

  defp blocked_entry(stage, reason) do
    %{stage: stage, status: :blocked, reason: reason, outputs: %{}}
  end

  defp failure_entry(stage, reason) do
    %{stage: stage, status: :failed, reason: reason, outputs: %{}}
  end

  # -------------------------------------------------------------- request

  defp normalize_request(request) when is_map(request) do
    mission = Map.get(request, :mission) || %{}

    %{
      mission: mission,
      domain: Map.get(request, :domain, :default),
      model_name: Map.get(request, :model_name, "Cognitive Spine Model"),
      working_memory: Map.get(request, :working_memory, %{}),
      knowledge_refs: Map.get(request, :knowledge_refs, []),
      evidence: Map.get(request, :evidence, []),
      candidates: Map.get(request, :candidates, [%{id: "candidate_1", plan: %{}}])
    }
  end

  defp normalize_request(_request) do
    normalize_request(%{})
  end
end
