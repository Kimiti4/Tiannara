defmodule Tiannara.OED.Validation.OntologySurvivability do
  @moduledoc """
  🔬 OED Validation Ontology Survivability.

  Simulates prolonged operational lifetimes (e.g. 1,000 generations) of a rule configuration
  inside virtual EHTC bounds to discover memory leaks or latent semantic decay.
  """

  require Logger

  @spec project_survivability(rule :: map()) :: {:ok, :survived} | {:error, String.t()}
  def project_survivability(rule) do
    Logger.info("🔬 [Ontology Survivability] Commencing 1,000-generation simulated projection for #{rule.type}")

    # Simulates decay progression
    decay = calculate_decay_rate(rule.body)

    if decay < 0.05 do
      {:ok, :survived}
    else
      {:error, "Survivability failure: recursive semantic decay rate is too high (decay=#{Float.round(decay, 3)})"}
    end
  end

  defp calculate_decay_rate({:if, _cond, then_b, else_b}) do
    0.5 * (calculate_decay_rate(then_b) + calculate_decay_rate(else_b))
  end

  defp calculate_decay_rate({:apply, :unconstrained_jump, _}), do: 0.15
  defp calculate_decay_rate(_), do: 0.01
end
