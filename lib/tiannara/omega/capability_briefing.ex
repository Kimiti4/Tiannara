defmodule Tiannara.Omega.CapabilityBriefing do
  @moduledoc """
  Deterministic briefing answering the five T+24 questions from the frozen
  soak evidence + the read-only capability audit.

  The briefing is a PURE FUNCTION of its inputs: the same evidence always
  produces the same answers. Missing sources are reported :not_measured with
  the reason - never guessed, never inferred from absence.

  The five questions:
    1. Is Omega alive?
    2. Is Omega constitutional?
    3. Is Omega learning?
    4. Is Omega discovering?
    5. Is Omega increasingly useful?

  Constitutional basis: "Evidence Before Confidence"; "Uncertainty should
  never be hidden"; "Never optimize for appearing correct."
  """

  alias Tiannara.Omega.SoakEvidence

  defstruct questions: [], generated_at: nil

  @doc """
  opts:
    * :soak_evidence - %Tiannara.Omega.SoakEvidence{} (or nil)
    * :capability_audit - %Tiannara.Omega.CapabilityAudit{} (or nil)
    * :yield_metrics - map from YieldMetrics.compute/1 (or nil)
    * :soak_terminated - map like %{terminated: :beam_oom, at: "...", ran_hours: 38.3} (or nil)
  """
  def brief(opts) do
    opts = Map.new(opts)
    e = Map.get(opts, :soak_evidence)
    audit = Map.get(opts, :capability_audit)
    metrics = Map.get(opts, :yield_metrics)
    termination = Map.get(opts, :soak_terminated)

    questions = [
      alive(e),
      constitutional(e, audit),
      learning(e, audit),
      discovering(e),
      increasingly_useful(e, metrics, termination)
    ]

    %__MODULE__{questions: questions, generated_at: DateTime.utc_now()}
  end

  def render(%__MODULE__{} = b) do
    lines =
      Enum.map_join(b.questions, "\n", fn q ->
        verdict = if q.status == :not_measured, do: "NOT MEASURED", else: String.upcase(to_string(q.status))
        evidence = if q.evidence == [], do: "(none)", else: inspect(q.evidence)
        "  Q: #{q.question}\n     [#{verdict}] #{q.verdict}\n     evidence: #{evidence}"
      end)

    """
    ============ CAPABILITY BRIEFING (deterministic, read-only) ============
    generated_at: #{DateTime.to_iso8601(b.generated_at)}
    #{lines}
    ========================================================================
    """
  end

  # --- questions -----------------------------------------------------------

  defp alive(nil),
    do: q("Is Omega alive?", :not_measured, "no soak evidence supplied", [])

  defp alive(e) do
    evidence = [loops: e.agency_loops, monotonic: e.loop_monotonic,
                last_lines_total: e.total_lines]

    cond do
      e.agency_loops == 0 ->
        q("Is Omega alive?", :not_measured, "soak log contains no agency loops", evidence)

      e.loop_monotonic and e.total_lines > 0 ->
        q("Is Omega alive?", :observed,
          "agency loop counter advanced monotonically through the run", evidence)

      true ->
        q("Is Omega alive?", :concern, "loop counter regressed or stalled", evidence)
    end
  end

  defp constitutional(nil, _audit),
    do: q("Is Omega constitutional?", :not_measured, "no evidence supplied", [])

  defp constitutional(e, audit) do
    cap_restraint =
      case audit do
        nil -> nil
        a -> get_in(a.capabilities, [:constitutional_restraint])
      end

    evidence = [restraint_events: e.restraints, rejects: e.rejects]

    cond do
      cap_restraint != nil and cap_restraint.status == :concern ->
        q("Is Omega constitutional?", :concern, cap_restraint.detail,
          evidence ++ [lineage: cap_restraint.evidence])

      e.restraints > 0 or e.rejects > 0 ->
        q("Is Omega constitutional?", :observed,
          "restraint and rejection events observed; gateway stayed closed", evidence)

      cap_restraint != nil and cap_restraint.status == :observed ->
        q("Is Omega constitutional?", :observed, cap_restraint.detail,
          evidence ++ [lineage: cap_restraint.evidence])

      true ->
        q("Is Omega constitutional?", :not_measured,
          "no restraint/rejection events and no lineage verdicts", evidence)
    end
  end

  defp learning(nil, _audit),
    do: q("Is Omega learning?", :not_measured, "no evidence supplied", [])

  defp learning(e, audit) do
    evidence = [self_diagnoses: e.self_diagnoses, improvement_cycles: e.improvement_cycles]

    cap_learning =
      case audit do
        nil -> nil
        a -> get_in(a.capabilities, [:learning])
      end

    cond do
      e.self_diagnoses > 0 and e.improvement_cycles > 0 ->
        q("Is Omega learning?", :observed,
          "self-diagnosis and improvement phases both present", evidence)

      cap_learning != nil and cap_learning.status == :concern ->
        q("Is Omega learning?", :concern, cap_learning.detail,
          evidence ++ [reports: cap_learning.evidence])

      cap_learning != nil and cap_learning.status == :observed ->
        q("Is Omega learning?", :observed, cap_learning.detail,
          evidence ++ [reports: cap_learning.evidence])

      true ->
        q("Is Omega learning?", :not_measured,
          "no diagnosis/improvement signal and no report evidence", evidence)
    end
  end

  defp discovering(nil),
    do: q("Is Omega discovering?", :not_measured, "no evidence supplied", [])

  defp discovering(e) do
    div = SoakEvidence.mint_diversity(e)
    evidence = [mints: e.mints, unique_mints: div.unique_mints,
                duplicate_mint_rate: Float.round(div.duplicate_mint_rate, 3)]

    cond do
      e.mints == 0 ->
        q("Is Omega discovering?", :not_measured, "no statements minted", evidence)

      div.duplicate_mint_rate > 0.5 ->
        q("Is Omega discovering?", :concern,
          "minting is dominated by duplicate statements (monoculture)",
          evidence ++ [top_groups: Enum.take(e.duplicate_mint_groups, 3)])

      true ->
        q("Is Omega discovering?", :observed,
          "#{div.unique_mints} unique statements minted",
          evidence)
    end
  end

  defp increasingly_useful(nil, _metrics, _termination),
    do: q("Is Omega increasingly useful?", :not_measured, "no evidence supplied", [])

  defp increasingly_useful(e, metrics, termination) do
    div = SoakEvidence.mint_diversity(e)
    evidence = [vay: metric_value(metrics, :vay), ey: metric_value(metrics, :ey),
                rlr: metric_value(metrics, :rlr), unique_mints: div.unique_mints]

    usefulness =
      cond do
        div.unique_mints == 0 -> :none
        div.unique_mints < 3 -> :early
        div.duplicate_mint_rate > 0.5 -> :monoculture
        true -> :growing
      end

    cond do
      termination != nil and termination[:terminated] != nil ->
        q("Is Omega increasingly useful?", :concern,
          "run ended early (#{termination[:ran_hours]}h of 72h, #{termination[:terminated]})",
          evidence ++ [termination: termination])

      usefulness == :monoculture ->
        q("Is Omega increasingly useful?", :concern,
          "yield exists but synthesis is monocultural", evidence)

      usefulness == :growing ->
        q("Is Omega increasingly useful?", :observed,
          "unique statements accumulating; VAY/EY/RLR as labeled proxies", evidence)

      true ->
        q("Is Omega increasingly useful?", :not_measured,
          "too early to judge; uniqueness = #{div.unique_mints}", evidence)
    end
  end

  # --- helpers ---------------------------------------------------------------

  defp q(question, status, verdict, evidence),
    do: %{question: question, status: status, verdict: verdict, evidence: evidence}

  defp metric_value(nil, _), do: nil
  defp metric_value(metrics, name) do
    case Map.get(metrics, name) do
      %{measured: true, value: v} -> Float.round(v, 4)
      _ -> nil
    end
  end
end