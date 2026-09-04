defmodule Tiannara.Discovery.Pipeline do
  @moduledoc """
  Deterministic, provenance-preserving scientific discovery engine.

      seed → observation → gap → hypothesis → prediction → experiment →
      scheduling → execution → evidence → knowledge integration →
      validation → discovery

  Guarantees:
    * Determinism — the core path is a pure function of the seed (no RNG).
    * Provenance — every artifact carries lineage/confidence/assumptions/
      unknowns/subsystem/checks.
    * Dispositions — every transition records a canonical disposition
      (advanced / rejected / blocked / failed / deferred / duplicate /
      not_applicable). A disposition reflects the FINAL status of an item;
      an interim :advanced may be superseded by a later :rejected/:blocked.
    * Composability — emits canonical funnel events consumable by
      `Funnel.Integrity`, `PipelinePanel`, and `Discovery.Certificate`.
    * Fault injection — `inject_fault: %{at:, kind:, reason:}` lets adversarial
      tests break any transition and assert the explicit diagnosis.

  Constitutional basis: Scientific Method, Evidence Before Confidence,
  Verification First, Explainability, "Uncertainty should never be hidden."
  """

  alias Tiannara.Discovery.Artifact

  defmodule Run do
    defstruct seed: nil,
              opts: [],
              artifacts: [],
              events: [],
              context: %{},
              halted?: false,
              halt_reason: nil
  end

  @stage_order [
    :observations,
    :gaps,
    :hypotheses,
    :ranked_hypotheses,
    :experiments_proposed,
    :experiments_scheduled,
    :experiments_started,
    :experiments_completed,
    :evidence_generated,
    :knowledge_integrated,
    :discovery_candidates,
    :validated_discoveries
  ]

  def stages, do: @stage_order

  def run(seed, opts \\ []) do
    @stage_order
    |> Enum.reduce(%Run{seed: seed, opts: opts}, fn stage, state ->
      process_stage(state, stage)
    end)
    |> finalize_run()
  end

  # --- orchestration -------------------------------------------------------

  defp process_stage(state, stage) do
    cond do
      state.halted? ->
        state

      faulted_at?(state, stage) ->
        apply_fault(state, stage)

      true ->
        state = advance_previous(state)
        stage_fun(stage).(state)
    end
  end

  defp stage_fun(:observations), do: &observe/1
  defp stage_fun(:gaps), do: &detect_gap/1
  defp stage_fun(:hypotheses), do: &generate_hypotheses/1
  defp stage_fun(:ranked_hypotheses), do: &rank_hypotheses/1
  defp stage_fun(:experiments_proposed), do: &propose_experiments/1
  defp stage_fun(:experiments_scheduled), do: &schedule/1
  defp stage_fun(:experiments_started), do: &start_execution/1
  defp stage_fun(:experiments_completed), do: &complete_execution/1
  defp stage_fun(:evidence_generated), do: &gather_evidence/1
  defp stage_fun(:knowledge_integrated), do: &integrate_knowledge/1
  defp stage_fun(:discovery_candidates), do: &validate_candidates/1
  defp stage_fun(:validated_discoveries), do: &finalize_discoveries/1

  defp faulted_at?(state, stage) do
    case state.opts[:inject_fault] do
      %{at: ^stage} -> true
      _ -> false
    end
  end

  defp advance_previous(state) do
    ids = Map.get(state.context, :current_ids, [])
    stage = Map.get(state.context, :current_stage)

    if stage == nil or ids == [] do
      state
    else
      Enum.reduce(ids, state, fn id, st -> emit_disposition(st, stage, id, :advanced) end)
    end
  end

  defp apply_fault(state, faulted_stage) do
    fault = state.opts[:inject_fault]
    kind = Map.get(fault, :kind, :blocked)
    reason = Map.get(fault, :reason, :injected_fault)

    ids = Map.get(state.context, :current_ids, [])
    stage = Map.get(state.context, :current_stage)

    state =
      if stage == nil or ids == [] do
        state
      else
        Enum.reduce(ids, state, fn id, st ->
          emit_disposition(st, stage, id, kind, reason)
        end)
      end

    %{state | halted?: true, halt_reason: {faulted_stage, kind, reason}}
  end

  # --- stages --------------------------------------------------------------

  defp observe(state) do
    q = state.seed.quantity

    {state, ids} =
      state.seed.observations
      |> Enum.with_index(1)
      |> Enum.reduce({state, []}, fn {o, i}, {st, acc} ->
        id = "obs-#{i}"

        artifact =
          Artifact.new(:observations, Map.put(o, :quantity, q),
            id: id,
            subsystem: :perception,
            assumptions: ["instrument reports are direct readings"]
          )

        st = st |> add_artifact(artifact) |> emit_created(:observations, id, [])
        {st, [id | acc]}
      end)

    set_current(state, :observations, Enum.reverse(ids))
  end

  defp detect_gap(state) do
    q = state.seed.quantity
    tol = Map.get(state.seed, :tolerance, 1)
    values = Enum.map(state.seed.observations, & &1.value)
    spread = Enum.max(values) - Enum.min(values)

    obs_ids = Map.get(state.context, :current_ids, [])

    if spread > tol do
      gap_id = "gap-1"

      artifact =
        Artifact.new(:gaps,
          %{quantity: q, kind: :contradiction, spread: spread, tolerance: tol, values: values},
          id: gap_id,
          lineage: obs_ids,
          subsystem: :gap_detection,
          contradictions: [{:value_disagreement, values}],
          unknowns: ["true value of #{q}"]
        )

      state =
        state
        |> add_artifact(artifact)
        |> emit_created(:gaps, gap_id, obs_ids)
        |> set_current(:gaps, [gap_id])
    else
      state =
        Enum.reduce(obs_ids, state, fn id, st ->
          emit_disposition(st, :observations, id, :not_applicable, :observations_consistent)
        end)

      %{state | halted?: true, halt_reason: {:gaps, :not_applicable, :no_contradiction}}
    end
  end

  defp generate_hypotheses(state) do
    q = state.seed.quantity
    gap_id = "gap-1"

    distinct =
      state.seed.observations |> Enum.map(& &1.value) |> Enum.uniq() |> Enum.sort()

    {hyps, state} =
      distinct
      |> Enum.with_index(1)
      |> Enum.reduce({%{}, state}, fn {v, i}, {map, st} ->
        id = "hyp-#{i}"

        artifact =
          Artifact.new(:hypotheses,
            %{quantity: q, claim: "true value of #{q} is #{v}", candidate_value: v},
            id: id,
            lineage: [gap_id],
            subsystem: :hypothesis_generation,
            assumptions: ["one of the observed values is the true value"],
            unknowns: ["which source is faulty"]
          )

        st = st |> add_artifact(artifact) |> emit_created(:hypotheses, id, [gap_id])
        {Map.put(map, id, v), st}
      end)

    ids = hyps |> Map.keys() |> Enum.sort()

    state
    |> Map.put(:context, Map.put(state.context, :hypotheses, hyps))
    |> set_current(:hypotheses, ids)
  end

  defp rank_hypotheses(state) do
    q = state.seed.quantity
    hyps = Map.get(state.context, :hypotheses, %{})

    {state, ids} =
      hyps
      |> Enum.sort_by(fn {id, _} -> id end)
      |> Enum.with_index(1)
      |> Enum.reduce({state, []}, fn {{hyp_id, v}, i}, {st, acc} ->
        id = "rank-#{i}"

        artifact =
          Artifact.new(:ranked_hypotheses,
            %{
              hypothesis: hyp_id,
              candidate_value: v,
              prediction: "re-measuring #{q} will yield #{v}"
            },
            id: id,
            lineage: [hyp_id],
            subsystem: :prediction,
            confidence: 0.5
          )

        st = st |> add_artifact(artifact) |> emit_created(:ranked_hypotheses, id, [hyp_id])
        {st, [id | acc]}
      end)

    set_current(state, :ranked_hypotheses, Enum.reverse(ids))
  end

  defp propose_experiments(state) do
    q = state.seed.quantity
    exp_id = "exp-1"
    ranked_parents = Map.get(state.context, :current_ids, [])
    hyps = Map.get(state.context, :hypotheses, %{})

    artifact =
      Artifact.new(:experiments_proposed,
        %{quantity: q, design: "calibrated re-measurement of #{q}",
          discriminates: Map.keys(hyps)},
        id: exp_id,
        lineage: ranked_parents,
        subsystem: :experiment_design
      )

    state
    |> add_artifact(artifact)
    |> emit_created(:experiments_proposed, exp_id, ranked_parents)
    |> set_current(:experiments_proposed, [exp_id])
  end

  defp schedule(state) do
    advance_experiment(state, :experiments_scheduled, "sched-1", :scheduled)
  end

  defp start_execution(state) do
    advance_experiment(state, :experiments_started, "start-1", :started)
  end

  defp complete_execution(state) do
    advance_experiment(state, :experiments_completed, "done-1", :completed)
  end

  defp advance_experiment(state, stage, id, status) do
    parent = hd(Map.get(state.context, :current_ids, ["exp-1"]))

    artifact =
      Artifact.new(stage, %{experiment: "exp-1", status: status},
        id: id,
        lineage: [parent],
        subsystem: :experiment_execution
      )

    state
    |> add_artifact(artifact)
    |> emit_created(stage, id, [parent])
    |> set_current(stage, [id])
  end

  defp gather_evidence(state) do
    q = state.seed.quantity
    world = state.seed.world
    runs = Map.get(state.seed, :reproducibility_runs, 3)
    measurements = for _ <- 1..runs, do: measure(world, q)
    value = hd(measurements)
    reproducible? = Enum.all?(measurements, &(&1 == value))

    ev_id = "evidence-1"
    parent = hd(Map.get(state.context, :current_ids, ["done-1"]))

    artifact =
      Artifact.new(:evidence_generated,
        %{quantity: q, measured_value: value, runs: runs,
          measurements: measurements, reproducible: reproducible?},
        id: ev_id,
        lineage: [parent],
        subsystem: :experiment_execution,
        confidence: if(reproducible?, do: 0.8, else: 0.4)
      )

    state
    |> add_artifact(artifact)
    |> emit_created(:evidence_generated, ev_id, [parent])
    |> Map.put(:context, Map.put(state.context, :measured_value, value))
    |> set_current(:evidence_generated, [ev_id])
  end

  defp integrate_knowledge(state) do
    k_id = "knowledge-1"
    parent = hd(Map.get(state.context, :current_ids, ["evidence-1"]))
    value = Map.get(state.context, :measured_value)
    q = state.seed.quantity

    artifact =
      Artifact.new(:knowledge_integrated,
        %{quantity: q, integrated_value: value,
          principle: "measurement of #{q} reconciled to #{value}"},
        id: k_id,
        lineage: [parent],
        subsystem: :memory_evolution,
        checks: [:evidence_before_confidence]
      )

    state
    |> add_artifact(artifact)
    |> emit_created(:knowledge_integrated, k_id, [parent])
    |> set_current(:knowledge_integrated, [k_id])
  end

  defp validate_candidates(state) do
    q = state.seed.quantity
    tol = Map.get(state.seed, :tolerance, 1)
    measured = Map.get(state.context, :measured_value)
    hyps = Map.get(state.context, :hypotheses, %{})
    parent = hd(Map.get(state.context, :current_ids, ["knowledge-1"]))

    {supported, rejected} =
      Enum.split_with(hyps, fn {_id, v} -> abs(v - measured) <= tol end)

    state =
      Enum.reduce(rejected, state, fn {hyp_id, _v}, st ->
        emit_disposition(st, :hypotheses, hyp_id, :rejected, :contradicted_by_evidence)
      end)

    confidence = evidence_confidence(state)

    {state, ids} =
      supported
      |> Enum.sort_by(fn {id, _} -> id end)
      |> Enum.with_index(1)
      |> Enum.reduce({state, []}, fn {{hyp_id, v}, i}, {st, acc} ->
        id = "cand-#{i}"

        artifact =
          Artifact.new(:discovery_candidates,
            %{quantity: q, claim: "true value of #{q} is #{v}",
              hypothesis: hyp_id, measured: measured},
            id: id,
            lineage: [parent, hyp_id],
            subsystem: :validation,
            confidence: confidence,
            checks: [:prediction_matches_evidence, :reproducibility]
          )

        st =
          st
          |> add_artifact(artifact)
          |> emit_created(:discovery_candidates, id, [parent, hyp_id])

        {st, [id | acc]}
      end)

    set_current(state, :discovery_candidates, Enum.reverse(ids))
  end

  defp finalize_discoveries(state) do
    q = state.seed.quantity
    threshold = Map.get(state.seed, :discovery_threshold, 0.7)

    candidates = Enum.filter(state.artifacts, &(&1.stage == :discovery_candidates))

    {state, ids} =
      candidates
      |> Enum.with_index(1)
      |> Enum.reduce({state, []}, fn {cand, i}, {st, acc} ->
        if cand.confidence >= threshold do
          id = "disc-#{i}"

          artifact =
            Artifact.new(:validated_discoveries,
              %{quantity: q, claim: cand.content.claim,
                provenance: provenance_chain(state, cand)},
              id: id,
              lineage: [cand.id],
              subsystem: :discovery,
              confidence: cand.confidence,
              checks: [:full_provenance, :validation_passed, :reproducibility]
            )

          st =
            st
            |> add_artifact(artifact)
            |> emit_created(:validated_discoveries, id, [cand.id])

          {st, [id | acc]}
        else
          st =
            emit_disposition(st, :discovery_candidates, cand.id, :rejected,
              :below_confidence_threshold)

          {st, acc}
        end
      end)

    set_current(state, :validated_discoveries, Enum.reverse(ids))
  end

  # --- helpers -------------------------------------------------------------

  defp finalize_run(state) do
    discoveries = Enum.filter(state.artifacts, &(&1.stage == :validated_discoveries))
    %{state | context: Map.put(state.context, :discoveries, discoveries)}
  end

  defp evidence_confidence(state) do
    case Enum.find(state.artifacts, &(&1.stage == :evidence_generated)) do
      nil -> 0.0
      ev -> if ev.content.reproducible, do: 0.8, else: 0.4
    end
  end

  defp measure(world, quantity), do: Map.fetch!(world, quantity)

  defp provenance_chain(state, artifact),
    do: walk_lineage(state, [artifact.id], MapSet.new(), [])

  defp walk_lineage(_state, [], _seen, acc), do: Enum.reverse(acc)

  defp walk_lineage(state, [id | rest], seen, acc) do
    if MapSet.member?(seen, id) do
      walk_lineage(state, rest, seen, acc)
    else
      seen = MapSet.put(seen, id)

      case Enum.find(state.artifacts, &(&1.id == id)) do
        nil ->
          walk_lineage(state, rest, seen, acc)

        a ->
          walk_lineage(state, a.lineage ++ rest, seen, [{a.stage, a.id} | acc])
      end
    end
  end

  defp emit_created(state, stage, id, parents),
    do: %{state | events: state.events ++ [{:created, stage, id, parents}]}

  defp emit_disposition(state, stage, id, kind, reason \\ nil),
    do: %{state | events: state.events ++ [{:disposition, stage, id, kind, reason}]}

  defp add_artifact(state, artifact),
    do: %{state | artifacts: state.artifacts ++ [artifact]}

  defp set_current(state, stage, ids) do
    ctx =
      state.context
      |> Map.put(:current_ids, ids)
      |> Map.put(:current_stage, stage)

    %{state | context: ctx}
  end
end
