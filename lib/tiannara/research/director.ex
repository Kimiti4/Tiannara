defmodule Tiannara.Research.Director do
  @moduledoc """
  Research Director — the bridge between Sentinel observations and
  experiment planning.

  Receives Sentinel epistemic events, generates testable hypotheses,
  designs experiments, tracks their lifecycle, and feeds results
  back into the learning loop.

  Architecture:
    Sentinel Event → Hypothesis → Experiment → Sandbox → Result → Knowledge
  """
  use GenServer
  require Logger

  alias Tiannara.Research.{Hypothesis, Experiment}

  # ── Public API ──

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Submits a Sentinel event for research investigation.
  Returns generated hypothesis and experiment.
  """
  def investigate_event(event_id, category, observation, opts \\ []) do
    GenServer.call(__MODULE__, {:investigate, event_id, category, observation, opts}, :infinity)
  end

  @doc """
  Returns all active hypotheses.
  """
  def list_hypotheses(status \\ nil) do
    GenServer.call(__MODULE__, {:list_hypotheses, status})
  end

  @doc """
  Returns all experiments, optionally filtered by status.
  """
  def list_experiments(status \\ nil) do
    GenServer.call(__MODULE__, {:list_experiments, status})
  end

  @doc """
  Returns a specific experiment by ID.
  """
  def get_experiment(experiment_id) do
    GenServer.call(__MODULE__, {:get_experiment, experiment_id})
  end

  @doc """
  Returns a specific hypothesis by ID.
  """
  def get_hypothesis(hypothesis_id) do
    GenServer.call(__MODULE__, {:get_hypothesis, hypothesis_id})
  end

  @doc """
  Marks an experiment as approved and ready for execution.
  """
  def approve_experiment(experiment_id) do
    GenServer.call(__MODULE__, {:approve_experiment, experiment_id})
  end

  @doc """
  Records an experiment result from the Execution Sandbox.
  """
  def record_result(experiment_id, result, metrics) do
    GenServer.call(__MODULE__, {:record_result, experiment_id, result, metrics})
  end

  @doc """
  Returns all proposals (backward compatibility with LiveView).
  """
  def all do
    hyps = list_hypotheses()
    exps = list_experiments()
    %{hypotheses: hyps, experiments: exps}
  end

  @doc """
  Returns recommended experiments (backward compatibility with LiveView).
  """
  def recommend_experiments do
    list_experiments(:approved)
  end

  @doc """
  Generates research proposals from open unknowns.
  Each proposal targets an unresolved unknown with an estimated
  uncertainty reduction and explanation.
  """
  def generate_proposals do
    case TiannaraOS.UnknownRegistry.list_open() do
      {:ok, unknowns} ->
        unknowns
        |> Enum.with_index(1)
        |> Enum.map(fn {unknown, idx} ->
          reduction = compute_uncertainty_reduction(unknown)
          %{
            id: "prop_#{unknown.id}",
            target_unknown_id: to_string(unknown.id),
            expected_uncertainty_reduction: reduction,
            reason_explanation: build_reason(unknown)
          }
        end)
      _ -> []
    end
  end

  defp compute_uncertainty_reduction(unknown) do
    base = case unknown.priority do
      :critical -> 0.85
      :high -> 0.70
      :medium -> 0.55
      _ -> 0.40
    end
    Float.round(base + (:rand.uniform() * 0.15 - 0.075), 2)
  end

  defp build_reason(unknown) do
    "Proposal for '#{unknown.question}' - resolves #{unknown.priority}-priority unknown in #{unknown.domain_id}"
  end

  @doc """
  Evaluates research strategy for a domain.
  Returns current gaps, hypotheses, and recommended next experiments.
  """
  def evaluate_strategy(domain) do
    GenServer.call(__MODULE__, {:evaluate_strategy, domain})
  end

  @doc """
  Returns research statistics.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:research_hypotheses, [:set, :public, :named_table])
    :ets.new(:research_experiments, [:set, :public, :named_table])
    Logger.info("[RESEARCH] Research Director initialized.")
    {:ok, %{
      hypotheses_table: :research_hypotheses,
      experiments_table: :research_experiments
    }}
  end

  @impl true
  def handle_call({:investigate, event_id, category, observation, opts}, _from, state) do
    hypothesis = generate_hypothesis(event_id, category, observation, opts)
    :ets.insert(state.hypotheses_table, {hypothesis.id, hypothesis})

    experiment = design_experiment(hypothesis, category, observation)
    :ets.insert(state.experiments_table, {experiment.id, experiment})

    # Link experiment to hypothesis
    updated_hyp = %{hypothesis | experiment_id: experiment.id}
    :ets.insert(state.hypotheses_table, {updated_hyp.id, updated_hyp})

    Logger.info("[RESEARCH] Investigation: #{hypothesis.id} -> #{experiment.id}")
    {:reply, %{hypothesis: updated_hyp, experiment: experiment}, state}
  end

  @impl true
  def handle_call({:list_hypotheses, status_filter}, _from, state) do
    all = :ets.tab2list(state.hypotheses_table) |> Enum.map(fn {_id, h} -> h end)
    result = if status_filter, do: Enum.filter(all, &(&1.status == status_filter)), else: all
    {:reply, Enum.sort_by(result, & &1.created_at, :desc), state}
  end

  @impl true
  def handle_call({:list_experiments, status_filter}, _from, state) do
    all = :ets.tab2list(state.experiments_table) |> Enum.map(fn {_id, e} -> e end)
    result = if status_filter, do: Enum.filter(all, &(&1.status == status_filter)), else: all
    {:reply, Enum.sort_by(result, & &1.created_at, :desc), state}
  end

  @impl true
  def handle_call({:get_experiment, id}, _from, state) do
    result = case :ets.lookup(state.experiments_table, id) do
      [{_key, exp}] -> exp
      [] -> nil
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_hypothesis, id}, _from, state) do
    result = case :ets.lookup(state.hypotheses_table, id) do
      [{_key, hyp}] -> hyp
      [] -> nil
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:approve_experiment, exp_id}, _from, state) do
    result = case :ets.lookup(state.experiments_table, exp_id) do
      [{_key, exp}] ->
        updated = %{exp | status: :approved}
        :ets.insert(state.experiments_table, {exp_id, updated})
        {:ok, updated}
      [] -> {:error, :not_found}
    end
    {:reply, result, state}
  end

  @impl true
  def handle_call({:record_result, exp_id, result, metrics}, _from, state) do
    outcome = case :ets.lookup(state.experiments_table, exp_id) do
      [{_key, exp}] ->
        now = DateTime.utc_now()
        updated = %{exp |
          status: if(result == :success, do: :completed, else: :failed),
          result: result,
          metrics: metrics,
          completed_at: now
        }
        :ets.insert(state.experiments_table, {exp_id, updated})

        # Update the associated hypothesis
        update_hypothesis_from_result(state.hypotheses_table, exp.hypothesis_id, result)
        {:ok, updated}
      [] -> {:error, :not_found}
    end
    {:reply, outcome, state}
  end

  @impl true
  def handle_call({:evaluate_strategy, domain}, _from, state) do
    strategy = evaluate_domain_strategy(state, domain)
    {:reply, strategy, state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    hyps = :ets.tab2list(state.hypotheses_table) |> Enum.map(fn {_id, h} -> h end)
    exps = :ets.tab2list(state.experiments_table) |> Enum.map(fn {_id, e} -> e end)
    {:reply, %{
      total_hypotheses: length(hyps),
      total_experiments: length(exps),
      hypotheses_by_status: Map.new(Enum.group_by(hyps, & &1.status), fn {k, v} -> {k, length(v)} end),
      experiments_by_status: Map.new(Enum.group_by(exps, & &1.status), fn {k, v} -> {k, length(v)} end),
      confirmed_hypotheses: Enum.count(hyps, &(&1.status == :confirmed)),
      refuted_hypotheses: Enum.count(hyps, &(&1.status == :refuted))
    }, state}
  end

  # ── Hypothesis Generation ──

  defp generate_hypothesis(event_id, category, observation, opts) do
    {question, explanation, info_gain} = generate_for_category(category, observation)
    evidence = Map.get(opts, :evidence, [])

    Hypothesis.new(event_id, question, explanation,
      confidence: Map.get(opts, :confidence, 0.5),
      expected_information_gain: info_gain,
      domain: category,
      evidence: evidence,
      alternatives: generate_alternatives(category, observation)
    )
  end

  defp generate_for_category(:scientific, observation) do
    cond do
      String.contains?(observation, "diversity") or String.contains?(observation, "convergence") ->
        {"Is the observed convergence an evolutionary attractor or a selection artifact?",
         "The observed pattern may represent a stable evolutionary attractor state. Testing requires comparing convergence rates against randomized baselines.",
         0.72}

      String.contains?(observation, "discovery") or String.contains?(observation, "novel") ->
        {"Does this discovery represent a genuinely new phenomenon or a rediscovery?",
         "Cross-reference against DiscoveryGenealogy to check for historical precedent. If novel, characterize its epistemic niche.",
         0.85}

      true ->
        {"What causal mechanism produced this observation?",
         "Run controlled perturbation analysis to identify causal factors. Compare against predicted outcomes from existing models.",
         0.60}
    end
  end

  defp generate_for_category(:runtime, observation) do
    cond do
      String.contains?(observation, "memory") or String.contains?(observation, "growth") ->
        {"Is the memory growth pattern a leak or a new stable baseline?",
         "Analyze memory allocation over time. Compare against known good baselines. Check for unreleased references.",
         0.65}

      String.contains?(observation, "degrad") or String.contains?(observation, "slow") ->
        {"What subsystem is causing the performance degradation?",
         "Isolate subsystems and measure individual contribution to latency. Check for cascade effects from dependencies.",
         0.70}

      true ->
        {"Is this runtime behavior normal or pathological?",
         "Compare against historical telemetry. If outside 95th percentile, escalate for investigation.",
         0.55}
    end
  end

  defp generate_for_category(:constitutional, _observation) do
    {"Which constitutional principle is affected by this observation?",
     "Map observation to constitutional principles. Check for violation patterns in historical records.",
     0.80}
  end

  defp generate_for_category(:discovery, _observation) do
    {"How does this discovery relate to existing knowledge?",
     "Query DiscoveryGenealogy for precedent. Check for contradiction with established theories. Measure novelty score.",
     0.75}
  end

  defp generate_for_category(:security, _observation) do
    {"Is this observation a genuine threat or a false positive?",
     "Correlate with multiple independent telemetry sources. Check for known threat patterns. Measure signal-to-noise ratio.",
     0.90}
  end

  defp generate_for_category(_category, _observation) do
    {"What can we learn from this observation?",
     "Record observation, monitor for recurrence, and check for patterns across subsystems.",
     0.40}
  end

  defp generate_alternatives(:scientific, _observation) do
    ["The pattern is a random fluctuation", "The pattern is caused by an unmeasured variable", "The pattern is a measurement artifact"]
  end

  defp generate_alternatives(_category, _observation) do
    ["This is a transient condition", "This is a systemic issue"]
  end

  # ── Experiment Design ──

  defp design_experiment(hypothesis, category, observation) do
    procedure = build_procedure(category, observation, hypothesis)
    success_criteria = build_success_criteria(category, hypothesis)
    duration = cycle_duration(category)

    Experiment.new(hypothesis.id, procedure,
      success_criteria: success_criteria,
      duration_cycles: duration,
      parameters: %{
        hypothesis_id: hypothesis.id,
        category: category,
        observation: observation,
        expected_information_gain: hypothesis.expected_information_gain
      },
      rollback_plan: "Restore pre-experiment snapshot for #{category}"
    )
  end

  defp build_procedure(:scientific, observation, _hypothesis) do
    "1. Create control group with current parameters\n" <>
    "2. Create test group with modified parameters based on: #{observation}\n" <>
    "3. Run for designated cycles\n" <>
    "4. Compare metrics between groups\n" <>
    "5. Statistical significance test"
  end

  defp build_procedure(:runtime, _observation, _hypothesis) do
    "1. Isolate suspect subsystem\n" <>
    "2. Measure baseline performance\n" <>
    "3. Apply diagnostic probes\n" <>
    "4. Compare against healthy baseline\n" <>
    "5. Report findings"
  end

  defp build_procedure(:constitutional, _observation, hypothesis) do
    "1. Load constitutional principles\n" <>
    "2. Map hypothesis to affected principles: #{hypothesis.proposed_explanation}\n" <>
    "3. Run CRAV constitutional suite\n" <>
    "4. Report violation score"
  end

  defp build_procedure(_category, _observation, _hypothesis) do
    "1. Observe and record baselines\n" <>
    "2. Monitor for trend confirmation\n" <>
    "3. Escalate if pattern persists"
  end

  defp build_success_criteria(:scientific, hypothesis) do
    "Expected outcome: #{hypothesis.predicted_outcome}. Information gain > #{Float.round(hypothesis.expected_information_gain, 2)}"
  end

  defp build_success_criteria(:runtime, _hypothesis) do
    "Performance returns to within normal parameters. No new anomalies introduced."
  end

  defp build_success_criteria(_category, _hypothesis) do
    "Data collected and analyzed. Clear go/no-go decision possible."
  end

  defp cycle_duration(:scientific), do: 500
  defp cycle_duration(:runtime), do: 100
  defp cycle_duration(:constitutional), do: 50
  defp cycle_duration(_), do: 200

  # ── Result Processing ──

  defp update_hypothesis_from_result(table, hypothesis_id, result) do
    case :ets.lookup(table, hypothesis_id) do
      [{_key, hyp}] ->
        new_status = case result do
          :success -> :confirmed
          :failure -> :refuted
          _ -> :inconclusive
        end
        :ets.insert(table, {hypothesis_id, %{hyp | status: new_status}})
      _ -> :ok
    end
  end

  # ── Strategy Evaluation ──

  defp evaluate_domain_strategy(state, domain) do
    all_hyps = :ets.tab2list(state.hypotheses_table) |> Enum.map(fn {_id, h} -> h end)
    domain_hyps = Enum.filter(all_hyps, &(&1.domain == domain))

    confirmed = Enum.filter(domain_hyps, &(&1.status == :confirmed))
    refuted = Enum.filter(domain_hyps, &(&1.status == :refuted))
    active = Enum.filter(domain_hyps, &(&1.status in [:proposed, :approved, :testing]))
    confirmed_rate = if domain_hyps != [], do: length(confirmed) / length(domain_hyps), else: 0.0

    gaps = identify_knowledge_gaps(domain, domain_hyps)
    recommendations = generate_recommendations(gaps, active)

    %{
      domain: domain,
      hypotheses_tested: length(domain_hyps),
      confirmed: length(confirmed),
      refuted: length(refuted),
      active_investigations: length(active),
      confirmation_rate: Float.round(confirmed_rate, 4),
      knowledge_gaps: gaps,
      next_recommended_experiments: recommendations
    }
  end

  defp identify_knowledge_gaps(:scientific, hypotheses) do
    gaps = []
    gaps = if Enum.count(hypotheses, &(&1.status == :refuted)) > 2, do: [{:theory_instability, "Multiple refuted hypotheses suggest underlying theory gap"} | gaps], else: gaps
    gaps = if length(hypotheses) < 3, do: [{:insufficient_data, "Not enough hypotheses tested for this domain"} | gaps], else: gaps
    gaps
  end

  defp identify_knowledge_gaps(_domain, _hypotheses) do
    [{:monitoring, "Continued observation needed"}]
  end

  defp generate_recommendations(gaps, _active) do
    Enum.map(gaps, fn {_type, description} ->
      %{
        gap: description,
        recommended_action: "Design experiment to address: #{description}",
        priority: if(description =~ "instability", do: :high, else: :medium)
      }
    end)
  end
end
