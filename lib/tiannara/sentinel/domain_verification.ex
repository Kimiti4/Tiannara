defmodule Tiannara.Sentinel.DomainVerification do
  @moduledoc """
  Independent domain verification gate for discoveries.

  A discovery is not domain-certified merely because its originating domain
  validates it. Every declared related domain must independently evaluate the
  same canonical evidence. The mathematics substrate is mandatory for every
  discovery and is kept separate from the 20-domain ontology.
  """

  alias Tiannara.Domains.CanonicalRegistry

  @type verifier :: (map() -> {:ok, map()} | {:error, term()} | map())

  @spec verify(map(), [atom()], verifier() | nil) :: {:ok, map()} | {:error, term()}
  def verify(discovery, related_domains, verifier)
      when is_map(discovery) and is_list(related_domains) do
    with :ok <- validate_discovery(discovery),
         {:ok, plan} <- build_plan(discovery, related_domains),
         :ok <- require_verifier(verifier),
         {:ok, results} <- verify_domains(plan, discovery, verifier, []) do
      {:ok, %{
        discovery_id: Map.get(discovery, :id),
        primary_domain: Map.get(discovery, :domain),
        required_domains: plan.domains,
        results: results,
        mathematics: Map.fetch!(results, :mathematics),
        all_domains_passed: Enum.all?(Map.values(results), &passed?/1),
        certification_eligible: false,
        epistemic_boundary: :independent_domain_verification
      }}
    end
  end

  def verify(_, _, _), do: {:error, :invalid_domain_verification_request}

  defp validate_discovery(discovery) do
    required = [:id, :domain]
    case Enum.find(required, &(not Map.has_key?(discovery, &1))) do
      nil -> :ok
      key -> {:error, {:missing_discovery_field, key}}
    end
  end

  defp build_plan(discovery, related_domains) do
    primary = Map.fetch!(discovery, :domain)
    domains =
      ([primary | related_domains] ++ [:mathematics])
      |> Enum.uniq()

    if Enum.all?(domains, &valid_domain_id?/1),
      do: {:ok, %{domains: domains}},
      else: {:error, :unknown_domain_in_verification_plan}
  end

  defp valid_domain_id?(:mathematics), do: true
  defp valid_domain_id?(domain) when is_atom(domain) do
    case CanonicalRegistry.all() do
      ids when is_list(ids) -> domain in ids
      _ -> false
    end
  catch
    :exit, _ -> false
  end
  defp valid_domain_id?(_), do: false

  defp require_verifier(fun) when is_function(fun, 1), do: :ok
  defp require_verifier(_), do: {:error, :domain_verifier_unavailable}

  defp verify_domains([], _discovery, _verifier, acc), do: {:ok, acc}

  defp verify_domains([domain | rest], discovery, verifier, acc) do
    evidence = %{
      discovery_id: Map.fetch!(discovery, :id),
      primary_domain: Map.fetch!(discovery, :domain),
      verification_domain: domain,
      discovery_evidence: discovery,
      mathematics_required: true,
      independent: true
    }

    case invoke(verifier, evidence) do
      {:ok, result} ->
        verify_domains(rest, discovery, verifier, Map.put(acc, domain, result))

      {:error, reason} ->
        {:error, {:domain_verification_failed, domain, reason}}
    end
  end

  defp invoke(fun, evidence) do
    case fun.(evidence) do
      {:ok, result} when is_map(result) -> {:ok, result}
      result when is_map(result) -> {:ok, result}
      {:error, reason} -> {:error, reason}
      other -> {:error, {:invalid_domain_verification_result, other}}
    end
  rescue
    exception -> {:error, {:domain_verifier_crashed, exception}}
  end

  defp passed?(result) when is_map(result) do
    Map.get(result, :status) in [:pass, :passed] and
      Map.get(result, :independent, false) == true
  end
  defp passed?(_), do: false
end
