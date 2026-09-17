defmodule TiannaraRuntime.WorldModel.Counterfactual.CounterfactualWorld do
  @moduledoc """
  Represents a counterfactual world derived by applying an intervention at a divergence point to a parent model timeline, producing alternative outcomes.
  """

  @id_prefix "cf_"

  @enforce_keys [:parent_model_id, :intervention, :divergence_point, :timeline, :outcomes]

  defstruct [
    :counterfactual_id,
    :parent_model_id,
    :parent_version,
    :parent_fingerprint,
    :intervention,
    :divergence_point,
    :timeline,
    :outcomes,
    :assumptions,
    :confidence,
    :uncertainty,
    :evidence_roots,
    :replay_fingerprint,
    :archaeology_root,
    :created_at
  ]

  @type t :: %__MODULE__{
          counterfactual_id: String.t() | nil,
          parent_model_id: String.t(),
          parent_version: non_neg_integer(),
          parent_fingerprint: String.t() | nil,
          intervention: TiannaraRuntime.WorldModel.Counterfactual.Intervention.t(),
          divergence_point: TiannaraRuntime.WorldModel.Counterfactual.DivergencePoint.t(),
          timeline: list(),
          outcomes: map(),
          assumptions: map(),
          confidence: float() | nil,
          uncertainty: float() | nil,
          evidence_roots: list(),
          replay_fingerprint: String.t() | nil,
          archaeology_root: String.t() | nil,
          created_at: String.t()
        }

  def new(opts) do
    struct = %__MODULE__{
      counterfactual_id: opts[:counterfactual_id],
      parent_model_id: opts[:parent_model_id],
      parent_version: opts[:parent_version] || 1,
      parent_fingerprint: opts[:parent_fingerprint],
      intervention: opts[:intervention],
      divergence_point: opts[:divergence_point],
      timeline: opts[:timeline],
      outcomes: opts[:outcomes],
      assumptions: opts[:assumptions] || %{},
      confidence: opts[:confidence],
      uncertainty: opts[:uncertainty],
      evidence_roots: opts[:evidence_roots] || [],
      replay_fingerprint: opts[:replay_fingerprint],
      archaeology_root: opts[:archaeology_root],
      created_at: opts[:created_at] || (DateTime.utc_now() |> DateTime.to_iso8601())
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = world) do
    errors = []

    errors =
      if is_nil(world.parent_model_id) or world.parent_model_id == "" do
        ["empty parent_model_id" | errors]
      else
        errors
      end

    errors = if is_nil(world.intervention), do: ["nil intervention" | errors], else: errors

    errors =
      if is_nil(world.divergence_point), do: ["nil divergence_point" | errors], else: errors

    errors = if is_nil(world.timeline), do: ["nil timeline" | errors], else: errors

    errors =
      if is_nil(world.outcomes) or world.outcomes == %{} do
        ["nil or empty outcomes" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = world) do
    world
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = world) do
    material =
      (world.parent_model_id || "") <>
        (world.intervention.intervention_id || "") <> (world.divergence_point.divergence_id || "")

    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{counterfactual_id: nil} = world) do
    %{world | counterfactual_id: compute_id(world)}
  end

  defp ensure_id(%__MODULE__{} = world), do: world
end
