defmodule Tiannara.Sentinel.DomainDependencyPlanner do
  @moduledoc """
  Evidence-bound inference of candidate verification domains.

  This planner does not certify relevance and never silently chooses a domain
  based on keyword matching. It extracts explicit dependency declarations from
  discovery structure and returns an auditable candidate plan. Mathematics is
  always mandatory as the epistemic substrate.
  """

  alias Tiannara.Domains.CanonicalRegistry

  @spec infer(map()) :: {:ok, map()} | {:error, term()}
  def infer(discovery) when is_map(discovery) do
    with :ok <- validate(discovery),
         {:ok, candidates} <- extract(discovery),
         {:ok, domains} <- normalize(candidates, Map.get(discovery, :domain)) do
      {:ok, %{
        discovery_id: Map.get(discovery, :id),
        candidates: domains,
        mathematics_required: true,
        status: :candidate_plan,
        certification_eligible: false,
        inference_basis: :explicit_evidence_dependencies
      }}
    end
  end

  def infer(_), do: {:error, :invalid_discovery}

  defp validate(d) do
    if is_binary(Map.get(d, :id)) or is_atom(Map.get(d, :id)) do
      if is_atom(Map.get(d, :domain)), do: :ok, else: {:error, :missing_primary_domain}
    else
      {:error, :missing_discovery_id}
    end
  end

  defp extract(d) do
    sources = [
      {:declared_domains, Map.get(d, :related_domains, [])},
      {:mechanism_dependencies, Map.get(d, :mechanism_dependencies, [])},
      {:variable_domains, Map.get(d, :variable_domains, [])},
      {:equation_domains, Map.get(d, :equation_domains, [])},
      {:artifact_domains, Map.get(d, :artifact_domains, [])},
      {:effect_domains, Map.get(d, :effect_domains, [])},
      {:provenance_domains, Map.get(d, :provenance_domains, [])}
    ]

    {:ok,
     Enum.flat_map(sources, fn {basis, values} ->
       Enum.map(List.wrap(values), fn
         domain when is_atom(domain) -> %{domain: domain, basis: basis}
         %{domain: domain} = item when is_atom(domain) -> Map.put_new(item, :basis, basis)
         _ -> nil
       end)
       |> Enum.reject(&is_nil/1)
     end)}
  end

  defp normalize(candidates, primary) do
    entries =
      ([%{domain: primary, basis: :originating_domain}] ++ candidates ++
       [%{domain: :mathematics, basis: :mandatory_epistemic_substrate}])
      |> Enum.uniq_by(& &1.domain)

    if Enum.all?(entries, &(valid?(&1.domain))) do
      {:ok, entries}
    else
      {:error, :unknown_domain_in_dependency_plan}
    end
  end

  defp valid?(:mathematics), do: true
  defp valid?(domain) when is_atom(domain) do
    case CanonicalRegistry.all() do
      ids when is_list(ids) -> domain in ids
      _ -> false
    end
  catch
    :exit, _ -> false
  end
  defp valid?(_), do: false
end
