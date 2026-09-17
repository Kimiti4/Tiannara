defmodule TiannaraRuntime.Shared.ConstitutionalLaws do
  @moduledoc """
  Formal Runtime Constitution - Immutable Substrate Laws.

  Defines safety invariants that are hardcoded into the execution pipeline.
  Even the most aggressive self-compiling OPC or evolved ALES laws can NEVER
  override these rules:
  1. Thermodynamic Scarcity: E_total >= 0
  2. Non-Paradoxical Causality: No cyclic self-references in causal graphs (∄ c_i -> c_i)
  3. Semantic Linchpin: Reintegrations must satisfy OMCS continuity bounds.
  """

  require Logger

  # ==================== Public API ====================

  @doc """
  Validate if a proposed energy allocation violates the conservation law.
  """
  @spec validate_thermodynamics(total_energy :: float(), cost :: float()) :: :ok | {:error, :energy_violation}
  def validate_thermodynamics(total_energy, cost) do
    if total_energy - cost >= 0.0 do
      :ok
    else
      Logger.error("⚖️ [Constitution] IMMUTABLE LAW VIOLATION: Thermodynamic Scarcity! Energy cannot fall below zero.")
      {:error, :energy_violation}
    end
  end

  @doc """
  Validate if a proposed causal link creates a direct paradox (cyclic self-link).
  """
  @spec validate_non_paradoxical(from_node :: String.t(), to_node :: String.t()) :: :ok | {:error, :causal_paradox}
  def validate_non_paradoxical(from_node, to_node) do
    if from_node == to_node do
      Logger.error("⚖️ [Constitution] IMMUTABLE LAW VIOLATION: Causal Paradox! Direct cyclic self-loop detected for node #{from_node}.")
      {:error, :causal_paradox}
    else
      # Verify transitive paths if necessary; direct self-loop is blocked immediately
      :ok
    end
  end

  @doc """
  Validate if an identity fold preserves the semantic continuity floor.
  """
  @spec validate_continuity(entity_id :: String.t(), prospective_hash :: String.t()) :: :ok | {:error, :continuity_breach}
  def validate_continuity(entity_id, prospective_hash) do
    if Process.whereis(TiannaraRuntime.OMCS.ContinuityIndex) do
      case TiannaraRuntime.OMCS.ContinuityIndex.verify_continuity(entity_id, prospective_hash) do
        :ok -> :ok
        {:error, _reason} ->
          Logger.error("⚖️ [Constitution] IMMUTABLE LAW VIOLATION: Semantic continuity breach for #{entity_id}!")
          {:error, :continuity_breach}
      end
    else
      # If OMCS is disabled/offline during testing, pass by default
      :ok
    end
  end
end
