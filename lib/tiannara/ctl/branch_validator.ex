defmodule Tiannara.Ctl.BranchValidator do
  @moduledoc """
  Validates branch compatibility before a merge to prevent paradox-inducing
  merges in the Causal Tensegrity Lattice.

  Branch evidence is read exclusively from the canonical registry
  `Tiannara.CTL.CausalRegistry` (uppercase CTL). The similarly cased
  explicit stub `Tiannara.Ctl.CausalRegistry` (constant stress `0.0`) was
  deleted during remediation: on case-insensitive filesystems its beam file
  collided with the real module's, making both unreliable
  (capability ledger D-B).

  Every evidence gap fails closed with a named reason:

    * `:registry_unavailable`          — canonical registry not running
    * `:threshold_configuration_absent` — stress threshold not configured
    * `:branch_not_found`              — branch never registered
    * `:branch_evidence_incomplete`    — branch record lacks a stress value
    * `:invalid_merge`                 — combined stress above threshold
  """

  alias Tiannara.CTL.CausalRegistry

  @type branch_id :: String.t()
  @type branch_record :: map()

  @spec validate_merge(branch_id(), branch_id()) ::
          {:ok, :valid}
          | {:error,
             :branch_not_found
             | :registry_unavailable
             | :threshold_configuration_absent
             | :branch_evidence_incomplete
             | :invalid_merge}
  def validate_merge(branch_a_id, branch_b_id) do
    with {:ok, threshold} <- stress_threshold(),
         {:ok, branch_a} <- CausalRegistry.get_branch(branch_a_id),
         {:ok, branch_b} <- CausalRegistry.get_branch(branch_b_id),
         :ok <- check_causal_stress(branch_a, branch_b, threshold) do
      {:ok, :valid}
    else
      {:error, :not_found} -> {:error, :branch_not_found}
      {:error, :stress_exceeded} -> {:error, :invalid_merge}
      {:error, reason} -> {:error, reason}
    end
  catch
    # Registry died mid-call: fail closed rather than crash the caller.
    :exit, _ -> {:error, :registry_unavailable}
  end

  @doc """
  Combined causal-stress threshold above which a merge is rejected.

  Sourced from configuration (`:ctl_causal_stress_threshold`); when the key
  is absent validation fails closed instead of falling back to a built-in
  default value.
  """
  @spec stress_threshold() :: {:ok, number()} | {:error, :threshold_configuration_absent}
  def stress_threshold do
    case Application.fetch_env(:tiannara, :ctl_causal_stress_threshold) do
      {:ok, threshold} when is_number(threshold) -> {:ok, threshold}
      _missing_or_invalid -> {:error, :threshold_configuration_absent}
    end
  end

  @spec check_causal_stress(branch_record(), branch_record(), number()) ::
          :ok | {:error, :stress_exceeded | :branch_evidence_incomplete}
  def check_causal_stress(branch_a, branch_b, threshold)
      when is_map(branch_a) and is_map(branch_b) and is_number(threshold) do
    stress_a = Map.get(branch_a, :stress)
    stress_b = Map.get(branch_b, :stress)

    if is_number(stress_a) and is_number(stress_b) do
      if (stress_a + stress_b) / 2 > threshold do
        {:error, :stress_exceeded}
      else
        :ok
      end
    else
      {:error, :branch_evidence_incomplete}
    end
  end
end
