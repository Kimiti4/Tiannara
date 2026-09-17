defmodule TiannaraRuntime.WorldModel.Counterfactual.BranchComparison do
  @moduledoc """
  Encapsulates the result of comparing an original branch with a counterfactual branch, tracking divergence and similarity metrics along with causal and informational deltas.
  """

  @id_prefix "bc_"

  @enforce_keys [:original_id, :counterfactual_id]

  defstruct [
    :comparison_id,
    :original_id,
    :counterfactual_id,
    :divergence_metric,
    :similarity_metric,
    :causal_distance,
    :entropy_delta,
    :variable_impacts,
    :explanation,
    :metadata
  ]

  @type t :: %__MODULE__{
          comparison_id: String.t() | nil,
          original_id: String.t(),
          counterfactual_id: String.t(),
          divergence_metric: float(),
          similarity_metric: float(),
          causal_distance: float(),
          entropy_delta: float(),
          variable_impacts: map(),
          explanation: String.t(),
          metadata: map()
        }

  def new(opts) do
    struct = %__MODULE__{
      comparison_id: opts[:comparison_id],
      original_id: opts[:original_id],
      counterfactual_id: opts[:counterfactual_id],
      divergence_metric: opts[:divergence_metric] || 0.0,
      similarity_metric: opts[:similarity_metric] || 1.0,
      causal_distance: opts[:causal_distance] || 0.0,
      entropy_delta: opts[:entropy_delta] || 0.0,
      variable_impacts: opts[:variable_impacts] || %{},
      explanation: opts[:explanation] || "",
      metadata: opts[:metadata] || %{}
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = comparison) do
    errors = []

    errors =
      if is_nil(comparison.original_id) or comparison.original_id == "" do
        ["empty original_id" | errors]
      else
        errors
      end

    errors =
      if comparison.divergence_metric < 0.0 or comparison.divergence_metric > 1.0 do
        ["divergence_metric not in 0.0..1.0" | errors]
      else
        errors
      end

    errors =
      if comparison.similarity_metric < 0.0 or comparison.similarity_metric > 1.0 do
        ["similarity_metric not in 0.0..1.0" | errors]
      else
        errors
      end

    errors =
      if comparison.causal_distance < 0.0, do: ["causal_distance < 0.0" | errors], else: errors

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = comparison) do
    comparison
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = comparison) do
    material = (comparison.original_id || "") <> (comparison.counterfactual_id || "")
    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{comparison_id: nil} = comparison) do
    %{comparison | comparison_id: compute_id(comparison)}
  end

  defp ensure_id(%__MODULE__{} = comparison), do: comparison
end
