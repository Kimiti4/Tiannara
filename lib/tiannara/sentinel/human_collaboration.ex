defmodule Tiannara.Sentinel.HumanCollaboration do
  @moduledoc """
  Human Collaboration Interface — explainability layer with evidence chains,
  confidence transparency, and uncertainty communication.

  Translates Sentinel's internal reasoning into human-readable reports that
  explain:
  - What Sentinel observed and why
  - What confidence it has in its conclusions and why
  - What uncertainties or unknowns exist
  - What evidence chains support each finding
  - What actions are recommended and why
  """
  use GenServer
  require Logger

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Generates an explainability report for a given finding or anomaly.
  Returns a structured report with evidence chains and confidence breakdown.
  """
  def explain_finding(finding_type, finding_id) do
    GenServer.call(__MODULE__, {:explain_finding, finding_type, finding_id})
  end

  @doc """
  Generates a comprehensive Sentinel status report for human review.
  """
  def sentinel_status_report do
    GenServer.call(__MODULE__, :sentinel_status_report)
  end

  @doc """
  Generates a confidence report showing what Sentinel is confident about,
  uncertain about, and what it cannot determine.
  """
  def confidence_report do
    GenServer.call(__MODULE__, :confidence_report)
  end

  @doc """
  Records an explanatory note linking an observation to a human-readable reason.
  """
  def record_explanation(observation_id, explanation, confidence) do
    GenServer.cast(__MODULE__, {:record_explanation, observation_id, explanation, confidence})
  end

  @doc """
  Returns the explanation chain for a given observation.
  """
  def get_explanation_chain(observation_id) do
    GenServer.call(__MODULE__, {:get_explanation_chain, observation_id})
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:collab_explanations, [:bag, :public, :named_table])
    :ets.new(:collab_confidence_records, [:bag, :public, :named_table])
    Logger.info("🤝 [COLLAB] Human Collaboration Interface initialized.")
    {:ok, %{
      explanations_table: :collab_explanations,
      confidence_table: :collab_confidence_records
    }}
  end

  @impl true
  def handle_cast({:record_explanation, observation_id, explanation, confidence}, state) do
    entry = {observation_id, explanation, confidence, DateTime.utc_now()}
    :ets.insert(state.explanations_table, entry)
    {:noreply, state}
  end

  @impl true
  def handle_call({:explain_finding, finding_type, finding_id}, _from, state) do
    report = build_explainability_report(state, finding_type, finding_id)
    {:reply, report, state}
  end

  @impl true
  def handle_call(:sentinel_status_report, _from, state) do
    report = build_status_report(state)
    {:reply, report, state}
  end

  @impl true
  def handle_call(:confidence_report, _from, state) do
    report = build_confidence_report(state)
    {:reply, report, state}
  end

  @impl true
  def handle_call({:get_explanation_chain, observation_id}, _from, state) do
    chain = :ets.match_object(state.explanations_table, {observation_id, :_, :_, :_})
    |> Enum.map(fn {_id, explanation, confidence, ts} ->
      %{explanation: explanation, confidence: confidence, timestamp: ts}
    end)
    |> Enum.sort_by(& &1.timestamp, :desc)
    {:reply, chain, state}
  end

  # ── Private Helpers ──

  defp build_explainability_report(state, finding_type, finding_id) do
    explanations = :ets.match_object(state.explanations_table, {finding_id, :_, :_, :_})
    |> Enum.map(fn {_id, explanation, confidence, ts} ->
      %{explanation: explanation, confidence: confidence, timestamp: ts}
    end)
    |> Enum.sort_by(& &1.timestamp, :desc)

    evidence_chain = build_evidence_chain(finding_type, finding_id)

    %{
      finding: %{type: finding_type, id: finding_id},
      explanation_count: length(explanations),
      explanations: explanations,
      evidence_chain: evidence_chain,
      confidence_summary: compute_confidence_summary(explanations),
      uncertainty_analysis: analyze_uncertainty(explanations),
      readability: format_for_humans(finding_type, finding_id, explanations, evidence_chain)
    }
  end

  defp build_evidence_chain(:anomaly, anomaly_id) do
    # Attempt to get causal analysis
    causal = case Code.ensure_loaded?(Tiannara.Sentinel.CausalIntelligence) do
      true ->
        try do
          apply(Tiannara.Sentinel.CausalIntelligence, :analyze_anomaly, [%{key: anomaly_id, severity: :unknown}])
        rescue
          _ -> %{explanations: [%{message: "Causal analysis unavailable"}]}
        end
      false -> %{explanations: [%{message: "Causal Intelligence not loaded"}]}
    end

    %{
      root_cause_analysis: causal[:primary_root_cause],
      causal_pathways: Enum.map(causal[:root_cause_pathways] || [], fn p -> p[:explanations] end) |> List.flatten(),
      detection_method: "Statistical anomaly detection via AnomalyDetector",
      evidence_strength: causal[:confidence] || 0.5
    }
  end

  defp build_evidence_chain(:verification, claim_id) do
    verification = case Code.ensure_loaded?(Tiannara.Sentinel.Verification) do
      true ->
        try do
          confidence = apply(Tiannara.Sentinel.Verification, :claim_confidence, [claim_id])
          contradictions = apply(Tiannara.Sentinel.Verification, :detect_contradictions, [claim_id])
          reproducibility = apply(Tiannara.Sentinel.Verification, :reproducibility_health, [claim_id])
          %{confidence: confidence, contradictions: contradictions, reproducibility: reproducibility}
        rescue
          _ -> %{confidence: %{confidence: 0.5}, contradictions: [], reproducibility: %{}}
        end
      false -> %{confidence: %{confidence: 0.5}, contradictions: [], reproducibility: %{}}
    end

    %{
      claim_id: claim_id,
      confidence_score: verification[:confidence][:confidence] || 0.5,
      supporting_evidence: verification[:confidence][:supporting_count] || 0,
      refuting_evidence: verification[:confidence][:refuting_count] || 0,
      reproducibility: verification[:reproducibility],
      contradictions: verification[:contradictions]
    }
  end

  defp build_evidence_chain(_type, _id) do
    %{message: "No specific evidence chain available for this finding type"}
  end

  defp compute_confidence_summary([]), do: %{average: 0.0, range: {0.0, 0.0}, verdict: "No data"}

  defp compute_confidence_summary(explanations) do
    confidences = Enum.map(explanations, & &1.confidence)
    avg = Enum.sum(confidences) / length(confidences)
    min_c = Enum.min(confidences)
    max_c = Enum.max(confidences)

    verdict = cond do
      avg >= 0.9 -> "Very high confidence"
      avg >= 0.7 -> "High confidence"
      avg >= 0.4 -> "Moderate confidence"
      avg >= 0.2 -> "Low confidence"
      true -> "Very low confidence"
    end

    %{
      average: Float.round(avg, 4),
      range: {Float.round(min_c, 4), Float.round(max_c, 4)},
      verdict: verdict
    }
  end

  defp analyze_uncertainty(explanations) do
    low_conf = Enum.filter(explanations, fn e -> e.confidence < 0.5 end)
    unknowns = Enum.filter(explanations, fn e ->
      String.contains?(to_string(e.explanation), ["unknown", "uncertain", "insufficient"])
    end)

    %{
      low_confidence_findings: length(low_conf),
      explicit_unknowns: length(unknowns),
      gaps: Enum.map(unknowns, & &1.explanation)
    }
  end

  defp format_for_humans(:anomaly, id, explanations, evidence) do
    lines = [
      "🔍 ANOMALY ANALYSIS: #{id}",
      "",
      "What Sentinel observed:",
      "  An anomaly was detected in #{id}. #{length(explanations)} explanation(s) recorded.",
      "",
      "Why it matters:",
    ]

    causal_lines = case evidence do
      %{root_cause_analysis: root} when not is_nil(root) ->
        ["  Likely root cause: #{root}", ""]
      _ ->
        ["  Root cause analysis not yet available", ""]
    end

    evidence_lines = case evidence do
      %{causal_pathways: pathways} when pathways != [] ->
        ["Evidence chain:"] ++ Enum.map(pathways, fn p -> "  → #{p[:message] || p}" end) ++ [""]
      _ -> []
    end

    confidence_lines = [
      "Confidence: #{compute_confidence_summary(explanations).verdict}",
      "  (#{compute_confidence_summary(explanations).average})",
      "",
      "Uncertainties:",
      "  #{analyze_uncertainty(explanations).low_confidence_findings} low-confidence finding(s)",
      "  #{analyze_uncertainty(explanations).explicit_unknowns} explicit unknown(s)"
    ]

    Enum.join(lines ++ causal_lines ++ evidence_lines ++ confidence_lines, "\n")
  end

  defp format_for_humans(:verification, id, explanations, evidence) do
    conf = evidence[:confidence_score] || 0.5
    supporting = evidence[:supporting_evidence] || 0
    refuting = evidence[:refuting_evidence] || 0

    lines = [
      "🔬 VERIFICATION REPORT: #{id}",
      "",
      "Claim confidence: #{Float.round(conf, 4)}",
      "  Supporting evidence: #{supporting}",
      "  Refuting evidence: #{refuting}",
      "",
      "Evidence chain:",
    ]

    rep_lines = case evidence[:reproducibility] do
      %{robustness: r} when not is_nil(r) ->
        ["  Reproducibility: #{r}",
         "  Success rate: #{evidence[:reproducibility][:success_rate] || "N/A"}"]
      _ -> ["  Reproducibility data not yet available"]
    end

    contra_lines = case evidence[:contradictions] do
      [] -> ["  No contradictions detected"]
      c -> ["  ⚠️ #{length(c)} contradiction(s) found:"] ++
           Enum.map(c, fn ct -> "    - #{ct[:claim_a]} vs #{ct[:claim_b]}: #{ct[:detail] || ct[:type]}" end)
    end

    Enum.join(lines ++ rep_lines ++ [""] ++ contra_lines, "\n")
  end

  defp format_for_humans(_type, _id, _explanations, _evidence) do
    "Report format not available for this finding type"
  end

  defp build_status_report(state) do
    explanation_count = :ets.info(state.explanations_table, :size)
    confidence_count = :ets.info(state.confidence_table, :size)

    subsystems = [
      %{
        name: "Universal Observation System",
        module: Tiannara.Sentinel.Observatory,
        status: check_module(Tiannara.Sentinel.Observatory)
      },
      %{
        name: "Scientific Verification",
        module: Tiannara.Sentinel.Verification,
        status: check_module(Tiannara.Sentinel.Verification)
      },
      %{
        name: "Causal Intelligence",
        module: Tiannara.Sentinel.CausalIntelligence,
        status: check_module(Tiannara.Sentinel.CausalIntelligence)
      },
      %{
        name: "Evolutionary Oversight",
        module: Tiannara.Sentinel.EvolutionaryOversight,
        status: check_module(Tiannara.Sentinel.EvolutionaryOversight)
      },
      %{
        name: "Archaeology Management",
        module: Tiannara.Sentinel.ArchaeologyManagement,
        status: check_module(Tiannara.Sentinel.ArchaeologyManagement)
      },
      %{
        name: "SOPL/REA Governance",
        module: Tiannara.Sentinel.Governance,
        status: check_module(Tiannara.Sentinel.Governance)
      },
      %{
        name: "Human Collaboration Interface",
        module: __MODULE__,
        status: :active
      }
    ]

    active_count = Enum.count(subsystems, fn s -> s.status == :active end)
    total = length(subsystems)

    health = cond do
      active_count == total -> :all_systems_operational
      active_count >= total - 1 -> :minor_degradation
      active_count > 0 -> :major_degradation
      true -> :offline
    end

    %{
      generated_at: DateTime.utc_now(),
      sentinel_health: health,
      subsystems: subsystems,
      statistics: %{
        explanations_recorded: explanation_count,
        confidence_records: confidence_count
      },
      operational_summary: "#{active_count}/#{total} Sentinel subsystems active"
    }
  end

  defp build_confidence_report(state) do
    explanations = :ets.tab2list(state.explanations_table)

    confidences = Enum.map(explanations, fn {_id, _exp, conf, _ts} -> conf end)

    known = Enum.count(explanations, fn {_id, _exp, conf, _ts} -> conf >= 0.7 end)
    uncertain = Enum.count(explanations, fn {_id, _exp, conf, _ts} -> conf >= 0.3 and conf < 0.7 end)
    unknown = Enum.count(explanations, fn {_id, _exp, conf, _ts} -> conf < 0.3 end)

    known_pct = if explanations != [], do: Float.round(known / length(explanations) * 100, 1), else: 0.0
    uncertain_pct = if explanations != [], do: Float.round(uncertain / length(explanations) * 100, 1), else: 0.0
    unknown_pct = if explanations != [], do: Float.round(unknown / length(explanations) * 100, 1), else: 0.0

    %{
      total_findings: length(explanations),
      confidence_breakdown: %{
        known: %{count: known, percentage: known_pct},
        uncertain: %{count: uncertain, percentage: uncertain_pct},
        unknown: %{count: unknown, percentage: unknown_pct}
      },
      average_confidence: if(confidences != [],
        do: Float.round(Enum.sum(confidences) / length(confidences), 4),
        else: 0.0
      ),
      assessment: cond do
        known_pct >= 80 -> "Strong epistemic foundation"
        known_pct >= 50 -> "Moderate epistemic foundation — opportunities for improvement"
        known_pct >= 20 -> "Weak epistemic foundation — significant investigation needed"
        true -> "Nascent — most findings are uncertain"
      end
    }
  end

  defp check_module(module) do
    case Process.whereis(module) do
      nil -> :not_running
      pid when is_pid(pid) ->
        if Process.alive?(pid), do: :active, else: :crashed
    end
  rescue
    _ -> :unavailable
  end
end
