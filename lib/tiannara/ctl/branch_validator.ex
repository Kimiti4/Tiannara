defmodule Tiannara.Ctl.BranchValidator do
  @moduledoc """
  Module for validating branch compatibility and preventing paradox-inducing merges.
  This module works with the CausalRegistry to ensure branch integrity.
  """

  alias Tiannara.CTL.CausalRegistry

  @type branch_id :: String.t()
  @type branch_record :: map()

  @spec validate_merge(branch_id(), branch_id()) :: {:ok, :valid} | {:error, :invalid_merge}
  def validate_merge(branch_a_id, branch_b_id) do
    with {:ok, branch_a} <- CausalRegistry.get_branch(branch_a_id),
         {:ok, branch_b} <- CausalRegistry.get_branch(branch_b_id),
         :ok <- check_causal_stress(branch_a, branch_b) do
      {:ok, :valid}
    else
      {:error, :not_found} -> {:error, :branch_not_found}
      {:error, :stress_exceeded} -> {:error, :invalid_merge}
    end
  end

  @spec check_causal_stress(branch_record(), branch_record()) :: :ok | {:error, :stress_exceeded}
  def check_causal_stress(branch_a, branch_b) do
    # Calculate combined stress
    combined_stress = (Map.get(branch_a, :stress, 0.0) + Map.get(branch_b, :stress, 0.0)) / 2
    
    if combined_stress > 0.7 do
      {:error, :stress_exceeded}
    else
      :ok
    end
  end

  @spec prevent_merge(branch_id(), branch_id()) :: :ok
  def prevent_merge(branch_a_id, branch_b_id) do
    {:error, {:merge_blocked, branch_a_id, branch_b_id}}
  end

  @spec log_validation_result(term()) :: :ok
  def log_validation_result(result) do
    :telemetry.execute([:tiannara, :ctl, :branch_validation], %{count: 1}, %{result: result})
    :ok
  end
end
