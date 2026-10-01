defmodule Tiannara.Twp.BranchPruner do
  @moduledoc """
  Prunes low-value branches in the temporal wavefunction to maintain simulation efficiency.
  """

  @spec prune_branches(map()) :: {:ok, term()} | {:error, term()}
  def prune_branches(%{branches: branches, survivability_threshold: threshold} = data)
      when is_list(branches) and is_number(threshold) do
    {kept, pruned} =
      Enum.split_with(branches, fn branch ->
        case calculate_survivability(branch) do
          {:ok, score} -> score >= threshold
          {:error, _} -> true
        end
      end)

    {:ok, %{data | branches: kept, pruned: pruned}}
  end

  def prune_branches(_), do: {:error, :branch_data_requires_measured_survivability}

  @spec calculate_survivability(map()) :: {:ok, float()} | {:error, term()}
  def calculate_survivability(%{} = branch) do
    case Map.get(branch, :survivability) do
      value when is_number(value) and value >= 0.0 and value <= 1.0 -> {:ok, value}
      _ -> {:error, :survivability_unmeasured}
    end
  end

  def calculate_survivability(_), do: {:error, :invalid_branch}
end