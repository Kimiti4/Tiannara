defmodule TiannaraRuntime.WorldModel.Counterfactual.DivergencePoint do
  @moduledoc """
  Captures the exact moment and state at which a counterfactual world diverges from its parent model, including the intervention that triggered the divergence.
  """

  @id_prefix "dp_"

  @enforce_keys [:parent_model_id, :step, :state, :intervention]

  defstruct [
    :divergence_id,
    :parent_model_id,
    :step,
    :state,
    :intervention,
    :description
  ]

  @type t :: %__MODULE__{
          divergence_id: String.t() | nil,
          parent_model_id: String.t(),
          step: non_neg_integer(),
          state: map(),
          intervention: TiannaraRuntime.WorldModel.Counterfactual.Intervention.t(),
          description: String.t()
        }

  def new(opts) do
    struct = %__MODULE__{
      divergence_id: opts[:divergence_id],
      parent_model_id: opts[:parent_model_id],
      step: opts[:step],
      state: opts[:state],
      intervention: opts[:intervention],
      description: opts[:description] || ""
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = dp) do
    errors = []

    errors =
      if is_nil(dp.parent_model_id) or dp.parent_model_id == "" do
        ["empty parent_model_id" | errors]
      else
        errors
      end

    errors = if not is_nil(dp.step) and dp.step < 0, do: ["step < 0" | errors], else: errors

    errors = if is_nil(dp.state), do: ["nil state" | errors], else: errors

    errors =
      if not is_nil(dp.state) and dp.state == %{} do
        ["empty state map" | errors]
      else
        errors
      end

    errors = if is_nil(dp.intervention), do: ["nil intervention" | errors], else: errors

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = dp) do
    dp
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = dp) do
    material = (dp.parent_model_id || "") <> Integer.to_string(dp.step || 0) <> inspect(dp.state || %{})
    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{divergence_id: nil} = dp) do
    %{dp | divergence_id: compute_id(dp)}
  end

  defp ensure_id(%__MODULE__{} = dp), do: dp
end
