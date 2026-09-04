defmodule Tiannara.Sentinel.Verification.Evidence do
  defstruct [
    :id, :claim_id, :type, :source, :timestamp,
    strength: 0.5,
    reproducible: false,
    reproduction_count: 0,
    reproduction_attempts: 0,
    contradicts: [],
    supports: [],
    metadata: %{}
  ]
end

defmodule Tiannara.Sentinel.Verification do
  @moduledoc """
  Scientific Verification Layer — evidence tracking, confidence scoring,
  reproducibility checks, and contradiction detection for discoveries,
  REA experiments, and all epistemic claims within Tiannara.

  Maintains an ETS-backed evidence ledger and provides query APIs for
  confidence computation and contradiction analysis.
  """
  use GenServer
  require Logger

  alias Tiannara.Sentinel.Verification.Evidence

  # ── Configuration ──

  @evidence_decay_halflife_days 90
  @min_evidence_for_claim 3
  @strong_evidence_threshold 0.7
  @reproducibility_target 0.8

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Records an evidence item supporting or refuting a claim.
  Returns the evidence ID.
  """
  def record_evidence(claim_id, type, strength, opts \\ []) do
    source = Map.get(opts, :source, :unknown)
    contradicts = Map.get(opts, :contradicts, [])
    supports = Map.get(opts, :supports, [])
    metadata = Map.get(opts, :metadata, %{})

    evidence = %Evidence{
      id: "ev_#{System.unique_integer([:positive])}",
      claim_id: claim_id,
      type: type,
      source: source,
      timestamp: DateTime.utc_now(),
      strength: strength,
      contradicts: List.wrap(contradicts),
      supports: List.wrap(supports),
      metadata: metadata
    }

    GenServer.cast(__MODULE__, {:record_evidence, evidence})
    evidence.id
  end

  @doc """
  Records a reproducibility attempt for a given evidence item.
  """
  def record_reproduction(evidence_id, success) do
    GenServer.cast(__MODULE__, {:record_reproduction, evidence_id, success})
  end

  @doc """
  Computes the confidence score for a claim based on all evidence.
  Returns a map with confidence, supporting_count, refuting_count,
  reproducibility_rate, and average_strength.
  """
  def claim_confidence(claim_id) do
    GenServer.call(__MODULE__, {:claim_confidence, claim_id})
  end

  @doc """
  Detects contradictions: evidence that supports claim A but contradicts
  claim B, or vice versa. Returns list of contradiction maps.
  """
  def detect_contradictions(claim_id) do
    GenServer.call(__MODULE__, {:detect_contradictions, claim_id})
  end

  @doc """
  Returns all evidence for a given claim.
  """
  def get_evidence(claim_id) do
    GenServer.call(__MODULE__, {:get_evidence, claim_id})
  end

  @doc """
  Returns a summary of all tracked claims with their confidence scores.
  """
  def claim_summary do
    GenServer.call(__MODULE__, :claim_summary)
  end

  @doc """
  Returns all evidence that has low reproducibility (< 0.5 success rate).
  """
  def low_reproducibility_evidence do
    GenServer.call(__MODULE__, :low_reproducibility_evidence)
  end

  @doc """
  Checks reproducibility health for a claim — whether it has been
  independently reproduced enough times for scientific confidence.
  """
  def reproducibility_health(claim_id) do
    GenServer.call(__MODULE__, {:reproducibility_health, claim_id})
  end

  # ── GenServer Callbacks ──

  @impl true
  def init(_opts) do
    :ets.new(:verification_evidence, [:set, :public, :named_table])
    :ets.new(:verification_reproductions, [:bag, :public, :named_table])
    Logger.info("🔬 [VERIFICATION] Scientific Verification Layer initialized.")
    {:ok, %{
      evidence_table: :verification_evidence,
      reproduction_table: :verification_reproductions
    }}
  end

  @impl true
  def handle_cast({:record_evidence, %Evidence{} = evidence}, state) do
    :ets.insert(state.evidence_table, {evidence.id, evidence})
    Logger.debug("[VERIFICATION] Evidence recorded: #{evidence.id} for claim #{evidence.claim_id}")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:record_reproduction, evidence_id, success}, state) do
    :ets.insert(state.reproduction_table, {evidence_id, success, DateTime.utc_now()})

    case :ets.lookup(state.evidence_table, evidence_id) do
      [{_id, evidence}] ->
        updated = %{evidence |
          reproduction_attempts: evidence.reproduction_attempts + 1,
          reproduction_count: if(success, do: evidence.reproduction_count + 1, else: evidence.reproduction_count),
          reproducible: (evidence.reproduction_count + (if(success, do: 1, else: 0))) / (evidence.reproduction_attempts + 1) >= @reproducibility_target
        }
        :ets.insert(state.evidence_table, {evidence_id, updated})
      _ -> :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_call({:claim_confidence, claim_id}, _from, state) do
    all_evidence = load_evidence_for_claim(state.evidence_table, claim_id)
    result = compute_confidence(claim_id, all_evidence)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:detect_contradictions, claim_id}, _from, state) do
    all_evidence = load_evidence_for_claim(state.evidence_table, claim_id)
    all_records = :ets.tab2list(state.evidence_table) |> Enum.map(fn {_id, ev} -> ev end)
    contradictions = find_contradictions(claim_id, all_evidence, all_records)
    {:reply, contradictions, state}
  end

  @impl true
  def handle_call({:get_evidence, claim_id}, _from, state) do
    evidence = load_evidence_for_claim(state.evidence_table, claim_id)
    {:reply, evidence, state}
  end

  @impl true
  def handle_call(:claim_summary, _from, state) do
    all = :ets.tab2list(state.evidence_table) |> Enum.map(fn {_id, ev} -> ev end)
    grouped = Enum.group_by(all, & &1.claim_id)

    summary = Map.new(grouped, fn {cid, ev_list} ->
      confidence = compute_confidence(cid, ev_list)
      {cid, confidence}
    end)

    {:reply, summary, state}
  end

  @impl true
  def handle_call(:low_reproducibility_evidence, _from, state) do
    all = :ets.tab2list(state.evidence_table) |> Enum.map(fn {_id, ev} -> ev end)
    low_rep = Enum.filter(all, fn ev ->
      ev.reproduction_attempts > 0 and
        (ev.reproduction_count / ev.reproduction_attempts) < 0.5
    end)
    {:reply, low_rep, state}
  end

  @impl true
  def handle_call({:reproducibility_health, claim_id}, _from, state) do
    evidence = load_evidence_for_claim(state.evidence_table, claim_id)

    total_attempts = Enum.sum_by(evidence, & &1.reproduction_attempts)
    total_successes = Enum.sum_by(evidence, & &1.reproduction_count)
    success_rate = if total_attempts > 0, do: total_successes / total_attempts, else: 0.0

    independently_reproduced = Enum.count(evidence, & &1.reproducible)
    total_evidence = length(evidence)

    robustness = cond do
      total_evidence >= 3 and success_rate >= 0.8 and independently_reproduced >= 2 -> :robust
      total_evidence >= 1 and success_rate >= 0.5 -> :moderate
      total_attempts == 0 -> :untested
      true -> :fragile
    end

    {:reply, %{
      claim_id: claim_id,
      total_evidence: total_evidence,
      total_reproduction_attempts: total_attempts,
      total_reproduction_successes: total_successes,
      success_rate: Float.round(success_rate, 4),
      independently_reproduced: independently_reproduced,
      robustness: robustness
    }, state}
  end

  # ── Private Helpers ──

  defp load_evidence_for_claim(table, claim_id) do
    table
    |> :ets.tab2list()
    |> Enum.map(fn {_id, ev} -> ev end)
    |> Enum.filter(fn ev -> ev.claim_id == claim_id end)
  end

  defp compute_confidence(claim_id, evidence) do
    supporting = Enum.filter(evidence, fn ev -> ev.strength >= @strong_evidence_threshold end)
    refuting = Enum.filter(evidence, fn ev -> ev.strength < @strong_evidence_threshold end)

    supporting_count = length(supporting)
    refuting_count = length(refuting)
    total = length(evidence)

    avg_strength = if total > 0, do: Enum.sum_by(evidence, & &1.strength) / total, else: 0.0

    total_attempts = Enum.sum_by(evidence, & &1.reproduction_attempts)
    total_successes = Enum.sum_by(evidence, & &1.reproduction_count)

    reproducibility_rate = if total_attempts > 0, do: total_successes / total_attempts, else: 0.0

    net_evidence = supporting_count - refuting_count
    evidence_factor = min(net_evidence / max(@min_evidence_for_claim, 1), 1.0)
    evidence_factor = max(evidence_factor, -1.0)

    strength_factor = (avg_strength - 0.5) * 2.0

    reproduction_factor = reproducibility_rate * 0.3

    age_factor = evidence_age_factor(evidence)

    raw_confidence = 0.5 +
      evidence_factor * 0.3 +
      strength_factor * 0.2 +
      reproduction_factor +
      age_factor

    confidence = max(0.01, min(0.99, raw_confidence))

    %{
      claim_id: claim_id,
      confidence: Float.round(confidence, 4),
      supporting_count: supporting_count,
      refuting_count: refuting_count,
      total_evidence: total,
      average_strength: Float.round(avg_strength, 4),
      reproducibility_rate: Float.round(reproducibility_rate, 4),
      assessment: confidence_assessment(confidence)
    }
  end

  defp confidence_assessment(confidence) when confidence >= 0.9, do: :very_high
  defp confidence_assessment(confidence) when confidence >= 0.7, do: :high
  defp confidence_assessment(confidence) when confidence >= 0.4, do: :moderate
  defp confidence_assessment(confidence) when confidence >= 0.2, do: :low
  defp confidence_assessment(_), do: :very_low

  defp evidence_age_factor(evidence) do
    now = DateTime.utc_now()

    ages = Enum.map(evidence, fn ev ->
      DateTime.diff(now, ev.timestamp, :day)
    end)

    if ages == [] do
      0.0
    else
      avg_age = Enum.sum(ages) / length(ages)
      # Recent evidence increases confidence, old evidence reduces it
      -0.1 * min(avg_age / @evidence_decay_halflife_days, 1.0)
    end
  end

  defp find_contradictions(claim_id, evidence, all_records) do
    direct = Enum.flat_map(evidence, fn ev ->
      ev.contradicts
      |> Enum.reject(&(&1 == claim_id))
      |> Enum.map(fn other_id ->
        other_evidence = Enum.filter(all_records, fn r -> r.claim_id == other_id end)
        %{
          type: :direct_contradiction,
          evidence_id: ev.id,
          claim_a: claim_id,
          claim_b: other_id,
          strength_a: ev.strength,
          strength_b: Enum.map(other_evidence, & &1.strength)
        }
      end)
    end)

    cross_support = Enum.flat_map(evidence, fn ev ->
      ev.supports
      |> Enum.reject(&(&1 == claim_id))
      |> Enum.map(fn other_id ->
        other_evidence = Enum.filter(all_records, fn r -> r.claim_id == other_id end)
        conflicting = Enum.filter(other_evidence, fn oe ->
          oe.contradicts |> Enum.member?(claim_id)
        end)
        if conflicting != [] do
          [%{
            type: :cross_contradiction,
            evidence_id: ev.id,
            claim_a: claim_id,
            claim_b: other_id,
            detail: "Evidence supports #{other_id} but contradicts #{claim_id}",
            severity: :medium
          }]
        else
          []
        end
      end)
      |> List.flatten()
    end)

    direct ++ cross_support
  end
end
