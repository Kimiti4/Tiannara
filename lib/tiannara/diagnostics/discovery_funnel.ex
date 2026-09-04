defmodule Tiannara.Diagnostics.DiscoveryFunnel do
  @moduledoc """
  Read-only causal reconstruction of the discovery pipeline.

  Constitutional basis:
    * Evidence Before Confidence
    * Verification First
    * Evolution Framework -- "Every architectural decision should remain traceable"
    * New invariant -- **Discovery absence must be explainable**

  This module performs NO writes and sends NO signals to the running soak.
  It consumes an immutable `Tiannara.Diagnostics.EventSource` and reconstructs:

      observations -> gaps -> hypotheses -> ranked_hypotheses ->
      experiments_proposed -> experiments_scheduled ->
      experiments_started -> experiments_completed ->
      evidence_generated -> knowledge_integrated ->
      discovery_candidates -> validated_discoveries

  CORE INVARIANT:
      Every non-zero upstream stage must have an explainable downstream
      disposition for every item it produced.

      hypotheses = 17, experiments_scheduled = 0 is only acceptable if the
      17 hypotheses have explicit dispositions:

          12 insufficient_evidence
           3 constitutional_veto
           2 duplicate

      A silent zero is a violation.

  ZERO-STATE CLASSIFICATION (the three states that must never be confused):
      :no_signal           -- nothing research-worthy happened (no gaps)
      :pipeline_blocked    -- upstream activity died silently (UNEXPLAINED loss)
      :validation_rejected -- candidates existed, all rejected with explicit reasons
      :healthy_empty       -- full flow, explained, but nothing qualified
      :discoveries_present -- validated discoveries exist
  """

  @stages [
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

  defstruct counts: %{},
            promoted: %{},
            rejected_reasons: %{},
            pending: %{},
            closed: %{},
            unexplained: %{},
            violations: [],
            zero_state: nil

  @type t :: %__MODULE__{}

  def stages, do: @stages

  @doc """
  Reconstruct and audit the funnel from a read-only event source.

  `source` is any struct whose module implements
  `Tiannara.Diagnostics.EventSource.stream_events/2`.

  This never mutates the source or the soak.
  """
  def audit(%_{} = source, opts \\ []) do
    source.__struct__.stream_events(source, opts)
    |> Enum.reduce(%__MODULE__{}, &apply_event/2)
    |> reconcile()
  end

  # --- event application (pure accumulation) ------------------------------

  defp apply_event({:created, stage, _id, _parents}, f) do
    if stage in @stages do
      %{f | counts: Map.update(f.counts, stage, 1, &(&1 + 1))}
    else
      f
    end
  end

  defp apply_event({:disposition, stage, _id, :promoted, _child}, f) do
    %{f | promoted: Map.update(f.promoted, stage, 1, &(&1 + 1))}
  end

  defp apply_event({:disposition, stage, _id, :rejected, reason}, f) do
    reasons = Map.get(f.rejected_reasons, stage, %{})
    reasons = Map.update(reasons, reason, 1, &(&1 + 1))
    %{f | rejected_reasons: Map.put(f.rejected_reasons, stage, reasons)}
  end

  defp apply_event({:disposition, stage, _id, :pending, _}, f) do
    %{f | pending: Map.update(f.pending, stage, 1, &(&1 + 1))}
  end

  # :closed = legitimately terminated without promotion (e.g. observation
  # revealed no gap). It is *explained*, not a rejection.
  defp apply_event({:disposition, stage, _id, :closed, _reason}, f) do
    %{f | closed: Map.update(f.closed, stage, 1, &(&1 + 1))}
  end

  # :absorbed = merged into another item (duplicate). Explained, counted
  # as a rejection reason for reporting.
  defp apply_event({:disposition, stage, _id, :absorbed, _into}, f) do
    reasons = Map.get(f.rejected_reasons, stage, %{})
    reasons = Map.update(reasons, :absorbed_duplicate, 1, &(&1 + 1))
    %{f | rejected_reasons: Map.put(f.rejected_reasons, stage, reasons)}
  end

  defp apply_event(_other, f), do: f

  # --- reconciliation + invariant ------------------------------------------

  defp reconcile(%__MODULE__{} = f) do
    # Ensure all stages appear in counts (default 0).
    counts = Enum.into(@stages, f.counts, fn s -> {s, Map.get(f.counts, s, 0)} end)
    f = %{f | counts: counts}

    # The terminal stage (:validated_discoveries) has no downstream disposition
    # by definition — discovery IS the end state. Don't flag it as unexplained.
    terminal = List.last(@stages)

    unexplained =
      for stage <- @stages, stage != terminal, into: %{} do
        c = count(f, stage)

        explained =
          Map.get(f.promoted, stage, 0) +
            stage_rejections(f, stage) +
            Map.get(f.pending, stage, 0) +
            Map.get(f.closed, stage, 0)

        {stage, max(c - explained, 0)}
      end

    violations =
      for {stage, n} <- unexplained, n > 0 do
        %{
          stage: stage,
          unexplained: n,
          message: "#{n} #{stage} have no downstream disposition (silent loss)"
        }
      end

    f2 = %{f | unexplained: unexplained, violations: violations}
    %{f2 | zero_state: classify_zero(f2)}
  end

  defp stage_rejections(f, stage) do
    f.rejected_reasons |> Map.get(stage, %{}) |> Map.values() |> Enum.sum()
  end

  defp count(f, stage), do: Map.get(f.counts, stage, 0)

  defp any_unexplained?(f), do: Enum.any?(Map.values(f.unexplained), &(&1 > 0))

  defp total_rejections(f) do
    f.rejected_reasons |> Map.values() |> Enum.flat_map(&Map.values/1) |> Enum.sum()
  end

  # --- zero-state classification ------------------------------------------

  @doc """
  Distinguish the scientifically different "zero discovery" states.

      :no_signal           != :pipeline_blocked != :validation_rejected
  """
  def classify_zero(%__MODULE__{} = f) do
    discoveries = count(f, :validated_discoveries)

    cond do
      discoveries > 0 ->
        :discoveries_present

      # Highest alarm: something upstream died with no explanation.
      any_unexplained?(f) ->
        :pipeline_blocked

      # Nothing research-worthy was detected (no gaps).
      count(f, :gaps) == 0 ->
        :no_signal

      # Material existed, but every candidate was explicitly turned down.
      total_rejections(f) > 0 ->
        :validation_rejected

      true ->
        :healthy_empty
    end
  end

  # --- reporting -----------------------------------------------------------

  @doc """
  Machine-readable summary for the Track I Discovery Pipeline view.
  """
  def summary(%__MODULE__{} = f) do
    %{
      zero_state: f.zero_state,
      counts: f.counts,
      unexplained: f.unexplained,
      rejected_reasons: f.rejected_reasons,
      pending: f.pending,
      violations: f.violations,
      invariant_satisfied?: f.violations == []
    }
  end

  @doc """
  Human-readable accounting for every stage transition.

  Produces exactly the required style:

      hypotheses (17) -> experiments_scheduled (0)
        promoted:     0
        pending:      0
        rejected:    17
           12 insufficient_evidence
            3 constitutional_veto
            2 duplicate
        unexplained:  0
  """
  def report(%__MODULE__{} = f) do
    header = """
    Discovery Pipeline Funnel Audit
    zero_state: #{f.zero_state}
    invariant: #{if f.violations == [], do: "SATISFIED", else: "VIOLATED (#{length(f.violations)} stage(s) with silent loss)"}
    """

    body =
      @stages
      |> Enum.chunk_every(2, 1, :discard)
      |> Enum.map(fn [from, to] -> transition_block(f, from, to) end)
      |> Enum.join("\n")

    header <> "\n" <> body
  end

  defp transition_block(f, from, to) do
    upstream = count(f, from)

    if upstream == 0 do
      "#{from}: 0 (no activity)"
    else
      reached = count(f, to)
      promoted = Map.get(f.promoted, from, 0)
      pending = Map.get(f.pending, from, 0)
      closed = Map.get(f.closed, from, 0)
      reasons = Map.get(f.rejected_reasons, from, %{})
      rejected = reasons |> Map.values() |> Enum.sum()
      unexp = Map.get(f.unexplained, from, 0)

      base = [
        "#{from} (#{upstream}) -> #{to} (#{reached})",
        "  promoted:   #{promoted}",
        "  pending:    #{pending}",
        "  closed:     #{closed}",
        "  rejected:   #{rejected}"
      ]

      reason_lines =
        reasons
        |> Enum.sort_by(fn {_r, n} -> -n end)
        |> Enum.map(fn {reason, n} -> "     #{String.pad_leading(to_string(n), 3)} #{reason}" end)

      unexp_line =
        if unexp > 0,
          do: "  unexplained: #{unexp}  | SILENT LOSS",
          else: "  unexplained: 0"

      Enum.join(base ++ reason_lines ++ [unexp_line], "\n")
    end
  end
end
