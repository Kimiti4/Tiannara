defmodule TiannaraRuntime.WorldModel.Composition.Engines.SharedVariableResolver do
  @moduledoc """
  Phase 17.6.3 — SharedVariableResolver engine.
  Resolves shared variables across domain interfaces deterministically.
  Detects conflicts and applies resolution strategies.
  """

  alias TiannaraRuntime.WorldModel.Composition.SharedVariable

  @doc """
  Resolves shared variables from a set of domain interfaces.
  Returns {:ok, [SharedVariable.t()]} or {:error, reason}.
  """
  def resolve(interfaces) do
    variable_map = collect_variables(interfaces)
    resolved = Enum.map(variable_map, &resolve_variable/1)
    {:ok, resolved}
  end

  @doc """
  Detects conflicts in a shared variable given domain-specific values.
  """
  def detect_conflict(variable, domain_values) do
    unique_values = domain_values |> Map.values() |> Enum.uniq()

    if length(unique_values) > 1 do
      %{variable | conflict: true, resolution_strategy: determine_strategy(variable)}
    else
      %{variable | conflict: false, resolved_value: hd(unique_values)}
    end
  end

  defp collect_variables(interfaces) do
    Enum.reduce(interfaces, %{}, fn iface, acc ->
      Enum.reduce(iface.shared_variables, acc, fn var_name, inner ->
        mapping = %{iface.source_domain => var_name}

        Map.update(inner, var_name, %{
          name: var_name,
          domain_mappings: mapping,
          sources: [iface.source_domain, iface.target_domain]
        }, fn existing ->
          %{
            existing
            | domain_mappings: Map.merge(existing.domain_mappings, mapping),
              sources: Enum.uniq(existing.sources ++ [iface.source_domain, iface.target_domain])
          }
        end)
      end)
    end)
  end

  defp resolve_variable({name, data}) do
    canonical = %{
      name: name,
      domain_mappings: data.domain_mappings
    }

    %SharedVariable{
      variable_id: SharedVariable.generate_id(canonical),
      name: name,
      domain_mappings: data.domain_mappings,
      conflict: false,
      resolution_strategy: :priority
    }
  end

  defp determine_strategy(variable) do
    variable.resolution_strategy || :priority
  end
end
