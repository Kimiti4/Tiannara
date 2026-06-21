defmodule Tiannara.ASC.Requirements.Extractor do
  @moduledoc """
  Pure function module for extracting structured requirements from a project goal string.

  ## Phase E.1 — Rule-Based Heuristics

  No LLM required. The extractor uses linguistic pattern matching to classify
  goal fragments into the four `ProjectWorld` requirement types.

  Phase I (MetaLearning) will refine extraction patterns from cross-project evidence
  as the corpus grows.

  ## Extraction Strategy

  - **Invariants**   — negation + obligation keywords ("must", "cannot", "never", "shall not")
  - **Capabilities** — action verb + subject patterns ("create X", "list Y", "delete Z")
  - **Constraints**  — measurable numeric limits ("under 100ms", "at least 99.9%", "max 10 requests")
  - **Risks**        — uncertainty and failure markers ("may fail", "could", "risk of", "if X then failure")

  ## Usage

      iex> world = Extractor.extract("user_id must be unique. Balance cannot go below zero. Respond under 100ms.")
      iex> [inv | _] = world.invariants
      iex> inv.statement
      "user_id must be unique"
  """

  alias Tiannara.ASC.ProjectWorld
  alias Tiannara.ASC.ProjectWorld.{Invariant, Capability, Constraint, Risk}

  # Verb patterns for capability extraction (most-specific first)
  @capability_verbs ~w(
    create add register open submit
    read get fetch list retrieve query find search view display show
    update edit modify patch change set
    delete remove close cancel archive
    send notify alert publish broadcast
    validate verify check audit
    calculate compute generate produce
    transfer move convert
    login authenticate authorize
    export import sync
  )

  # Constraint detection regexes
  @latency_re     ~r/(\d+(?:\.\d+)?)\s*(ms|milliseconds?|seconds?)\b/i
  @throughput_re  ~r/(\d+(?:[,_]\d+)?(?:\.\d+)?)\s*(req\/s|rps|requests?\s+per\s+second|tps)/i
  @percent_re     ~r/(\d+(?:\.\d+)?)\s*%/i

  # Risk markers
  @risk_markers ["may fail", "might fail", "could fail", "risk of", "risk", "failure if",
                 "outage", "at risk", "vulnerable", "breach", "if not"]

  # Must / should / may patterns
  @must_words   ["must", "shall", "cannot", "can't", "never", "not allowed", "forbidden", "required"]
  @should_words ["should", "ought to", "recommended", "preferred"]

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  @doc """
  Extract a populated `%ProjectWorld{}` from a raw goal string.

  Splits the goal into sentence fragments and classifies each according to
  the heuristic rules above.
  """
  @spec extract(String.t(), keyword()) :: ProjectWorld.t()
  def extract(goal_string, _opts \\ []) do
    sentences = split_sentences(goal_string)

    invariants   = extract_invariants(sentences)
    capabilities = extract_capabilities(sentences)
    constraints  = extract_constraints(sentences)
    risks        = extract_risks(sentences)
    acceptance   = extract_acceptance_criteria(sentences)

    ProjectWorld.put_requirements(
      ProjectWorld.new(),
      invariants,
      capabilities,
      constraints,
      risks,
      acceptance
    )
  end

  # ---------------------------------------------------------------------------
  # Sentence splitting
  # ---------------------------------------------------------------------------

  defp split_sentences(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.split(~r/[.!?\n;,]/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(String.length(&1) < 5))
  end

  # ---------------------------------------------------------------------------
  # Invariant extraction
  # ---------------------------------------------------------------------------

  defp extract_invariants(sentences) do
    Enum.flat_map(sentences, fn sentence ->
      lower = String.downcase(sentence)

      cond do
        contains_any?(lower, @must_words) ->
          domain = classify_invariant_domain(lower)
          [Invariant.new(sentence,
            strength: :must,
            domain: domain,
            source_fragment: sentence,
            negation_form: negate_statement(sentence)
          )]

        contains_any?(lower, @should_words) ->
          domain = classify_invariant_domain(lower)
          [Invariant.new(sentence,
            strength: :should,
            domain: domain,
            source_fragment: sentence
          )]

        true -> []
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Capability extraction
  # ---------------------------------------------------------------------------

  defp extract_capabilities(sentences) do
    Enum.flat_map(sentences, fn sentence ->
      lower  = String.downcase(sentence)
      words  = String.split(lower)

      found_verb = Enum.find(@capability_verbs, fn verb ->
        verb_words = String.split(verb)
        vlen = length(verb_words)
        Enum.any?(0..(length(words) - vlen), fn i ->
          Enum.slice(words, i, vlen) == verb_words
        end)
      end)

      case found_verb do
        nil  -> []
        verb ->
          subject = subject_after_verb(words, verb)
          actor   = infer_actor(lower)
          [Capability.new("#{verb} #{subject}",
            actor: actor,
            source_fragment: sentence
          )]
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Constraint extraction
  # ---------------------------------------------------------------------------

  defp extract_constraints(sentences) do
    Enum.flat_map(sentences, fn sentence ->
      lower = String.downcase(sentence)
      acc   = []

      # Latency
      acc = case Regex.run(@latency_re, sentence) do
        [_, value, unit] ->
          normalized = if String.starts_with?(String.downcase(unit), "s") and
                          not String.starts_with?(String.downcase(unit), "ms"), do: :s, else: :ms
          [Constraint.new(:latency, "response_time", :lte, parse_float(value),
            unit: normalized, source_fragment: sentence) | acc]
        _ -> acc
      end

      # Throughput
      acc = case Regex.run(@throughput_re, sentence) do
        [_, value, _unit] ->
          numeric = value |> String.replace(~r/[,_]/, "") |> parse_float()
          [Constraint.new(:throughput, "throughput", :gte, numeric,
            unit: :rps, source_fragment: sentence) | acc]
        _ -> acc
      end

      # Availability / percentage
      acc = case Regex.run(@percent_re, sentence) do
        [_, value] ->
          if contains_any?(lower, ["available", "availability", "uptime", "sla"]) do
            [Constraint.new(:availability, "availability", :gte, parse_float(value),
              unit: :percent, source_fragment: sentence) | acc]
          else
            acc
          end
        _ -> acc
      end

      acc
    end)
  end

  # ---------------------------------------------------------------------------
  # Risk extraction
  # ---------------------------------------------------------------------------

  defp extract_risks(sentences) do
    Enum.flat_map(sentences, fn sentence ->
      lower = String.downcase(sentence)

      if contains_any?(lower, @risk_markers) do
        category = classify_risk_category(lower)
        prob     = infer_probability(lower)
        sev      = infer_severity(lower)
        [Risk.new(sentence,
          category: category,
          probability: prob,
          severity: sev,
          source_fragment: sentence
        )]
      else
        []
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Acceptance criteria extraction
  # ---------------------------------------------------------------------------

  defp extract_acceptance_criteria(sentences) do
    markers = ["when ", "given ", "then ", "expect", "verify", "ensure", "assert", "scenario"]
    Enum.filter(sentences, fn s ->
      contains_any?(String.downcase(s), markers)
    end)
  end

  # ---------------------------------------------------------------------------
  # Classification helpers
  # ---------------------------------------------------------------------------

  defp classify_invariant_domain(lower) do
    cond do
      contains_any?(lower, ["unique", "duplicate", "null", "empty", "exist", "integrity",
                             "foreign key", "relation"])  -> :data_integrity
      contains_any?(lower, ["auth", "permission", "access", "secret", "password",
                             "encrypt", "secure", "role", "token"])  -> :security
      contains_any?(lower, ["time", "ms", "second", "latency", "response",
                             "throughput", "fast"])  -> :performance
      contains_any?(lower, ["balance", "payment", "order", "transaction",
                             "account", "price", "invoice", "budget"])  -> :business_logic
      true -> :general
    end
  end

  defp classify_risk_category(lower) do
    cond do
      contains_any?(lower, ["attack", "breach", "inject", "xss", "csrf", "exploit",
                             "vulnerable", "malicious"])  -> :security
      contains_any?(lower, ["data loss", "corrupt", "deleted", "lost", "overwritten"])  -> :data_loss
      contains_any?(lower, ["slow", "latency", "timeout", "overload", "memory",
                             "exhaustion"])  -> :performance
      contains_any?(lower, ["gdpr", "compliance", "regulation", "legal", "audit"])  -> :compliance
      contains_any?(lower, ["third party", "external", "api", "vendor",
                             "service down"])  -> :external
      true -> :reliability
    end
  end

  defp infer_probability(lower) do
    cond do
      contains_any?(lower, ["likely", "probable", "frequent", "often"])  -> 0.7
      contains_any?(lower, ["possible", "may", "might", "could"])  -> 0.4
      contains_any?(lower, ["unlikely", "rare", "edge case", "occasionally"])  -> 0.1
      true -> 0.3
    end
  end

  defp infer_severity(lower) do
    cond do
      contains_any?(lower, ["critical", "catastrophic", "fatal", "data loss",
                             "breach", "outage"])  -> 0.9
      contains_any?(lower, ["major", "significant", "serious", "severe"])  -> 0.7
      contains_any?(lower, ["minor", "small", "low impact", "cosmetic"])  -> 0.3
      true -> 0.5
    end
  end

  defp infer_actor(lower) do
    cond do
      contains_any?(lower, ["user", "customer", "admin", "operator", "human",
                             "client", "end user"])  -> :user
      contains_any?(lower, ["system", "service", "automated", "scheduler",
                             "background", "daemon"])  -> :system
      contains_any?(lower, ["external", "third party", "api", "webhook",
                             "integration"])  -> :external
      true -> :unknown
    end
  end

  # ---------------------------------------------------------------------------
  # Text helpers
  # ---------------------------------------------------------------------------

  defp subject_after_verb(words, verb) do
    verb_words = String.split(verb)
    vlen       = length(verb_words)

    idx = Enum.find_index(0..(length(words) - vlen), fn i ->
      Enum.slice(words, i, vlen) == verb_words
    end)

    case idx do
      nil -> "entity"
      i   ->
        words
        |> Enum.slice(i + vlen, 3)
        |> Enum.reject(&(&1 in ["a", "an", "the", "for", "of", "to", "in", "with"]))
        |> Enum.take(2)
        |> Enum.join(" ")
        |> case do
          ""  -> "entity"
          sub -> sub
        end
    end
  end

  defp negate_statement(statement) do
    lower = String.downcase(statement)
    cond do
      String.contains?(lower, "must be")  ->
        String.replace(statement, ~r/must be/i, "must NOT be")
      String.contains?(lower, "cannot") or String.contains?(lower, "can't") ->
        statement  # already negated
      String.contains?(lower, "must") ->
        String.replace(statement, ~r/must\b/i, "must NOT")
      true ->
        "VIOLATION: #{statement}"
    end
  end

  defp contains_any?(string, patterns) do
    Enum.any?(patterns, &String.contains?(string, &1))
  end

  defp parse_float(str) do
    case Float.parse(str) do
      {f, _} -> f
      :error  -> 0.0
    end
  end
end
