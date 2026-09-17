defmodule TiannaraRuntime.WorldModel.Counterfactual.BranchNode do
  @moduledoc """
  Represents a node in the counterfactual branch tree, linking a divergence point to its parent branch and tracking child branches at increasing depths.
  """

  @id_prefix "bn_"

  @enforce_keys [:divergence, :depth]

  defstruct [
    :branch_id,
    :parent_branch_id,
    :divergence,
    :children,
    :depth,
    :metadata
  ]

  @type t :: %__MODULE__{
          branch_id: String.t() | nil,
          parent_branch_id: String.t() | nil,
          divergence: TiannaraRuntime.WorldModel.Counterfactual.DivergencePoint.t(),
          children: list(),
          depth: non_neg_integer(),
          metadata: map()
        }

  def new(opts) do
    struct = %__MODULE__{
      branch_id: opts[:branch_id],
      parent_branch_id: opts[:parent_branch_id],
      divergence: opts[:divergence],
      children: opts[:children] || [],
      depth: opts[:depth],
      metadata: opts[:metadata] || %{}
    }

    case validate(struct) do
      :ok -> {:ok, ensure_id(struct)}
      {:error, _} = err -> err
    end
  end

  def validate(%__MODULE__{} = node) do
    errors = []

    errors = if is_nil(node.divergence), do: ["nil divergence" | errors], else: errors

    errors = if not is_nil(node.depth) and node.depth < 0, do: ["depth < 0" | errors], else: errors

    errors = if not is_list(node.children), do: ["children not a list" | errors], else: errors

    if errors == [], do: :ok, else: {:error, Enum.reverse(errors)}
  end

  def canonicalize(%__MODULE__{} = node) do
    node
    |> Map.from_struct()
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Map.new()
  end

  def compute_id(%__MODULE__{} = node) do
    material = inspect(node.divergence) <> Integer.to_string(node.depth)
    hash = :crypto.hash(:sha256, material) |> Base.encode16(case: :lower)
    @id_prefix <> hash
  end

  defp ensure_id(%__MODULE__{branch_id: nil} = node) do
    %{node | branch_id: compute_id(node)}
  end

  defp ensure_id(%__MODULE__{} = node), do: node
end
