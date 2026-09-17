defmodule TiannaraRuntime.WorldModel.Counterfactual.ScenarioOutcome do
  @moduledoc """
  Represents an outcome variable within a counterfactual scenario, storing the resulting value, confidence, and deviation from the original timeline.
  """

  @id_prefix "so_"

  @enforce_keys [:counterfactual_id, :variable, :value]

  defstruct [
    :outcome_id,
    :counterfactual_id,
    :variable,
    :value,
    :confidence,
    :delta_from_original,
    :metadata
  ]

  @type t :: %__MODULE__{
          outcome_id: String.t() | nil,
          counterfactual_id: String.t(),
          variable: String.t(),
          value: any(),
          confidence: float(),
          delta_from_original: any(),
          metadata: map()
        }

  def new(opts) do
    struct = %__MODULE__{
      outcome_id: opts[:outcome_id],
      counterfactual_id: opts[:counterfactual_id],
      variable: opts[:variable],
      value: opts[:value],
      confidence: opts[:confidence] || 0.0,
      delta_from_original: opts[:delta_from_original],
      metadata: opts[:metadata] || %{}
    }

    ensure_id(struct)
  end

  def validate(%__MODULE__{} = outcome) do
    errors = []

    errors =
      if is_nil(outcome.counterfactual_id) or outcome.counterfactual_id == "" do
        ["empty counterfactual_id" | errors]
      else
        errors
      end

    errors =
      if is_nil(outcome.variable) or outcome.variable == "" do
        ["empty variable" | errors]
      else
        errors
      end

    errors =
      if is_nil(outcome.value) do
        ["nil value" | errors]
      else
        errors
      end

    errors =
      if not is_nil(outcome.confidence) and
           (outcome.confidence < 0.0 or outcome.confidence > 1.0) do
        ["confidence not in 0.0..1.0" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = outcome) do
    outcome
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = outcome) do
    material = outcome.counterfactual_id <> outcome.variable
    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{outcome_id: nil} = outcome) do
    %{outcome | outcome_id: compute_id(outcome)}
  end

  defp ensure_id(%__MODULE__{} = outcome), do: outcome
end
