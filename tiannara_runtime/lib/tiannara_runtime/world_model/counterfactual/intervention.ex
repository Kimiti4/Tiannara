defmodule TiannaraRuntime.WorldModel.Counterfactual.Intervention do
  @moduledoc """
  Defines an intervention operation applied to a target element within a counterfactual world, specifying the type of change and its parameters.
  """

  @id_prefix "iv_"

  @enforce_keys [:type, :target, :operation]

  defstruct [
    :intervention_id,
    :type,
    :target,
    :operation,
    :value,
    :constraints,
    :evidence_hash,
    :description,
    :metadata
  ]

  @type t :: %__MODULE__{
          intervention_id: String.t() | nil,
          type: :variable | :structural | :policy | :engineering | :environmental,
          target: String.t(),
          operation: :fix | :remove | :add | :modify | :replace,
          value: term() | nil,
          constraints: list(),
          evidence_hash: String.t() | nil,
          description: String.t(),
          metadata: map()
        }

  @valid_types ~w(variable structural parameter event)a
  @valid_operations ~w(fix shift add remove multiply)a

  def new(opts) do
    struct = %__MODULE__{
      intervention_id: opts[:intervention_id],
      type: opts[:type],
      target: opts[:target],
      operation: opts[:operation],
      value: opts[:value],
      constraints: opts[:constraints] || [],
      evidence_hash: opts[:evidence_hash],
      description: opts[:description] || "",
      metadata: opts[:metadata] || %{}
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = intervention) do
    errors = []

    errors =
      if intervention.type not in @valid_types do
        ["invalid type" | errors]
      else
        errors
      end

    errors =
      if is_nil(intervention.target) or intervention.target == "" do
        ["empty target" | errors]
      else
        errors
      end

    errors =
      if intervention.operation not in @valid_operations do
        ["invalid operation" | errors]
      else
        errors
      end

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = intervention) do
    intervention
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = intervention) do
    material =
      Atom.to_string(intervention.type || :null) <>
        (intervention.target || "") <> Atom.to_string(intervention.operation || :null)

    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{intervention_id: nil} = intervention) do
    %{intervention | intervention_id: compute_id(intervention)}
  end

  defp ensure_id(%__MODULE__{} = intervention), do: intervention
end
