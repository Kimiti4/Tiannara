defmodule TiannaraOS.ResearchDirector do
  @moduledoc """
  Research Director - Orchestrates research prioritization and resource allocation.

  The Research Director analyzes unknowns, theories, discoveries, and domain health
  to determine which experiments should be run next, which domains need additional
  research, and how to maximize expected information gain while reducing uncertainty.

  ## Constitutional Role

  The Research Director sits above individual registries and composes them to make
  strategic decisions:

  ```
  Research Director (this module)
      ↓
  Unknown Registry → Identifies knowledge gaps
  Theory Registry → Evaluates theory competition
  Discovery Registry → Assesses validation status
  Domain Registry → Monitors portfolio health
  Program Registry → Allocates resources
  ```

  ## Responsibilities

  1. **Identify Neglected Domains** - Find domains with high research debt
  2. **Allocate Research Effort** - Distribute resources based on priority
  3. **Maximize Information Gain** - Prioritize experiments with highest expected value
  4. **Reduce Uncertainty** - Target areas with highest uncertainty first
  5. **Maintain Balanced Portfolios** - Ensure no domain is starved of attention

  ## Priority Calculation

  Research priorities are calculated using:
  - Unknown severity (critical > high > medium > low)
  - Domain research debt (more unknowns = higher priority)
  - Theory confidence gaps (low-confidence theories need validation)
  - Discovery validation backlog (unvalidated discoveries block progress)
  - Resource availability

  ## Usage

      {:ok, priorities} = ResearchDirector.calculate_priorities()
      {:ok, next_experiment} = ResearchDirector.suggest_next_experiment(:medicine)
      {:ok, allocation} = ResearchDirector.allocate_resources()
  """

  use GenServer

  alias TiannaraOS.{
    UnknownRegistry,
    TheoryRegistry,
    DiscoveryRegistry,
    UnknownDependencyGraph
  }

  alias Tiannara.Domains.{CanonicalRegistry, KnowledgeCapitalBoundary}

  defstruct [
    :last_analysis_timestamp,
    :domain_priorities,
    :recommended_experiments,
    :resource_allocation,
    :neglected_domains,
    :research_debt_summary,
    :analysis_metadata
  ]

  @type t :: %__MODULE__{
    last_analysis_timestamp: DateTime.t(),
    domain_priorities: map(),
    recommended_experiments: [map()],
    resource_allocation: map(),
    neglected_domains: [atom()],
    research_debt_summary: map(),
    analysis_metadata: map()
  }

  # ==================== Public API ====================

  @doc """
  Start the Research Director GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Calculate research priorities across all domains.

  Analyzes unknowns, theories, discoveries, and domain health to produce
  a prioritized list of research objectives.

  ## Returns
  {:ok, ResearchDirector.t()}
  """
  def calculate_priorities do
    GenServer.call(__MODULE__, :calculate_priorities)
  end

  @doc """
  Suggest the next experiment to run for a specific domain.

  Based on current unknowns, theory gaps, and resource availability.

  ## Parameters
  - `domain_id`: atom()

  ## Returns
  {:ok, experiment_suggestion} | {:error, String.t()}
  """
  def suggest_next_experiment(domain_id) do
    GenServer.call(__MODULE__, {:suggest_next_experiment, domain_id})
  end

  @doc """
  Allocate research resources across domains.

  Distributes available resources based on calculated priorities and
  domain needs.

  ## Returns
  {:ok, resource_allocation_map}
  """
  def allocate_resources do
    GenServer.call(__MODULE__, :allocate_resources)
  end

  @doc """
  Get summary of research debt by domain.

  Research debt = count of open unknowns per domain.

  ## Returns
  {:ok, %{domain_id => debt_count}}
  """
  def get_research_debt_summary do
    GenServer.call(__MODULE__, :get_research_debt_summary)
  end

  @doc """
  Identify neglected domains that need additional attention.

  Neglected domains have:
  - High research debt
  - Low recent activity
  - Critical unknowns unresolved

  ## Returns
  {:ok, [domain_id]}
  """
  def identify_neglected_domains do
    GenServer.call(__MODULE__, :identify_neglected_domains)
  end

  @doc """
  Get portfolio health report for Mission Control.

  Includes per-domain statistics on discoveries, theories, laws, unknowns,
  applications, maturity, and knowledge capital.

  ## Returns
  {:ok, portfolio_health_report}
  """
  def get_portfolio_health do
    GenServer.call(__MODULE__, :get_portfolio_health)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def init(_opts) do
    state = %{
      last_analysis: nil,
      cache: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:calculate_priorities, _from, state) do
    analysis = perform_priority_analysis()

    state = %{state |
      last_analysis: analysis,
      cache: Map.put(state.cache, :priorities, analysis)
    }

    {:reply, {:ok, analysis}, state}
  end

  @impl true
  def handle_call({:suggest_next_experiment, domain_id}, _from, state) do
    suggestion = generate_experiment_suggestion(domain_id)
    {:reply, {:ok, suggestion}, state}
  end

  @impl true
  def handle_call(:allocate_resources, _from, state) do
    allocation = calculate_resource_allocation()
    {:reply, {:ok, allocation}, state}
  end

  @impl true
  def handle_call(:get_research_debt_summary, _from, state) do
    case UnknownRegistry.count_by_domain() do
      {:ok, counts} -> {:reply, {:ok, counts}, state}
      error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_call(:identify_neglected_domains, _from, state) do
    neglected = find_neglected_domains()
    {:reply, {:ok, neglected}, state}
  end

  @impl true
  def handle_call(:get_portfolio_health, _from, state) do
    health_report = generate_portfolio_health_report()
    {:reply, {:ok, health_report}, state}
  end

  # ==================== Private Analysis Functions ====================

  defp perform_priority_analysis do
    # Gather data from all registries
    {:ok, debt_summary} = UnknownRegistry.count_by_domain()
    domains = CanonicalRegistry.all()

    # Calculate priority scores for each domain
    domain_priorities = Enum.reduce(domains, %{}, fn domain, acc ->
      priority_score = calculate_domain_priority(domain, debt_summary)
      Map.put(acc, domain.id, %{
        domain: domain.id,
        priority_score: priority_score,
        research_debt: Map.get(debt_summary, domain.id, 0),
        active_programs: length(domain.active_programs),
        last_activity: domain.last_research_activity
      })
    end)

    # Sort by priority score (descending)
    sorted_priorities = domain_priorities
    |> Enum.sort_by(fn {_id, data} -> data.priority_score end, :desc)
    |> Enum.into(%{})

    # Identify neglected domains
    neglected_domains = find_neglected_domains_from_data(debt_summary, domains)

    # Generate recommended experiments
    recommended_experiments = generate_experiment_recommendations(domains, debt_summary)

    %__MODULE__{
      last_analysis_timestamp: DateTime.utc_now(),
      domain_priorities: sorted_priorities,
      recommended_experiments: recommended_experiments,
      resource_allocation: calculate_resource_allocation_from_priorities(sorted_priorities),
      neglected_domains: neglected_domains,
      research_debt_summary: debt_summary,
      analysis_metadata: %{
        total_domains: length(domains),
        total_unknowns: Enum.sum(Map.values(debt_summary)),
        analysis_method: :priority_scoring
      }
    }
  end

  defp calculate_domain_priority(domain, debt_summary) do
    debt_count = Map.get(debt_summary, domain.id, 0)

    # Base priority from research debt
    debt_priority = min(debt_count * 10, 50)

    # Bonus for critical unknowns
    {:ok, critical_unknowns} = UnknownRegistry.get_by_priority(domain.id, :critical)
    critical_bonus = length(critical_unknowns) * 15

    # Penalty for many active programs (already well-resourced)
    program_penalty = length(domain.active_programs) * 5

    # BOTTLENECK ANALYSIS - Integration with Unknown Dependency Graph
    # Find bottlenecks in this domain and estimate cascade unlock potential
    bottleneck_score = calculate_bottleneck_priority(domain.id)

    # Calculate final priority score with bottleneck weighting
    max(0, debt_priority + critical_bonus + bottleneck_score - program_penalty)
  end

  defp calculate_bottleneck_priority(domain_id) do
    # Query Unknown Dependency Graph for bottlenecks in this domain
    case UnknownDependencyGraph.find_bottlenecks() do
      {:ok, bottlenecks} ->
        # Filter bottlenecks relevant to this domain
        domain_bottlenecks = Enum.filter(bottlenecks, fn bottleneck ->
          bottleneck[:domain_id] == domain_id
        end)

        if length(domain_bottlenecks) > 0 do
          # Calculate bottleneck priority based on:
          # 1. Number of dependents (how many unknowns are blocked)
          # 2. Dependency depth (how deep the cascade goes)
          # 3. Blocking factor (severity of blockage)

          total_dependents = Enum.sum(Enum.map(domain_bottlenecks, fn b ->
            length(b[:dependent_unknown_ids] || [])
          end))

          max_depth = case Enum.max_by(domain_bottlenecks, fn b ->
            b[:dependency_depth] || 0
          end) do
            nil -> 0
            deepest -> deepest[:dependency_depth] || 0
          end

          # Bottleneck score: dependents * depth multiplier
          # More dependents and deeper cascades = higher priority
          min(total_dependents * max_depth * 5, 100)
        else
          0
        end

      _ ->
        # If dependency graph not available, fall back to zero
        0
    end
  end

  defp generate_experiment_suggestion(domain_id) do
    # Get critical unknowns for this domain
    {:ok, critical_unknowns} = UnknownRegistry.get_by_priority(domain_id, :critical)

    if length(critical_unknowns) > 0 do
      # Suggest experiment to address highest-priority unknown
      unknown = hd(critical_unknowns)

      %{
        domain: domain_id,
        suggested_action: :investigate_unknown,
        unknown_id: unknown.id,
        question: unknown.question,
        priority: unknown.priority,
        rationale: "Critical knowledge gap blocking research progress",
        estimated_impact: :high
      }
    else
      # No critical unknowns, suggest theory validation
      {:ok, theories} = TheoryRegistry.list_by_domain(domain_id)

      low_confidence_theories = Enum.filter(theories, fn t ->
        t.confidence < 0.7 and t.status == :active
      end)

      if length(low_confidence_theories) > 0 do
        theory = hd(low_confidence_theories)

        %{
          domain: domain_id,
          suggested_action: :validate_theory,
          theory_id: theory.id,
          theory_name: theory.name,
          current_confidence: theory.confidence,
          rationale: "Theory needs additional validation to increase confidence",
          estimated_impact: :medium
        }
      else
        %{
          domain: domain_id,
          suggested_action: :exploratory_research,
          rationale: "No critical gaps or low-confidence theories; explore new frontiers",
          estimated_impact: :low
        }
      end
    end
  end

  defp calculate_resource_allocation do
    {:ok, priorities} = calculate_priorities()

    calculate_resource_allocation_from_priorities(priorities.domain_priorities)
  end

  defp calculate_resource_allocation_from_priorities(priorities) do
    total_score = Enum.reduce(priorities, 0, fn {_id, data}, acc ->
      acc + data.priority_score
    end)

    if total_score == 0 do
      %{}
    else
      Enum.reduce(priorities, %{}, fn {domain_id, data}, acc ->
        allocation_percentage = Float.round((data.priority_score / total_score) * 100, 2)
        Map.put(acc, domain_id, %{
          percentage: allocation_percentage,
          priority_score: data.priority_score,
          research_debt: data.research_debt
        })
      end)
    end
  end

  defp find_neglected_domains do
    domains = CanonicalRegistry.all()
    {:ok, debt_summary} = UnknownRegistry.count_by_domain()

    find_neglected_domains_from_data(debt_summary, domains)
  end

  defp find_neglected_domains_from_data(debt_summary, domains) do
    Enum.filter(domains, fn domain ->
      debt_count = Map.get(debt_summary, domain.id, 0)
      has_critical_unknowns = has_critical_unknowns?(domain.id)
      low_activity = low_recent_activity?(domain)

      # Neglected if: high debt OR critical unknowns AND low activity
      (debt_count > 10 or has_critical_unknowns) and low_activity
    end)
    |> Enum.map(& &1.id)
  end

  defp has_critical_unknowns?(domain_id) do
    case UnknownRegistry.get_by_priority(domain_id, :critical) do
      {:ok, unknowns} -> length(unknowns) > 0
      _ -> false
    end
  end

  defp low_recent_activity?(domain) do
    if domain.last_research_activity do
      days_since = DateTime.diff(DateTime.utc_now(), domain.last_research_activity, :day)
      days_since > 30  # No activity in last 30 days
    else
      true  # Never had activity
    end
  end

  defp generate_experiment_recommendations(domains, debt_summary) do
    Enum.flat_map(domains, fn domain ->
      debt_count = Map.get(debt_summary, domain.id, 0)

      if debt_count > 5 do
        [
          %{
            domain: domain.id,
            recommendation: :reduce_research_debt,
            current_debt: debt_count,
            suggested_focus: "Address #{debt_count} open unknowns"
          }
        ]
      else
        []
      end
    end)
  end

  defp generate_portfolio_health_report do
    domains = CanonicalRegistry.all()

    domain_reports = Enum.map(domains, fn domain ->
      knowledge_capital = KnowledgeCapitalBoundary.get(domain.id)
      {:ok, theories} = TheoryRegistry.list_by_domain(domain.id)
      {:ok, discoveries} = DiscoveryRegistry.list_by_domain(domain.id)
      {:ok, open_unknowns} = UnknownRegistry.list_open_by_domain(domain.id)

      validated_theories = Enum.count(theories, fn t -> t.confidence >= 0.9 end)
      operationally_validated = Enum.count(discoveries, fn d ->
        d.validation_status == :operationally_validated
      end)

      %{
        domain: domain.id,
        domain_name: domain.name,
        knowledge_capital: knowledge_capital,
        statistics: %{
          total_theories: length(theories),
          validated_theories: validated_theories,
          total_discoveries: length(discoveries),
          operationally_validated_discoveries: operationally_validated,
          open_unknowns: length(open_unknowns),
          active_programs: length(domain.active_programs),
          research_debt: length(open_unknowns)
        },
        maturity_assessment: assess_domain_maturity(theories, discoveries, open_unknowns),
        last_activity: domain.last_research_activity
      }
    end)

    %{
      report_timestamp: DateTime.utc_now(),
      total_domains: length(domains),
      domain_reports: domain_reports,
      overall_health: calculate_overall_health(domain_reports)
    }
  end

  defp assess_domain_maturity(theories, discoveries, unknowns) do
    theory_maturity = if length(theories) > 0 do
      validated_ratio = Enum.count(theories, fn t -> t.confidence >= 0.9 end) / length(theories)
      if validated_ratio > 0.7, do: :mature, else: :developing
    else
      :emerging
    end

    discovery_maturity = if length(discoveries) > 0 do
      validated_count = Enum.count(discoveries, fn d ->
        d.validation_status == :operationally_validated
      end)
      if validated_count > 5, do: :mature, else: :developing
    else
      :emerging
    end

    unknown_severity = if length(unknowns) > 20 do
      :high_debt
    else
      :manageable
    end

    %{
      theory_maturity: theory_maturity,
      discovery_maturity: discovery_maturity,
      unknown_severity: unknown_severity
    }
  end

  defp calculate_overall_health(domain_reports) do
    total_unknowns = Enum.sum(Enum.map(domain_reports, fn r ->
      r.statistics.open_unknowns
    end))

    total_discoveries = Enum.sum(Enum.map(domain_reports, fn r ->
      r.statistics.total_discoveries
    end))

    mature_domains = Enum.count(domain_reports, fn r ->
      r.maturity_assessment.theory_maturity == :mature
    end)

    %{
      total_unknowns: total_unknowns,
      total_discoveries: total_discoveries,
      mature_domains: mature_domains,
      health_score: Float.round((total_discoveries / max(total_unknowns + total_discoveries, 1)) * 100, 2)
    }
  end
end
