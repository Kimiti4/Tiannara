defmodule Tiannara.CIS do
  @moduledoc """
  Cognitive Immune System constraint surface.

  CIS constrains; it does not authorize or decide. Decisions remain with Core/CEL/C14.
  """

  @spec validate_plan(map()) :: {:ok, map()} | {:error, [atom()]}
  def validate_plan(plan) when is_map(plan) do
    violations =
      []
      |> require_field(plan, :id)
      |> require_field(plan, :steps)
      |> require_field(plan, :authority)
      |> require_field(plan, :evidence)
      |> require_field(plan, :provenance)
      |> reject_unbounded_risk(plan)
      |> reject_missing_authority(plan)
      |> reject_conflicting_domains(plan)

    case violations do
      [] -> {:ok, Map.put(plan, :cis_status, :constrained_ok)}
      errors -> {:error, Enum.reverse(errors)}
    end
  end

  def validate_plan(_), do: {:error, [:invalid_plan]}

  @spec check_domain_diversity(map()) :: {:ok, map()} | {:error, atom()}
  def check_domain_diversity(weights) when is_map(weights) do
    active = Enum.count(weights, fn {_domain, weight} -> is_number(weight) and weight > 0 end)
    total = Enum.reduce(weights, 0.0, fn {_d, w}, acc -> acc + if(is_number(w), do: max(w, 0), else: 0) end)
    dominant =
      if total > 0 do
        {_dominant_domain, dominant_weight} =
          Enum.max_by(weights, fn {_d, w} -> if(is_number(w), do: w, else: 0) end)

        dominant_weight / total
      else
        1.0
      end
    cond do
      active < 2 -> {:error, :insufficient_domain_diversity}
      dominant > 0.8 -> {:error, :domain_monoculture_risk}
      true -> {:ok, %{active_domains: active, dominant_share: dominant}}
    end
  end

  def check_domain_diversity(_), do: {:error, :invalid_domain_weights}

  defp require_field(errors, plan, field) do
    case Map.get(plan, field) do
      nil -> [String.to_atom("missing_#{field}") | errors]
      [] -> [String.to_atom("missing_#{field}") | errors]
      _ -> errors
    end
  end

  defp reject_unbounded_risk(errors, plan) do
    risk = Map.get(plan, :risk, Map.get(plan, :risk_score))

    cond do
      not is_number(risk) -> [:risk_unavailable | errors]
      risk > 0.8 -> [:risk_exceeds_cis_threshold | errors]
      true -> errors
    end
  end

  defp reject_missing_authority(errors, plan) do
    if Map.get(plan, :authority) in [nil, :unknown], do: [:missing_authority | errors], else: errors
  end

  defp reject_conflicting_domains(errors, plan) do
    if Map.get(plan, :contradiction_count, 0) > 0, do: [:unresolved_contradiction | errors], else: errors
  end
end
