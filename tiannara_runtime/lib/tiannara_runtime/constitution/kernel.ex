defmodule Tiannara.Constitution.Kernel do
  @moduledoc """
  L0 - Constitution Kernel
  
  The ultimate authority in the Elixir Substrate.
  All state transitions, orchestration requests (from Python L5), 
  and physical events (from L1) MUST pass through this Kernel.
  
  If any constitutional invariant is violated, the transition is hard-rejected.
  """

  require Logger

  alias Tiannara.Constitution.{Conservation, Causality, Stabilization, Identity}

  @doc """
  Runs all constitutional invariant checks against a proposed state transition.
  
  ## Parameters
    - `params`: A map containing context for the checks.
      - `:current_energy`, `:proposed_cost` (Conservation)
      - `:causal_links` (Causality)
      - `:current_interventions`, `:proposed_intervention_cost`, `:max_budget` (Stabilization)
      - `:parent_anchors`, `:child_anchors` (Identity)
      
  Returns `:ok` if all invariants hold, or `{:error, reason}` if any fail.
  """
  def enforce_invariants(params) do
    with :ok <- check_conservation(params),
         :ok <- check_causality(params),
         :ok <- check_stabilization(params),
         :ok <- check_identity(params) do
      Logger.debug("Constitution Kernel: All invariants satisfied.")
      :ok
    else
      {:error, reason} ->
        Logger.error("Constitution Kernel: Invariant violation detected -> #{reason}")
        {:error, reason}
    end
  end

  defp check_conservation(%{current_energy: e, proposed_cost: c}) do
    Conservation.validate(e, c)
  end
  defp check_conservation(_), do: :ok # Skip if not provided

  defp check_causality(%{causal_links: links}) do
    Causality.validate(links)
  end
  defp check_causality(_), do: :ok

  defp check_stabilization(%{
         current_interventions: ci,
         proposed_intervention_cost: pc,
         max_budget: mb
       }) do
    Stabilization.validate(ci, pc, mb)
  end
  defp check_stabilization(_), do: :ok

  defp check_identity(%{parent_anchors: pa, child_anchors: ca}) do
    Identity.validate(pa, ca)
  end
  defp check_identity(_), do: :ok

end
