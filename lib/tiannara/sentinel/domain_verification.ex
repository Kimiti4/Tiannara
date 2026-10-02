defmodule Tiannara.Sentinel.DomainVerification do
  @moduledoc """
  Evidence-first independent domain verification and discovery enhancement.

  Domains may verify, reject, identify uncertainty, or propose a correction.
  Corrections are hypotheses for a subsequent controlled validation cycle, never
  silent mutations of the original discovery.
  """

  alias Tiannara.Domains.CanonicalRegistry
  alias Tiannara.Sentinel.DomainDependencyPlanner

  @type verifier :: (map() -> {:ok, map()} | {:error, term()} | map())

  @spec verify(map(), [atom()], verifier() | nil) :: {:ok, map()} | {:error, term()}
  def verify(discovery, related_domains, verifier)
      when is_map(discovery) and is_list(related_domains) do
    with :ok <- validate_discovery(discovery),
         {:ok, inferred} <- DomainDependencyPlanner.infer(discovery),
         {:ok, plan} <- build_plan(discovery, related_domains, inferred),
         :ok <- require_verifier(verifier),
         {:ok, results} <- verify_domains(plan, discovery, verifier, []) do
      {:ok, %{
        discovery_id: Map.get(discovery, :id),
        primary_domain: Map.get(discovery, :domain),
        required_domains: plan.domains,
        dependency_reasons: plan.reasons,
        results: results,
        mathematics: Map.fetch!(results, :mathematics),
        all_domains_passed: Enum.all?(Map.values(results), &passed?/1),
        enhancements: collect_enhancements(results),
        certification_eligible: false,
        epistemic_boundary: :independent_domain_verification
      }}
    end
  end

  @doc """
  Builds a verification plan from explicit discovery dependencies.

  The planner accepts declared domain dependencies and evidence references
  rather than maintaining a hard-coded domain implication table.
  """
  @spec plan(map(), [map() | atom()]) :: {:ok, map()} | {:error, term()}
  def plan(discovery, dependency_declarations)
      when is_map(discovery) and is_list(dependency_declarations) do
    primary = Map.get(discovery, :domain)

    declarations =
      dependency_declarations
      |> Enum.map(&normalize_dependency/1)
      |> Enum.reject(&is_nil/1)

    domains =
      ([%{domain: primary, reason: :originating_domain}] ++ declarations ++
         [%{domain: :mathematics, reason: :mandatory_epistemic_substrate}])
      |> Enum.uniq_by(& &1.domain)

    if Enum.all?(domains, &(valid_domain_id?(&1.domain))),
      do: {:ok, %{domains: Enum.map(domains, & &1.domain), reasons: domains}},
      else: {:error, :unknown_domain_in_verification_plan}
  end

  def verify(_, _, _), do: {:error, :invalid_domain_verification_request}

  defp validate_discovery(discovery) do
    required = [:id, :domain]
    case Enum.find(required, &(not Map.has_key?(discovery, &1))) do
      nil -> :ok
      key -> {:error, {:missing_discovery_field, key}}
    end
  end

  defp build_plan(discovery, related_domains, inferred) do
    declarations = Enum.map(related_domains, fn
      domain when is_atom(domain) -> %{domain: domain, reason: :declared_related_domain}
      declaration when is_map(declaration) -> declaration
      _ -> nil
    end) |> Enum.reject(&is_nil/1)

    plan(discovery, declarations ++ inferred.candidates)
  end

  defp normalize_dependency(domain) when is_atom(domain),
    do: %{domain: domain, reason: :declared_related_domain}
  defp normalize_dependency(%{domain: domain} = declaration) when is_atom(domain),
    do: Map.put_new(declaration, :reason, :evidence_declared_dependency)
  defp normalize_dependency(_), do: nil

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

  defp collect_enhancements(results) do
    results
    |> Enum.flat_map(fn {domain, result} ->
      result
      |> Map.get(:corrections, [])
      |> Enum.map(fn correction ->
        %{
          domain: domain,
          correction: correction,
          enhancement_status: :proposed,
          original_discovery_unchanged: true,
          requires_revalidation: true,
          learning_artifact: %{
            source: :independent_domain_review,
            domain: domain,
            recorded_for_acl_oavl: true
          }
        }
      end)
    end)
  end
end
