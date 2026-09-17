defmodule Tiannara.OED.ACM.OntologyTranslation do
  @moduledoc """
  ⚔️ ACM Ontology Translation.

  Translates configuration rules and properties across domain interfaces to guarantee
  semantic coherence and prevent meaning drift across node namespaces.
  """

  require Logger

  @spec translate(rule :: map(), from_domain :: atom(), to_domain :: atom()) :: {:ok, map()} | {:error, String.t()}
  def translate(rule, from_domain, to_domain) do
    Logger.debug("⚔️ [Ontology Translation] Mapping rule type #{rule.type} from #{from_domain} to #{to_domain}")

    try do
      translated_body = translate_body(rule.body, from_domain, to_domain)
      {:ok, %{rule | body: translated_body}}
    rescue
      e -> {:error, "Ontology translation failure: #{inspect(e)}"}
    end
  end

  # ==================== Internal Translators ====================

  defp translate_body({:diffuse, :pressure_field, rate, cap}, :olef, :omce) do
    # Map OLEF pressure fields to corresponding OMCE density parameters
    {:compress, :ontology_density, rate * 0.5, cap}
  end

  defp translate_body({:if, cond, then_branch, else_branch}, from, to) do
    {:if, translate_cond(cond, from, to), translate_body(then_branch, from, to), translate_body(else_branch, from, to)}
  end

  defp translate_body(action, _from, _to), do: action

  defp translate_cond({op, :curvature_stress, val}, :hsv, :ctl) do
    # HSV stress translates to CTL causal stress
    {op, :causal_stress, val * 0.8}
  end

  defp translate_cond(cond, _from, _to), do: cond
end
