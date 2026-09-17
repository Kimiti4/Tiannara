defmodule TiannaraRuntime.WorldModel.Composition.Engines.SynchronizationEngine do
  @moduledoc """
  Phase 17.6.4 — SynchronizationEngine engine.
  Derives synchronization rules from domain interfaces and shared variables.
  Supports discrete, continuous, and event-driven modes.
  """

  alias TiannaraRuntime.WorldModel.Composition.SynchronizationRule

  @doc """
  Derives synchronization rules from interfaces and resolved variables.
  Returns {:ok, [SynchronizationRule.t()]} or {:error, reason}.
  """
  def derive(interfaces, variables) do
    rules =
      Enum.flat_map(interfaces, fn iface ->
        Enum.map(iface.shared_variables, fn var_name ->
          variable = Enum.find(variables, &(&1.name == var_name))

          canonical = %{
            source_model: iface.source_domain,
            target_model: iface.target_domain,
            variable: var_name,
            mode: :discrete
          }

          %SynchronizationRule{
            rule_id: SynchronizationRule.generate_id(canonical),
            source_model: iface.source_domain,
            target_model: iface.target_domain,
            variable: var_name,
            mode: :discrete,
            frequency: 1,
            metadata: %{
              derived_from: iface.interface_id,
              variable_id: if(variable, do: variable.variable_id, else: nil)
            }
          }
        end)
      end)

    {:ok, rules}
  end

  @doc """
  Validates temporal compatibility of synchronization rules.
  """
  def validate_temporal(rules, model_temporal_modes) do
    errors =
      Enum.reduce(rules, [], fn rule, acc ->
        source_mode = Map.get(model_temporal_modes, rule.source_model)
        target_mode = Map.get(model_temporal_modes, rule.target_model)

        if compatible?(source_mode, target_mode) do
          acc
        else
          [%{rule: rule.rule_id, error: :temporal_incompatibility} | acc]
        end
      end)

    if errors == [], do: {:ok, rules}, else: {:error, errors}
  end

  @doc """
  Executes a synchronization step between two models.
  """
  def sync(rule, source_state, target_state) do
    case rule.mode do
      :discrete -> sync_discrete(source_state, target_state, rule)
      :continuous -> sync_continuous(source_state, target_state, rule)
      :event_driven -> {:ok, source_state, target_state}
    end
  end

  defp compatible?(:discrete, :discrete), do: true
  defp compatible?(:continuous, :continuous), do: true
  defp compatible?(:event_driven, :event_driven), do: true
  defp compatible?(:discrete, :event_driven), do: true
  defp compatible?(:event_driven, :discrete), do: true
  defp compatible?(_, _), do: false

  defp sync_discrete(source, target, rule) do
    transformed = apply_transform(source, rule)
    {:ok, source, Map.put(target, rule.variable, transformed)}
  end

  defp sync_continuous(source, target, rule) do
    transformed = apply_transform(source, rule)
    {:ok, source, Map.put(target, rule.variable, transformed)}
  end

  defp apply_transform(state, rule) do
    case rule.transform do
      nil -> Map.get(state, rule.variable)
      transform when is_map(transform) ->
        fn_transform = Map.get(transform, :fn)
        if fn_transform, do: fn_transform.(Map.get(state, rule.variable)), else: Map.get(state, rule.variable)
    end
  end
end
