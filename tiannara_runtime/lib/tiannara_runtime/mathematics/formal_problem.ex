defmodule TiannaraRuntime.Mathematics.FormalProblem do
  @moduledoc """
  Canonical machine-readable representation of a mathematical research problem.

  Natural-language statements are not treated as proofs. A formal problem must
  carry explicit variables, domains, assumptions, definitions, target
  propositions, and provenance. Unresolved pieces remain explicit obligations.
  """

  @enforce_keys [:problem_id, :variables, :assumptions, :definitions, :targets]
  defstruct [
    :problem_id,
    :variables,
    :assumptions,
    :definitions,
    :targets,
    :provenance,
    :formalization_status
  ]

  @type t :: %__MODULE__{
    problem_id: binary(),
    variables: list(),
    assumptions: list(),
    definitions: list(),
    targets: list(),
    provenance: map() | nil,
    formalization_status: :complete | :partial | :unresolved
  }

  def new(attrs) when is_map(attrs) do
    variables = Map.get(attrs, :variables, Map.get(attrs, "variables", []))
    assumptions = Map.get(attrs, :assumptions, Map.get(attrs, "assumptions", []))
    definitions = Map.get(attrs, :definitions, Map.get(attrs, "definitions", []))
    targets = Map.get(attrs, :targets, Map.get(attrs, "targets", []))

    cond do
      not is_list(variables) or not is_list(assumptions) or
          not is_list(definitions) or not is_list(targets) ->
        {:error, :formal_problem_components_must_be_lists}

      targets == [] ->
        {:error, :formal_target_required}

      Enum.any?(variables, &invalid_variable?/1) ->
        {:error, :invalid_variable}

      true ->
        status = if Enum.any?(targets ++ assumptions ++ definitions, &unresolved?/1),
          do: :unresolved,
          else: :complete

        id = TiannaraRuntime.Mathematics.MathematicalID.from_canonical_map(%{
          "variables" => variables,
          "assumptions" => assumptions,
          "definitions" => definitions,
          "targets" => targets
        })

        {:ok, %__MODULE__{
          problem_id: "problem_" <> id,
          variables: variables,
          assumptions: assumptions,
          definitions: definitions,
          targets: targets,
          provenance: Map.get(attrs, :provenance, Map.get(attrs, "provenance")),
          formalization_status: status
        }}
    end
  end

  def unresolved?(%{status: status}) when status in [:unresolved, "unresolved"], do: true
  def unresolved?(%{"formal" => nil}), do: true
  def unresolved?(_), do: false

  defp invalid_variable?(%{name: name, domain: domain}), do: not is_binary(name) or is_nil(domain)
  defp invalid_variable?(%{"name" => name, "domain" => domain}), do: not is_binary(name) or is_nil(domain)
  defp invalid_variable?(_), do: true
end
