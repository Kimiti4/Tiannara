defmodule TiannaraRuntime.WorldModel.Composition.Engines.InterfaceRegistry do
  @moduledoc """
  Phase 17.6.2 — InterfaceRegistry engine.
  Registers and manages domain interfaces between world models.
  Provides deterministic interface discovery, registration, and validation.
  """

  alias TiannaraRuntime.WorldModel.Composition.DomainInterface
  alias TiannaraRuntime.WorldModel.Composition.InterfaceConstraint

  @doc """
  Registers domain interfaces for a list of models.
  Returns {:ok, [DomainInterface.t()]} or {:error, reason}.
  """
  def register(models, domain_definitions) do
    interfaces =
      Enum.reduce(domain_definitions, [], fn {source, target, vars, direction, opts}, acc ->
        constraints = Keyword.get(opts, :constraints, [])
        priority = Keyword.get(opts, :priority, 100)

        canonical = %{
          source_domain: source,
          target_domain: target,
          shared_variables: Enum.sort(vars),
          direction: direction
        }

        interface = %DomainInterface{
          interface_id: DomainInterface.generate_id(canonical),
          source_domain: source,
          target_domain: target,
          shared_variables: Enum.sort(vars),
          direction: direction,
          constraints: Enum.map(constraints, &build_constraint/1),
          priority: priority,
          metadata: Keyword.get(opts, :metadata, %{})
        }

        [interface | acc]
      end)

    {:ok, Enum.reverse(interfaces)}
  end

  @doc """
  Validates that all interfaces reference valid models.
  """
  def validate(interfaces, model_ids) do
    model_set = MapSet.new(model_ids)

    errors =
      Enum.reduce(interfaces, [], fn iface, acc ->
        cond do
          !MapSet.member?(model_set, iface.source_domain) ->
            [%{interface: iface.interface_id, error: :unknown_source_domain} | acc]

          !MapSet.member?(model_set, iface.target_domain) ->
            [%{interface: iface.interface_id, error: :unknown_target_domain} | acc]

          true ->
            acc
        end
      end)

    if errors == [], do: {:ok, interfaces}, else: {:error, errors}
  end

  @doc """
  Finds all interfaces for a given domain.
  """
  def find_by_domain(interfaces, domain) do
    Enum.filter(interfaces, fn iface ->
      iface.source_domain == domain || iface.target_domain == domain
    end)
  end

  defp build_constraint({type, expression}) do
    canonical = %{type: type, expression: expression}
    %InterfaceConstraint{
      constraint_id: InterfaceConstraint.generate_id(canonical),
      type: type,
      expression: expression
    }
  end
end
