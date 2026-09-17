defmodule TiannaraRuntime.Cognitive.Metacognition.IntrospectionEngine do
  @moduledoc "Phase 18.8 — Introspect session against constitutional constraints"

  def introspect(session, constitution) do
    aspects = [:determinism, :replay, :archaeology, :evidence, :bias]
    findings = Enum.map(aspects, fn aspect ->
      {:ok, finding} = check_finding(aspect, session, constitution)
      finding
    end)
    {:ok, %{trigger: Map.get(constitution, :trigger, :manual), findings: findings, status: :completed, completed_at: :erlang.unique_integer([:positive])}}
  end

  def check_finding(aspect, session, _constitution) do
    {result, severity, recommendation} = case aspect do
      :determinism ->
        if is_list(Map.get(session, :evidence)),
          do: {:pass, 0.0, "Determinism maintained"},
          else: {:fail, 0.6, "Evidence is not a list"}
      :replay ->
        evidence = Map.get(session, :evidence, [])
        if length(evidence) > 0,
          do: {:pass, 0.0, "Replay evidence exists"},
          else: {:fail, 0.6, "No replay evidence found"}
      :archaeology ->
        if is_nil(Map.get(session, :archaeology)),
          do: {:fail, 0.6, "No archaeology data recorded"},
          else: {:pass, 0.0, "Archaeology data intact"}
      :evidence ->
        if is_nil(Map.get(session, :evidence_chain)),
          do: {:fail, 0.6, "No evidence chain configured"},
          else: {:pass, 0.0, "Evidence chain present"}
      :bias ->
        bias_count = length(Map.get(session, :bias_assessments, []))
        if bias_count == 0,
          do: {:fail, 0.6, "No bias assessments present"},
          else: {:pass, 0.0, "Bias assessments present"}
    end
    {:ok, %{aspect: aspect, result: result, severity: severity, recommendation: recommendation}}
  end

  def summarize(introspection) do
    findings = Map.get(introspection, :findings, [])
    pass_count = Enum.count(findings, fn f -> Map.get(f, :result) == :pass end)
    fail_count = Enum.count(findings, fn f -> Map.get(f, :result) == :fail end)
    warn_count = Enum.count(findings, fn f -> Map.get(f, :result) == :warning end)
    total = length(findings)
    {:ok, "#{pass_count} passed, #{fail_count} failed, #{warn_count} warning out of #{total} aspects"}
  end
end
