defmodule Tiannara.Discovery.Step do
  @moduledoc """
  Behaviour for a discovery-pipeline step (the Experiment / Validation stages
  of rules.md's Scientific Method).

  A step is REAL when its `execute/2` runs actual code over actual inputs and
  returns an actual, provenance-tagged evidence record. A step that returns a
  canned record is NOT a step — it is an assumption wearing evidence's clothes,
  which rules.md forbids ("Evidence Before Confidence"; "Distinguish clearly
  between Facts, Evidence, Assumptions"; "Never optimize for appearing correct").

  The contract here mirrors what the WorkflowEngine actually invokes at
  runtime (workflow_engine.ex:518-554, 556-612, 675-707, 722):

      step.module.required_capability()      # engine:520, OUTSIDE the try
      step.module.execute(step.input, ctx)   # engine:525 — first arg is INPUT
      step.module.step_type()                # engine:530,565,587,598,644,657
      step.module.compensate(input,res,ctx)  # engine:722 (saga rollback)

  The engine reads these keys from the `{:ok, output}` of `execute/2`:
  `:evidence` (list), `:confidence`, `:quality_metrics`, `:resource_usage`.
  Keep that shape — it is the pipeline's evidence carrier.

  This module also hosts the shared, pure measurement helpers so the
  confidence formula has ONE source (Explainability + DRY without macro
  complexity).
  """

  @type input :: map()
  @type context :: map()
  @type output :: map()

  @doc "Returns the unique identifier for this step type (workflow step_metrics key)."
  @callback step_type() :: atom()

  @doc "Returns the capability required to execute this step (resolved by CapabilityGraph)."
  @callback required_capability() :: atom()

  @doc "Validates the step input. Returns :ok or {:error, reason}."
  @callback validate_input(input()) :: :ok | {:error, term()}

  @doc """
  Executes the step over its input and the workflow context. Returns
  `{:ok, output}` or `{:error, reason}`; `output` must carry `:evidence` (a
  list), `:confidence`, `:quality_metrics` and `:resource_usage`.
  """
  @callback execute(input(), context()) :: {:ok, output()} | {:error, term()}

  @doc "Undoes the step's effects on saga rollback."
  @callback compensate(input(), output() | nil, context()) :: :ok | {:error, term()}

  @doc "Returns metadata about the step for observability."
  @callback metadata() :: map()

  @doc """
  Confidence derived from how far a measured divergence exceeds tolerance.
  Pure, monotonic, explainable: ratio = divergence / tolerance; confidence =
  clamp(ratio / 2, 0, 1). A confirmed conflict (divergence > tolerance) yields
  confidence >= 0.5; non-numeric inputs yield 0.0 (uncertainty surfaced, not
  hidden).
  """
  @spec confidence_from_divergence(number() | nil, number()) :: float()
  def confidence_from_divergence(divergence, tolerance)
      when is_number(divergence) and is_number(tolerance) and tolerance > 0 do
    ratio = divergence / tolerance
    ratio
    |> Kernel./(2.0)
    |> min(1.0)
    |> max(0.0)
  end

  def confidence_from_divergence(_, _), do: 0.0

  @doc "An outcome is decisive (carries information) iff confirmed or refuted."
  @spec decisive?(atom()) :: boolean()
  def decisive?(outcome), do: outcome in [:confirmed, :refuted]
end
