defmodule TiannaraOS.CivilizationAtlas do
  @moduledoc """
  Civilization Atlas - Searchable knowledge graph for the entire research civilization.

  Provides advanced query capabilities across all scientific registries, enabling
  complex searches like "Show all discoveries related to robotics" or "Show all
  theories supporting medicine."

  ## Query Capabilities

  The Atlas supports queries by:
  - Domain (all knowledge in a domain)
  - Theory (discoveries/laws based on a theory)
  - Principle (applications of universal principles)
  - Program (everything within a research program)
  - Validation status (operationally validated discoveries, etc.)
  - Confidence level (high-confidence theories, low-confidence hypotheses)
  - Time range (recent discoveries, historical laws)
  - Cross-domain relationships (knowledge transfer patterns)

  ## Usage Examples

      # All discoveries in robotics
      {:ok, discoveries} = CivilizationAtlas.query(:discoveries_in_domain, :robotics)

      # All theories supporting medicine
      {:ok, theories} = CivilizationAtlas.query(:theories_in_domain, :medicine)

      # Operationally validated discoveries
      {:ok, validated} = CivilizationAtlas.query(:validated_discoveries)

      # High-confidence theories
      {:ok, strong_theories} = CivilizationAtlas.query(:high_confidence_theories, 0.9)

      # Knowledge related to a principle
      {:ok, applications} = CivilizationAtlas.query(:principle_applications, :optionality_preservation)

      # Cross-domain knowledge transfer
      {:ok, transfers} = CivilizationAtlas.query(:cross_domain_transfers)
  """

  alias TiannaraOS.{
    PrincipleRegistry,
    ProgramRegistry,
    TheoryRegistry,
    LawRegistry,
    DiscoveryRegistry,
    UnknownRegistry
  }

  alias Tiannara.Domains.{CanonicalRegistry, KnowledgeCapitalBoundary}

  # ==================== Public Query API ====================

  @doc """
  Execute a query against the Civilization Atlas.

  ## Parameters
  - `query_type`: atom() - type of query to execute
  - `params`: any() - query parameters (varies by query type)

  ## Query Types

  ### Domain Queries
  - `:discoveries_in_domain` - params: domain_id
  - `:theories_in_domain` - params: domain_id
  - `:laws_in_domain` - params: domain_id
  - `:programs_in_domain` - params: domain_id
  - `:unknowns_in_domain` - params: domain_id

  ### Validation Queries
  - `:validated_discoveries` - params: none or domain_id
  - `:high_confidence_theories` - params: min_confidence (default 0.9)
  - `:low_confidence_theories` - params: max_confidence (default 0.5)
  - `:established_laws` - params: none

  ### Relationship Queries
  - `:theory_discoveries` - params: theory_id
  - `:discovery_law` - params: discovery_id
  - `:principle_applications` - params: principle_id
  - `:program_theories` - params: program_id
  - `:program_discoveries` - params: program_id

  ### Priority Queries
  - `:critical_unknowns` - params: none or domain_id
  - `:neglected_domains` - params: none
  - `:high_debt_domains` - params: min_debt_count

  ### Cross-Domain Queries
  - `:cross_domain_transfers` - params: none
  - `:shared_principles` - params: none
  - `:domain_maturity_comparison` - params: none

  ## Returns
  {:ok, query_results} | {:error, String.t()}
  """
  def query(query_type, params \\ nil) do
    case query_type do
      # Domain Queries
      :discoveries_in_domain ->
        query_discoveries_in_domain(params)

      :theories_in_domain ->
        query_theories_in_domain(params)

      :laws_in_domain ->
        query_laws_in_domain(params)

      :programs_in_domain ->
        query_programs_in_domain(params)

      :unknowns_in_domain ->
        query_unknowns_in_domain(params)

      # Validation Queries
      :validated_discoveries ->
        query_validated_discoveries(params)

      :high_confidence_theories ->
        query_high_confidence_theories(params)

      :low_confidence_theories ->
        query_low_confidence_theories(params)

      :established_laws ->
        query_established_laws()

      # Relationship Queries
      :theory_discoveries ->
        query_theory_discoveries(params)

      :discovery_law ->
        query_discovery_law(params)

      :principle_applications ->
        query_principle_applications(params)

      :program_theories ->
        query_program_theories(params)

      :program_discoveries ->
        query_program_discoveries(params)

      # Priority Queries
      :critical_unknowns ->
        query_critical_unknowns(params)

      :neglected_domains ->
        query_neglected_domains()

      :high_debt_domains ->
        query_high_debt_domains(params)

      # Cross-Domain Queries
      :cross_domain_transfers ->
        query_cross_domain_transfers()

      :shared_principles ->
        query_shared_principles()

      :domain_maturity_comparison ->
        query_domain_maturity_comparison()

      _ ->
        {:error, "Unknown query type: #{inspect(query_type)}"}
    end
  end

  @doc """
  Get comprehensive knowledge map for a domain.

  Returns all knowledge artifacts (principles, programs, theories, laws,
  discoveries, unknowns) for a specific domain in a single query.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, domain_knowledge_map}
  """
  def get_domain_knowledge_map(domain_id) do
    with {:ok, domain} <- CanonicalRegistry.get(domain_id),
         {:ok, programs} <- ProgramRegistry.list_by_domain(domain_id),
         {:ok, theories} <- TheoryRegistry.list_by_domain(domain_id),
         {:ok, laws} <- LawRegistry.list_by_domain(domain_id),
         {:ok, discoveries} <- DiscoveryRegistry.list_by_domain(domain_id),
         {:ok, unknowns} <- UnknownRegistry.list_open_by_domain(domain_id),
         {:ok, principles} <- PrincipleRegistry.for_domain(domain_id) do
      knowledge_capital = KnowledgeCapitalBoundary.get(domain_id)
      knowledge_map = %{
        domain: domain,
        principles: principles,
        programs: programs,
        theories: theories,
        laws: laws,
        discoveries: discoveries,
        unknowns: unknowns,
        knowledge_capital: knowledge_capital,
        summary: %{
          total_principles: length(principles),
          total_programs: length(programs),
          total_theories: length(theories),
          total_laws: length(laws),
          total_discoveries: length(discoveries),
          total_unknowns: length(unknowns)
        }
      }

      {:ok, knowledge_map}
    end
  end

  @doc """
  Find all knowledge artifacts related to a specific theory.

  Traces theory → discoveries → laws → applications relationships.

  ## Parameters
  - `theory_id`: atom()

  ## Returns
  {:ok, theory_knowledge_network}
  """
  def get_theory_knowledge_network(theory_id) do
    with {:ok, theory} <- TheoryRegistry.get(theory_id),
         {:ok, discoveries} <- DiscoveryRegistry.find_by_theory(theory_id) do
      # Find laws that originated from this theory
      laws_from_theory = case LawRegistry.get(theory_id) do
        {:ok, law} -> [law]
        {:error, _} -> []
      end

      # Collect all applications from discoveries
      applications = Enum.flat_map(discoveries, fn d -> d.applications end)

      network = %{
        theory: theory,
        discoveries: discoveries,
        laws: laws_from_theory,
        applications: applications,
        summary: %{
          discovery_count: length(discoveries),
          law_count: length(laws_from_theory),
          application_count: length(applications),
          average_discovery_confidence: if(length(discoveries) > 0,
            do: Float.round(Enum.sum(Enum.map(discoveries, & &1.confidence)) / length(discoveries), 2),
            else: 0.0
          )
        }
      }

      {:ok, network}
    end
  end

  # ==================== Private Query Implementations ====================

  defp query_discoveries_in_domain(domain_id) do
    DiscoveryRegistry.list_by_domain(domain_id)
  end

  defp query_theories_in_domain(domain_id) do
    TheoryRegistry.list_by_domain(domain_id)
  end

  defp query_laws_in_domain(domain_id) do
    LawRegistry.list_by_domain(domain_id)
  end

  defp query_programs_in_domain(domain_id) do
    ProgramRegistry.list_by_domain(domain_id)
  end

  defp query_unknowns_in_domain(domain_id) do
    UnknownRegistry.list_open_by_domain(domain_id)
  end

  defp query_validated_discoveries(domain_id) do
    if domain_id do
      case DiscoveryRegistry.list_by_domain(domain_id) do
        {:ok, discoveries} ->
          validated = Enum.filter(discoveries, fn d ->
            d.validation_status == :operationally_validated
          end)
          {:ok, validated}

        error -> error
      end
    else
      # Get validated discoveries across all domains
      domains = CanonicalRegistry.all()

      all_validated = Enum.flat_map(domains, fn domain ->
        case DiscoveryRegistry.list_by_domain(domain.id) do
          {:ok, discoveries} ->
            Enum.filter(discoveries, fn d ->
              d.validation_status == :operationally_validated
            end)
          _ -> []
        end
      end)

      {:ok, all_validated}
    end
  end

  defp query_high_confidence_theories(min_confidence) do
    domains = CanonicalRegistry.all()

    high_confidence = Enum.flat_map(domains, fn domain ->
      case TheoryRegistry.list_by_domain(domain.id) do
        {:ok, theories} ->
          Enum.filter(theories, fn t -> t.confidence >= min_confidence end)
        _ -> []
      end
    end)

    {:ok, high_confidence}
  end

  defp query_low_confidence_theories(max_confidence) do
    domains = CanonicalRegistry.all()

    low_confidence = Enum.flat_map(domains, fn domain ->
      case TheoryRegistry.list_by_domain(domain.id) do
        {:ok, theories} ->
          Enum.filter(theories, fn t -> t.confidence < max_confidence and t.status == :active end)
        _ -> []
      end
    end)

    {:ok, low_confidence}
  end

  defp query_established_laws do
    domains = CanonicalRegistry.all()

    established = Enum.flat_map(domains, fn domain ->
      case LawRegistry.list_by_domain(domain.id) do
        {:ok, laws} ->
          Enum.filter(laws, fn l -> l.status in [:established, :fundamental] end)
        _ -> []
      end
    end)

    {:ok, established}
  end

  defp query_theory_discoveries(theory_id) do
    DiscoveryRegistry.find_by_theory(theory_id)
  end

  defp query_discovery_law(discovery_id) do
    case DiscoveryRegistry.get(discovery_id) do
      {:ok, discovery} ->
        if discovery.law_id do
          LawRegistry.get(discovery.law_id)
        else
          {:ok, nil}
        end

      error -> error
    end
  end

  defp query_principle_applications(principle_id) do
    PrincipleRegistry.get(principle_id)
  end

  defp query_program_theories(program_id) do
    case ProgramRegistry.get(program_id) do
      {:ok, program} ->
        theories = Enum.map(program.theory_ids, fn theory_id ->
          case TheoryRegistry.get(theory_id) do
            {:ok, theory} -> theory
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)

        {:ok, theories}

      error -> error
    end
  end

  defp query_program_discoveries(program_id) do
    case ProgramRegistry.get(program_id) do
      {:ok, program} ->
        discoveries = Enum.map(program.discovery_ids, fn discovery_id ->
          case DiscoveryRegistry.get(discovery_id) do
            {:ok, discovery} -> discovery
            _ -> nil
          end
        end)
        |> Enum.filter(& &1)

        {:ok, discoveries}

      error -> error
    end
  end

  defp query_critical_unknowns(domain_id) do
    if domain_id do
      UnknownRegistry.get_by_priority(domain_id, :critical)
    else
      # Get critical unknowns across all domains
      domains = CanonicalRegistry.all()

      all_critical = Enum.flat_map(domains, fn domain ->
        case UnknownRegistry.get_by_priority(domain.id, :critical) do
          {:ok, unknowns} -> unknowns
          _ -> []
        end
      end)

      {:ok, all_critical}
    end
  end

  defp query_neglected_domains do
    # Integrate with ResearchDirector to identify neglected domains
    require Logger
    Logger.debug("Tiannara.OS.ResearchDirector.identify_neglected_domains/0 is unavailable")
    {:ok, []}
  end

  defp query_high_debt_domains(min_debt_count) do
    case UnknownRegistry.count_by_domain() do
      {:ok, counts} ->
        high_debt = Enum.filter(counts, fn {_domain, count} ->
          count >= min_debt_count
        end)
        |> Enum.map(fn {domain, _count} -> domain end)

        {:ok, high_debt}

      error -> error
    end
  end

  defp query_cross_domain_transfers do
    # Identify discoveries with applications in multiple domains
    domains = CanonicalRegistry.all()

    transfers = Enum.flat_map(domains, fn domain ->
      case DiscoveryRegistry.list_by_domain(domain.id) do
        {:ok, discoveries} ->
          Enum.filter(discoveries, fn d ->
            # Check if discovery has applications in other domains
            application_domains = Enum.map(d.applications, & &1[:domain])
            |> Enum.uniq()

            length(application_domains) > 1
          end)
          |> Enum.map(fn d ->
            %{
              discovery: d,
              source_domain: domain.id,
              application_domains: Enum.map(d.applications, & &1[:domain]) |> Enum.uniq()
            }
          end)

        _ -> []
      end
    end)

    {:ok, transfers}
  end

  defp query_shared_principles do
    # Find principles applied across multiple domains
    {:ok, principles} = PrincipleRegistry.list_all()

    shared = Enum.filter(principles, fn p ->
      map_size(p.domain_applications) > 3
    end)

    {:ok, shared}
  end

  defp query_domain_maturity_comparison do
    domains = CanonicalRegistry.all()

    comparisons = Enum.map(domains, fn domain ->
      knowledge_capital = KnowledgeCapitalBoundary.get(domain.id)

      maturity_score = calculate_maturity_score(knowledge_capital)

      %{
        domain: domain.id,
        domain_name: domain.name,
        maturity_score: maturity_score,
        knowledge_capital_summary: %{
          theories: length(knowledge_capital.theories),
          validated_theories: length(knowledge_capital.validated_theories),
          laws: length(knowledge_capital.laws),
          discoveries: length(knowledge_capital.discoveries),
          applications: length(knowledge_capital.applications),
          unknowns: length(knowledge_capital.unknowns)
        }
      }
    end)
    |> Enum.sort_by(& &1.maturity_score, :desc)

    {:ok, comparisons}
  end

  defp calculate_maturity_score(knowledge_capital) do
    # Simple scoring algorithm
    theory_score = length(knowledge_capital.validated_theories) * 10
    law_score = length(knowledge_capital.laws) * 20
    discovery_score = length(knowledge_capital.discoveries) * 5
    application_score = length(knowledge_capital.applications) * 3
    unknown_penalty = length(knowledge_capital.unknowns) * 2

    max(0, theory_score + law_score + discovery_score + application_score - unknown_penalty)
  end
end
