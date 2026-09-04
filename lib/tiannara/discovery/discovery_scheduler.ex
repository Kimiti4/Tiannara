defmodule Tiannara.Discovery.DiscoveryScheduler do
  use GenServer
  require Logger

  alias Tiannara.Discovery.{
    Events,
    Discovery,
    DiscoveryScore,
    GapAnalyzer,
    ContradictionAnalyzer,
    HypothesisGenerator,
    PredictionEngine,
    ExperimentPlanner,
    DiscoveryPrioritizer,
    DiscoveryEngine
  }

  alias Tiannara.World.{UnifiedRealityGraph, UnifiedWorldModel}
  alias Tiannara.Discovery.Domain.KnowledgeGap
  alias Tiannara.Discovery.Quality.DiscoveryQualityAssessor
  alias Tiannara.Discovery.Topics
  alias Tiannara.CEL.Models.CivilizationalEvent
  alias Tiannara.CEL.Services.EventBus

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    interval = Keyword.get(opts, :interval_ms, 30 * 60 * 1000)
    schedule_next(interval)

    # CapabilityGraph is booted before this scheduler by ControlCenter, so the
    # step modules can register themselves as providers for their capabilities.
    # Guarded: a graph that is down degrades registration, never the boot.
    _ = Tiannara.Discovery.Steps.ProviderSeeder.register()

    subscribe_runtime()

    {:ok,
     %{
       interval: interval,
       active_discoveries: %{},
       active_workflows: %{},
       completed_evidence_events: 0,
       cycle_count: 0,
       last_cycle: nil,
       completed_cycles: 0,
       total_gaps_detected: 0,
       total_hypotheses_generated: 0,
       total_predictions_generated: 0,
       total_experiments_planned: 0,
       total_experiments_executed: 0,
       last_cycle_at: nil
     }}
  end

  # The completion broadcasts from WorkflowEngine arrive on the bus envelope
  # `{:event, %CivilizationalEvent{}}`; the scheduler listens so it can route
  # executed evidence into DiscoveryEngine and complete the discovery edge.
  defp subscribe_runtime do
    try do
      EventBus.subscribe("workflow.completed")
      EventBus.subscribe("workflow.failed")
    rescue
      _ -> :ok
    catch
      :exit, _ -> :ok
    end
  end

  def trigger_cycle, do: GenServer.call(__MODULE__, :trigger_cycle)
  def get_stats, do: GenServer.call(__MODULE__, :get_stats)

  def handle_call(:trigger_cycle, _from, state) do
    new_state = run_cycle(state)

    {:reply, :ok,
     %{state | cycle_count: state.cycle_count + 1, last_cycle: DateTime.utc_now()}
     |> Map.merge(
       Map.take(new_state, [
         :completed_cycles,
         :total_gaps_detected,
         :total_hypotheses_generated,
         :total_predictions_generated,
         :total_experiments_planned,
         :total_experiments_executed,
         :last_cycle_at,
         :active_workflows,
         :completed_evidence_events
       ])
     )}
  end

  def handle_call(:get_stats, _from, state), do: {:reply, state, state}

  def handle_info(:run_cycle, state) do
    new_state = run_cycle(state)
    schedule_next(state.interval)

    {:noreply,
     %{state | cycle_count: state.cycle_count + 1, last_cycle: DateTime.utc_now()}
     |> Map.merge(
       Map.take(new_state, [
         :completed_cycles,
         :total_gaps_detected,
         :total_hypotheses_generated,
         :total_predictions_generated,
         :total_experiments_planned,
         :total_experiments_executed,
         :last_cycle_at,
         :active_workflows,
         :completed_evidence_events
       ])
     )}
  end

  # WorkflowEngine broadcasts completion on the EventBus (`workflow.completed` /
  # `workflow.failed`); whenever one of the experiments this scheduler started
  # finishes, route the accumulated evidence back into DiscoveryEngine and
  # publish `discovery.completed` so the world model integrates the result.
  def handle_info(
        {:event,
         %CivilizationalEvent{routing_destination: topic, raw_payload: payload}},
        state
      )
      when topic in ["workflow.completed", "workflow.failed"] do
    wf_id = Map.get(payload, :workflow_id)

    case Map.pop(state.active_workflows, wf_id) do
      {nil, _} ->
        {:noreply, state}

      {tracking, remaining} ->
        {:noreply,
         finalize_discovery(%{state | active_workflows: remaining}, tracking, payload)}
    end
  end

  def handle_info({:event, _event}, state), do: {:noreply, state}

  defp schedule_next(interval), do: Process.send_after(self(), :run_cycle, interval)

  # A discovery is a first-class object in DiscoveryEngine too; register it there
  # (when up) so `route_evidence/2` finds it after experiments complete. Falls
  # back to a local encode when the engine process is not running.
  defp register_discovery(gap) do
    with pid when is_pid(pid) <- Process.whereis(DiscoveryEngine),
         {:ok, disc} <- guarded_create_discovery(pid, gap) do
      disc
    else
      _ -> Discovery.from_gap(gap)
    end
  end

  defp guarded_create_discovery(_pid, gap) do
    DiscoveryEngine.create_discovery(gap)
  rescue
    _ -> {:error, :discovery_engine_unavailable}
  catch
    :exit, _ -> {:error, :discovery_engine_unavailable}
  end

  defp finalize_discovery(
         state,
         %{discovery_id: discovery_id, experiment_id: experiment_id, hypothesis_id: hypothesis_id},
         payload
       ) do
    outcome = if Map.get(payload, :outcome) == :success, do: :supported, else: :inconclusive
    evidence = collect_execution_evidence(Map.get(payload, :workflow_id))

    result =
      Tiannara.Discovery.Domain.DiscoveryResult.new(%{
        experiment_id: experiment_id,
        hypothesis_id: hypothesis_id,
        outcome: outcome,
        evidence: evidence,
        confidence_delta: confidence_delta(outcome, evidence)
      })

    route_discovery_evidence(discovery_id, [result])

    events_emitted = Enum.count(evidence)

    if events_emitted > 0 do
      publish_discovery_completed(discovery_id, evidence)

      Events.emit(:discovery_completed, discovery_id, %{
        evidence_routed_count: events_emitted
      })
    end

    Map.update(state, :completed_evidence_events, events_emitted, &(&1 + events_emitted))
  end

  # Evidence-derived confidence delta: the magnitude is proportional to the
  # confidence of the actual step evidence produced by the workflow, instead of
  # a fixed constant. Supported outcomes shift confidence up; inconclusive
  # outcomes leave it essentially unchanged (or slightly down).
  defp confidence_delta(:supported, evidence) do
    case evidence_confidences(evidence) do
      [] -> 0.1
      confs -> round3((Enum.sum(confs) / length(confs)) * 0.2)
    end
  end

  defp confidence_delta(_outcome, evidence) do
    case evidence_confidences(evidence) do
      [] -> 0.0
      confs -> round3((Enum.sum(confs) / length(confs)) * -0.05)
    end
  end

  defp evidence_confidences(evidence) do
    for e <- evidence,
        result = Map.get(e || %{}, :result),
        is_map(result),
        conf = Map.get(result, :confidence),
        is_number(conf),
        do: conf
  end

  defp round3(v), do: Float.round(v, 3)

  # Pulls the accumulated evidence off the finished workflow record itself. The
  # engine attaches the step evidence (`ExperimentStep` returns `:evidence` in
  # its output) to `outcome_evidence` on completion.
  defp collect_execution_evidence(workflow_id) do
    try do
      case Tiannara.CEL.Services.WorkflowEngine.get_workflow(workflow_id) do
        {:ok, wf} when is_map(wf) -> wf.outcome_evidence || []
        _ -> []
      end
    rescue
      _ -> []
    catch
      :exit, _ -> []
    end
  end

  defp route_discovery_evidence(discovery_id, results) do
    try do
      case Process.whereis(DiscoveryEngine) do
        nil ->
          :ok

        _ ->
          _ = DiscoveryEngine.route_evidence(discovery_id, results)
          :ok
      end
    rescue
      _ -> :ok
    catch
      :exit, _ -> :ok
    end
  end

  # Completes the discovery edge: publish on the topic the WorldStateSynchronizer
  # consumes (`discovery.completed`) and supports the WSS entity shape.
  defp publish_discovery_completed(discovery_id, evidence) do
    try do
      EventBus.publish(Topics.discovery_completed(), %{
        discovery_id: discovery_id,
        confidence: 0.8,
        evidence: evidence,
        data: %{
          statement: "Scheduler-completed discovery #{discovery_id}",
          discovery_id: discovery_id,
          evidence_count: length(evidence)
        }
      })

      :ok
    rescue
      _ -> :ok
    catch
      :exit, _ -> :ok
    end
  end

  defp run_cycle(state) do
    cycle_id = "cycle_#{:crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)}"
    Events.emit(:cycle_started, cycle_id, %{interval: state.interval})

    report = fetch_integrity_report()
    gaps = GapAnalyzer.analyze(report) |> GapAnalyzer.rank()

    conflicts = fetch_active_conflicts()

    contradiction_gaps =
      conflicts
      |> ContradictionAnalyzer.analyze()
      |> Map.get(:contradictions, [])
      |> Enum.map(&contradiction_to_gap/1)

    all_gaps = GapAnalyzer.rank(gaps ++ contradiction_gaps)

    Enum.each(all_gaps, fn gap ->
      Events.emit(:gap_detected, cycle_id, %{
        gap_id: gap.id,
        domain: gap.domain,
        severity: gap.severity,
        description: gap.description
      })
    end)

    discoveries =
      all_gaps
      |> Enum.take(5)
      |> Enum.map(fn gap ->
        disc = register_discovery(gap)

        Events.emit(:discovery_created, disc.id, %{
          question: disc.question,
          gap_id: gap.id,
          score: DiscoveryScore.composite(disc.score)
        })

        disc
      end)

    discoveries =
      Enum.map(discoveries, fn disc ->
        hypotheses = HypothesisGenerator.generate(disc.gap)

        Enum.each(hypotheses, fn hyp ->
          Events.emit(:hypothesis_generated, disc.id, %{
            hypothesis_id: hyp.id,
            prior: hyp.prior,
            eig: hyp.expected_information_gain
          })
        end)

        Discovery.add_hypotheses(disc, hypotheses)
      end)

    discoveries =
      Enum.map(discoveries, fn disc ->
        predictions =
          disc.hypotheses
          |> Enum.flat_map(fn hyp ->
            preds = PredictionEngine.generate(hyp)

            Enum.each(preds, fn pred ->
              Events.emit(:prediction_created, disc.id, %{
                prediction_id: pred.id,
                hypothesis_id: pred.hypothesis_id,
                confidence: pred.confidence
              })
            end)

            preds
          end)

        Discovery.add_predictions(disc, predictions)
      end)

    discoveries =
      Enum.map(discoveries, fn disc ->
        experiments =
          disc.hypotheses
          |> Enum.flat_map(fn hyp ->
            hyp_predictions = Enum.filter(disc.predictions, &(&1.hypothesis_id == hyp.id))
            ExperimentPlanner.plan(hyp, hyp_predictions)
          end)

        Enum.each(experiments, fn exp ->
          Events.emit(:experiment_planned, disc.id, %{
            experiment_id: exp.id,
            hypothesis_id: exp.hypothesis_id,
            type: exp.type,
            eig: exp.expected_information_gain
          })
        end)

        Discovery.add_experiments(disc, experiments)
      end)

    discoveries =
      Enum.map(discoveries, fn disc ->
        {:ok, disc} = Discovery.transition(disc, :gap_identified)
        {:ok, disc} = Discovery.transition(disc, :hypotheses_generated)
        {:ok, disc} = Discovery.transition(disc, :predictions_made)
        {:ok, disc} = Discovery.transition(disc, :experiments_planned)
        disc
      end)

    ranked = DiscoveryPrioritizer.rank_with_diversity(discoveries)
    monoculture_warnings = DiscoveryPrioritizer.detect_monoculture(discoveries)
    bottleneck = DiscoveryPrioritizer.systemic_bottleneck(discoveries)

    if monoculture_warnings != [] do
      Logger.warning("DiscoveryScheduler: monoculture detected: #{inspect(monoculture_warnings)}")
    end

    if bottleneck do
      {dim, avg} = bottleneck

      Logger.info(
        "DiscoveryScheduler: systemic bottleneck in #{dim} (avg=#{Float.round(avg, 3)})"
      )
    end

    selected = DiscoveryPrioritizer.select_for_execution(ranked, 3)

    # Fetch the observation surface ONCE per cycle instead of once per dispatched
    # experiment. Each fetch scans up to @world_scan_limit world-model entities,
    # so doing it inside the dispatch loop made this O(dispatches × scan_limit).
    observation_ids = world_observation_ids()

    dispatched =
      Enum.flat_map(selected, fn disc ->
        Enum.map(disc.experiments, fn exp ->
          case dispatch_experiment(disc, exp, observation_ids) do
            {:ok, workflow_id} ->
              Events.emit(:experiment_dispatched, disc.id, %{
                experiment_id: exp.id,
                workflow_id: workflow_id
              })

              {workflow_id, %{
                discovery_id: disc.id,
                experiment_id: exp.id,
                hypothesis_id: exp.hypothesis_id,
                dispatched_at: DateTime.utc_now()
              }}

            {:error, reason} ->
              Logger.warning(
                "DiscoveryScheduler: failed to dispatch #{exp.id}: #{inspect(reason)}"
              )

              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      end)

    active_workflows =
      Enum.reduce(dispatched, state.active_workflows, fn {wf_id, tracking}, acc ->
        Map.put(acc, wf_id, tracking)
      end)
    total_hypotheses = Enum.reduce(discoveries, 0, fn d, acc -> acc + length(d.hypotheses) end)
    total_predictions = Enum.reduce(discoveries, 0, fn d, acc -> acc + length(d.predictions) end)
    total_experiments = Enum.reduce(discoveries, 0, fn d, acc -> acc + length(d.experiments) end)

    # Quality gate: assess all discoveries before completing cycle
    qa_results =
      Enum.map(selected, fn disc ->
        report = DiscoveryQualityAssessor.assess(disc)

        unless report.recommendation in [:pass, :pass_with_warnings] do
          Logger.warning(
            "DiscoveryScheduler: Discovery #{disc.id} failed QA (#{report.recommendation}, score=#{Float.round(report.overall_score, 3)})"
          )
        end

        %{
          discovery_id: disc.id,
          recommendation: report.recommendation,
          score: report.overall_score
        }
      end)

    Events.emit(:cycle_completed, cycle_id, %{
      gaps_detected: length(all_gaps),
      discoveries_created: length(discoveries),
      hypotheses_generated: total_hypotheses,
      predictions_generated: total_predictions,
      experiments_planned: total_experiments,
      experiments_dispatched: length(dispatched),
      discoveries_selected: length(selected),
      monoculture_warnings: length(monoculture_warnings),
      systemic_bottleneck: bottleneck,
      qa_results: qa_results
    })

    %{
      state
      | completed_cycles: state.completed_cycles + 1,
        active_workflows: active_workflows,
        total_gaps_detected: state.total_gaps_detected + length(all_gaps),
        total_hypotheses_generated: state.total_hypotheses_generated + total_hypotheses,
        total_predictions_generated: state.total_predictions_generated + total_predictions,
        total_experiments_planned: state.total_experiments_planned + total_experiments,
        total_experiments_executed: state.total_experiments_executed + length(dispatched),
        last_cycle_at: DateTime.utc_now()
    }
  end

  defp fetch_integrity_report do
    entities = fetch_world_entities()

    if entities == [] do
      %{
        contradiction_rate: 0.0,
        evidence_quality: 0.0,
        stale_theory_rate: 0.0,
        provenance_completeness: 0.0,
        experiment_recommendations: []
      }
    else
      count = length(entities)
      confidences = Enum.map(entities, &entity_confidence/1)
      contradictions = count_contradiction_pairs(entities)

      %{
        contradiction_rate: min(1.0, contradictions / count),
        evidence_quality: Enum.sum(confidences) / count,
        stale_theory_rate: min(1.0, Enum.count(entities, &stale_entity?/1) / count),
        provenance_completeness: provenance_ratio(entities),
        experiment_recommendations: contradiction_recommendations(entities)
      }
    end
  rescue
    _ ->
      %{
        contradiction_rate: 0.0,
        evidence_quality: 0.0,
        stale_theory_rate: 0.0,
        provenance_completeness: 0.0,
        experiment_recommendations: []
      }
  end

  defp fetch_active_conflicts do
    case contradiction_pairs(fetch_world_entities()) do
      [] ->
        %{contradictions: [], contradictions_classified: false, analysis_complete: false}

      pairs ->
        %{contradictions: pairs, contradictions_classified: false, analysis_complete: false}
    end
  rescue
    _ -> %{contradictions: [], contradictions_classified: false, analysis_complete: false}
  end

  @world_scan_limit 500

  # The ExperimentStep measures divergence between two world-model observations;
  # harvest the observation entity ids from the live graph (the same surface the
  # integrity report reads) so the dispatch carries a REAL measurement surface.
  defp world_observation_ids do
    fetch_world_entities()
    |> Enum.filter(&(get_attr(&1, :subtype) == :observation))
    |> Enum.map(&get_attr(&1, :id))
    |> Enum.take(2)
  end

  # Reads the LIVE world model (the same surface the pipeline telemetry and
  # the seeder use) — never the entity struct patterns on persisted terms.
  defp fetch_world_entities do
    if Process.whereis(UnifiedRealityGraph) == nil do
      []
    else
      case UnifiedRealityGraph.query_entities(
             predicate: fn _ -> true end,
             limit: @world_scan_limit
           ) do
        {:ok, ids} ->
          Enum.flat_map(ids, fn id ->
            case UnifiedWorldModel.get_entity(id) do
              {:ok, e} when is_map(e) -> [e]
              _ -> []
            end
          end)

        _ ->
          []
      end
    end
  rescue
    _ -> []
  end

  defp entity_confidence(e), do: Map.get(e, :confidence) || 0.0

  defp entity_attrs(e), do: Map.get(e, :attributes) || %{}

  defp get_attr(e, key) when is_map(e) do
    case Map.fetch(e, key) do
      {:ok, v} -> v
      :error -> Map.get(e, to_string(key))
    end
  end

  defp entity_value(e) do
    case entity_attrs(e) do
      %{"value" => v} -> v
      %{value: v} -> v
      _ -> nil
    end
  end

  defp stale_entity?(e) do
    chain =
      case entity_attrs(e) do
        %{:evidence_chain => c} when is_list(c) -> c
        %{"evidence_chain" => c} when is_list(c) -> c
        _ -> []
      end

    Enum.any?(chain, &(is_binary(&1) and String.contains?(&1, "stale")))
  rescue
    _ -> false
  end

  defp provenance_ratio(entities) do
    with_prov = Enum.count(entities, fn e -> is_map(get_attr(e, :provenance)) end)
    if entities == [], do: 0.0, else: with_prov / length(entities)
  end

  defp count_contradiction_pairs(entities), do: length(contradiction_pairs(entities))

  defp contradiction_pairs(entities) do
    observations = Enum.filter(entities, &(get_attr(&1, :subtype) == :observation))

    observations
    |> Enum.with_index()
    |> Enum.flat_map(fn {a, i} ->
      Enum.drop(observations, i + 1)
      |> Enum.map(fn b -> {a, b} end)
    end)
    |> Enum.filter(fn {a, b} ->
      same_observation_key?(a, b) and
        Tiannara.Logic.Contradiction.detect(claim(a), claim(b)) == :contradiction
    end)
    |> Enum.map(fn {a, b} ->
      %{
        type: :direct,
        domain: get_attr(a, :domain) || get_attr(b, :domain),
        entity_ids: [get_attr(a, :id), get_attr(b, :id)],
        description:
          "Direct observation contradiction between #{get_attr(a, :id)} and #{get_attr(b, :id)}"
      }
    end)
  end

  defp claim(e), do: %{subject: key_of(e), value: entity_value(e)}

  defp same_observation_key?(a, b) do
    key_of(a) != nil and key_of(a) == key_of(b)
  end

  defp key_of(e) do
    case entity_attrs(e) do
      %{property: p} -> p
      %{"property" => p} -> p
      _ -> nil
    end
  end

  defp contradiction_to_gap(c) do
    KnowledgeGap.new(%{
      domain: Map.get(c, :domain, :epistemic_consistency),
      description: Map.get(c, :description, "Classified observation contradiction"),
      severity: :high,
      uncertainty: 0.5,
      estimated_impact: Map.get(c, :impact, 0.5),
      recommended_investigation: :resolve_contradictions,
      source: :contradiction_analysis,
      evidence: [%{type: :contradiction, classification: Map.get(c, :classification)}]
    })
  end

  defp contradiction_recommendations(entities) do
    if count_contradiction_pairs(entities) > 0 do
      [
        %{
          domain: :sensor_fusion,
          reason: "Live contradicting observations in the world model",
          type: :resolve_contradictions,
          severity: :medium,
          estimated_impact: 0.6
        }
      ]
    else
      []
    end
  end

  defp dispatch_experiment(disc, exp, observation_ids) do
    workflow_spec = %{
      name: "Discovery Experiment: #{exp.id}",
      steps: [
        %{
          id: "step_execute",
          module: Tiannara.Discovery.Steps.ExperimentStep,
          config: %{},
          input: %{
            discovery_id: disc.id,
            experiment_id: exp.id,
            hypothesis_id: exp.hypothesis_id,
            experiment_design: exp,
            experiment_type: exp.type,
            inputs: observation_ids,
            tolerance: 1.0,
            controls: exp.controls,
            stopping_criteria: exp.stopping_criteria
          }
        },
        %{
          id: "step_validate",
          module: Tiannara.Discovery.Steps.ValidationStep,
          config: %{},
          input: %{
            success_criteria: exp.success_criteria,
            failure_criteria: exp.failure_criteria,
            expected_information_gain: exp.expected_information_gain
          }
        }
      ],
      context: %{
        discovery_id: disc.id,
        experiment_id: exp.id,
        hypothesis_id: exp.hypothesis_id,
        source: :discovery_scheduler
      }
    }

    try do
      Tiannara.CEL.Services.WorkflowEngine.start_workflow(workflow_spec)
    rescue
      e -> {:error, e}
    catch
      :exit, e -> {:error, e}
    else
      {:ok, result} -> {:ok, result}
      other -> other
    end
  end
end
