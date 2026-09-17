defmodule TiannaraRuntime.WorldModel.Counterfactual.TimelineStep do
  @moduledoc """
  Represents a single step within an alternative timeline, capturing the state, intervention status, causal propagation, and entropy at that point.
  """

  @id_prefix "ts_"

  @enforce_keys [:step, :state, :intervention_active]

  defstruct [
    :step,
    :state,
    :intervention_active,
    :causal_propagation,
    :entropy,
    :timestamp
  ]

  @type t :: %__MODULE__{
          step: non_neg_integer(),
          state: any(),
          intervention_active: boolean(),
          causal_propagation: list(),
          entropy: float(),
          timestamp: any()
        }

  def new(opts) do
    struct = %__MODULE__{
      step: opts[:step],
      state: opts[:state],
      intervention_active: opts[:intervention_active] || false,
      causal_propagation: opts[:causal_propagation] || [],
      entropy: opts[:entropy] || 0.0,
      timestamp: opts[:timestamp]
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = step) do
    errors = []

    errors =
      if step.step < 0 do
        ["step < 0" | errors]
      else
        errors
      end

    errors =
      if is_nil(step.state) do
        ["nil state" | errors]
      else
        errors
      end

    errors =
      if not is_nil(step.state) and
           (step.state == "" or step.state == %{} or step.state == []) do
        ["empty state" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = step) do
    step
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = step) do
    material = Integer.to_string(step.step || 0) <> inspect(step.state || %{})
    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{} = step), do: step
end
