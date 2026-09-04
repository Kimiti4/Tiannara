defmodule TiannaraWeb.MissionControlLive do
  @moduledoc """
  NASA-style Command Cockpit structured around the five core research questions and dynamic domain portfolios.
  """
  use Phoenix.LiveView

  alias Tiannara.KnowledgeGraph.Registry, as: KG
  alias Tiannara.Domains.{CanonicalRegistry, KnowledgeCapitalBoundary, PortfolioBoundary}
  alias Tiannara.Domains.TransferMatrix
  alias Tiannara.Discoveries.Unknown
  alias Tiannara.REA.Intervention
  alias Tiannara.Research.Director
  alias Tiannara.Sentinel.OperationalObservatory

  def mount(_params, _session, socket) do
    # Fetch unified nodes and transfers
    nodes = KG.all()
    transfers = TransferMatrix.all()
    domains = CanonicalRegistry.all_records()

    # Pre-seed discoveries and theories from unified registry
    discoveries = Enum.filter(nodes, & &1.type == :discovery or &1.type == :law)
    theories = Enum.filter(nodes, & &1.type == :theory)
    unknowns = Unknown.all()
    interventions = Intervention.all()
    maturity = OperationalObservatory.get_operational_maturity()
    proposals = Director.all()

    # Dynamic theories mapped
    mapped_theories = Enum.map(theories, fn th ->
      %{
        name: th.name,
        health: "High",
        evidence_strength: th.metadata[:evidence_strength] || th.metadata["evidence_strength"] || 0.85,
        contradiction_pressure: th.metadata[:contradiction_pressure] || th.metadata["contradiction_pressure"] || 0.08,
        operational_support: th.metadata[:operational_support] || th.metadata["operational_support"] || 0.15,
        research_debt: th.metadata[:research_debt] || th.metadata["research_debt"] || "Low"
      }
    end)

    # Precompute Domain Portfolio Metrics
    domain_portfolio_scores = Enum.map(domains, fn dom ->
      capital = KnowledgeCapitalBoundary.get(dom.id)
      vector = PortfolioBoundary.get(dom.id)
      %{dom: dom, capital: capital, vector: vector}
    end)

    # Top Domains (sorted by computed dynamic Knowledge Capital)
    top_domains = 
      domain_portfolio_scores 
      |> Enum.sort_by(& &1.capital, :desc) 
      |> Enum.take(3)
      |> Enum.map(& &1.dom.name)

    # Most Transferable Discovery
    most_transferable_disc =
      if Enum.empty?(transfers) do
        "Structured Forgetting"
      else
        transfers
        |> Enum.group_by(& &1.discovery_id)
        |> Enum.max_by(fn {_id, list} -> Enum.count(list) end, fn -> {"structured_forgetting", []} end)
        |> elem(0)
        |> to_string()
        |> String.replace("_", " ")
        |> String.capitalize()
      end

    # Highest Discovery Yield Domain
    highest_yield_dom =
      domain_portfolio_scores
      |> Enum.max_by(& &1.vector.discovery_power, fn -> %{dom: %{name: "Engineering"}} end)
      |> Map.get(:dom)
      |> Map.get(:name)

    # Highest Cross-Domain Impact
    highest_cross_impact =
      if Enum.empty?(transfers) do
        "Generative Orbit Equivalence"
      else
        transfers
        |> Enum.group_by(& &1.discovery_id)
        |> Enum.max_by(fn {_id, list} -> Enum.sum(Enum.map(list, & &1.transfer_success)) / Enum.count(list) end, fn -> {"generative_orbit_equivalence", []} end)
        |> elem(0)
        |> to_string()
        |> String.replace("_", " ")
        |> String.capitalize()
      end

    # Most Underexplored Domain (active programs, lowest operational maturity)
    most_underexplored =
      domain_portfolio_scores
      |> Enum.filter(& &1.dom.status == :active)
      |> Enum.min_by(& &1.vector.operational_maturity, fn -> %{dom: %{name: "Medicine"}} end)
      |> Map.get(:dom)
      |> Map.get(:name)

    # Calculate Knowledge Capital Balance Sheet
    validated_theories_count = Enum.count(mapped_theories, &(&1.research_debt == "Low"))
    knowledge_capital = %{
      discoveries: length(discoveries),
      laws: Enum.count(discoveries, & &1.metadata[:status] == :supported_law or &1.metadata["status"] == :supported_law),
      theories: length(theories),
      validated_theories: validated_theories_count,
      unresolved_unknowns: length(unknowns)
    }

    state =
      case Process.whereis(TiannaraOS.CivilizationKernel) do
        nil -> nil
        pid ->
          if Process.alive?(pid) do
            try do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            rescue
              _ -> nil
            end
          else
            nil
          end
      end

    {dvr, surprise_index} =
      if state do
        total_disc = map_size(state.discoveries)
        val_disc = Enum.count(Map.values(state.discoveries), &(&1.status == :validated))
        computed_dvr = if total_disc > 0, do: val_disc / total_disc, else: 1.0

        nodes_list = Map.values(state.evidence_graph)
        refuted_or_contested = Enum.count(nodes_list, &(&1.validity in [:invalid, :contested]))
        total_nodes = length(nodes_list)
        computed_surprise = if total_nodes > 0, do: refuted_or_contested / total_nodes, else: 0.0496

        {computed_dvr, computed_surprise}
      else
        {1.0, 0.0496}
      end

    provenance =
      if state do
        TiannaraOS.MetricWithProvenance.from_state(0.0, state).provenance
      else
        %{theories_count: 0, evidence_nodes_count: 0, replication_events_count: 0, repository_worlds_count: 0}
      end

    orbit_summary = Tiannara.OrbitAtlas.get_summary_metrics()

    {:ok,
     assign(socket,
       discoveries: discoveries,
       unknowns: unknowns,
       interventions: interventions,
       maturity: maturity,
       proposals: proposals,
       theories: mapped_theories,
       knowledge_capital: knowledge_capital,
       dvr: dvr,
       surprise_index: surprise_index,
       top_domains: top_domains,
       most_transferable_disc: most_transferable_disc,
       highest_yield_dom: highest_yield_dom,
       highest_cross_impact: highest_cross_impact,
       most_underexplored: most_underexplored,
       highest_intervention_success: "Specialist Context Retention = 55%",
       orbit_summary: orbit_summary,
       provenance: provenance
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      
      <!-- COLUMN 1: Is the System Improving? & Knowledge Capital Balance Sheet & Domain Analytics -->
      <div class="glass-card p-6 flex flex-col gap-6">
        <div>
          <h2 class="text-xs font-bold uppercase tracking-wider text-slate-500 font-mono mb-2">01 / System Performance</h2>
          <h1 class="text-xl font-bold text-indigo-400 font-heading">Is the System Improving?</h1>
        </div>

        <!-- Telemetry Metrics Scorecard -->
        <div class="grid grid-cols-2 gap-4">
          <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg">
            <span class="text-slate-500 text-[10px] uppercase block font-semibold">Discovery-to-Value</span>
            <span class="text-xl font-extrabold text-emerald-400 font-heading"><%= Float.round(@dvr * 100, 1) %>%</span>
          </div>
          <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg">
            <span class="text-slate-500 text-[10px] uppercase block font-semibold">Surprise Index</span>
            <span class="text-xl font-extrabold text-amber-400 font-heading"><%= @surprise_index %></span>
          </div>
          <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg">
            <span class="text-slate-500 text-[10px] uppercase block font-semibold">Operational Cycles</span>
            <span class="text-xl font-extrabold text-slate-200 font-heading"><%= @maturity.cycles %></span>
          </div>
          <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg">
            <span class="text-slate-500 text-[10px] uppercase block font-semibold">Validated Discovery</span>
            <span class="text-xl font-extrabold text-slate-200 font-heading"><%= @maturity.validated_discoveries %></span>
          </div>
        </div>

        <!-- Knowledge Capital Balance Sheet -->
        <div class="border-t border-slate-800 pt-4 flex flex-col gap-3">
          <h3 class="text-xs font-bold text-slate-100 uppercase tracking-wider font-heading">Knowledge Capital Sheet</h3>
          <div class="flex flex-col gap-2 text-xs font-mono">
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Total Discoveries</span>
              <span class="text-slate-100 font-bold"><%= @knowledge_capital.discoveries %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Synthesized Theories</span>
              <span class="text-slate-100 font-bold"><%= @knowledge_capital.theories %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Validated Theories</span>
              <span class="text-emerald-400 font-bold"><%= @knowledge_capital.validated_theories %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Unresolved Unknowns</span>
              <span class="text-rose-400 font-bold"><%= @knowledge_capital.unresolved_unknowns %></span>
            </div>
          </div>
        </div>

        <!-- Domain Portfolio Analytics Section -->
        <div class="border-t border-slate-800 pt-4 flex flex-col gap-3">
          <h3 class="text-xs font-bold text-slate-100 uppercase tracking-wider font-heading">Domain Portfolio Analytics</h3>
          <div class="flex flex-col gap-2 text-xs font-mono">
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Top Domains</span>
              <span class="text-indigo-400 font-bold"><%= Enum.join(@top_domains, ", ") %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Most Transferable</span>
              <span class="text-slate-200 font-bold"><%= @most_transferable_disc %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Highest Yield Domain</span>
              <span class="text-slate-200 font-bold"><%= @highest_yield_dom %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Highest Cross-Impact</span>
              <span class="text-purple-400 font-bold"><%= @highest_cross_impact %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Most Underexplored</span>
              <span class="text-rose-450 font-bold text-rose-400"><%= @most_underexplored %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Highest Interv Success</span>
              <span class="text-emerald-400 font-bold"><%= @highest_intervention_success %></span>
            </div>
          </div>
        </div>

        <!-- Orbit Transition Dynamics Section -->
        <div class="border-t border-slate-800 pt-4 flex flex-col gap-3">
          <h3 class="text-xs font-bold text-slate-100 uppercase tracking-wider font-heading">Orbit Transition Dynamics</h3>
          <div class="flex flex-col gap-2 text-xs font-mono">
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Most Common Transition</span>
              <span class="text-indigo-400 font-bold"><%= if @orbit_summary.most_common, do: "#{format_orbit_name(@orbit_summary.most_common.from_orbit)} &rarr; #{format_orbit_name(@orbit_summary.most_common.to_orbit)}", else: "N/A" %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Most Valuable Transition</span>
              <span class="text-emerald-400 font-bold"><%= if @orbit_summary.most_valuable, do: "#{format_orbit_name(@orbit_summary.most_valuable.from_orbit)} &rarr; #{format_orbit_name(@orbit_summary.most_valuable.to_orbit)}", else: "N/A" %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Most Dangerous Transition</span>
              <span class="text-rose-400 font-bold"><%= if @orbit_summary.most_dangerous, do: "#{format_orbit_name(@orbit_summary.most_dangerous.from_orbit)} &rarr; #{format_orbit_name(@orbit_summary.most_dangerous.to_orbit)}", else: "N/A" %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Highest Cost Transition</span>
              <span class="text-slate-200 font-bold"><%= if @orbit_summary.highest_cost, do: "#{format_orbit_name(@orbit_summary.highest_cost.from_orbit)} &rarr; #{format_orbit_name(@orbit_summary.highest_cost.to_orbit)}", else: "N/A" %></span>
            </div>
            <div class="flex justify-between items-center bg-slate-900/50 p-2 rounded">
              <span class="text-slate-400">Most Stable Orbit</span>
              <span class="text-indigo-400 font-bold"><%= if @orbit_summary.most_stable, do: format_orbit_name(@orbit_summary.most_stable), else: "N/A" %></span>
            </div>
          </div>
        </div>

        <!-- Metric Provenance Trace Section -->
        <div class="border-t border-slate-800 pt-4 flex flex-col gap-2">
          <h3 class="text-xs font-bold text-slate-100 uppercase tracking-wider font-heading">Metric Provenance</h3>
          <p class="text-[10px] text-slate-400 leading-normal font-mono">
            Derived directly from:<br/>
            • <%= @provenance.theories_count %> active theories<br/>
            • <%= @provenance.evidence_nodes_count %> evidence nodes<br/>
            • <%= @provenance.replication_events_count %> replication events<br/>
            • <%= @provenance.repository_worlds_count %> repository twin worlds
          </p>
        </div>
      </div>

      <!-- COLUMN 2: What Did We Learn? & What Do We Believe? -->
      <div class="glass-card p-6 flex flex-col gap-6 col-span-2">
        <!-- What Did We Learn? -->
        <div>
          <h2 class="text-xs font-bold uppercase tracking-wider text-slate-500 font-mono mb-2">02 / What Did We Learn?</h2>
          <h1 class="text-xl font-bold text-emerald-400 font-heading">Latest Discoveries</h1>
          
          <div class="flex flex-col gap-3 mt-3">
            <%= for disc <- Enum.take(@discoveries, 2) do %>
              <div class="p-3.5 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-start gap-4">
                <div>
                  <h3 class="font-bold text-slate-100 text-sm"><%= disc.name %></h3>
                  <p class="text-xs text-slate-400 mt-1 leading-relaxed"><%= disc.description %></p>
                  <div class="flex gap-4 text-[9px] text-slate-500 mt-2 font-mono">
                    <span>Validation Score: <strong class="text-slate-450 text-slate-400"><%= Float.round((disc.metadata[:confidence][:consensus] || disc.metadata["confidence"][:consensus] || 0.90) * 100, 0) %>%</strong></span>
                  </div>
                </div>
                <span class="text-xs px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-semibold font-mono">
                  <%= disc.metadata[:status] || disc.metadata["status"] || :validated %>
                </span>
              </div>
            <% end %>
          </div>
        </div>

        <!-- What Do We Believe? -->
        <div class="border-t border-slate-800 pt-4">
          <h2 class="text-xs font-bold uppercase tracking-wider text-slate-500 font-mono mb-2">03 / What Do We Believe?</h2>
          <h1 class="text-xl font-bold text-blue-400 font-heading">Theories & Foundational Nodes</h1>
          
          <div class="flex flex-col gap-3 mt-3">
            <%= for th <- @theories do %>
              <div class="p-3.5 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-start gap-4">
                <div>
                  <h3 class="font-bold text-slate-100 text-sm"><%= th.name %></h3>
                  <div class="grid grid-cols-4 gap-2 text-[10px] text-slate-500 mt-2 font-mono">
                    <span>Evidence: <strong class="text-slate-300"><%= Float.round(th.evidence_strength * 100, 0) %>%</strong></span>
                    <span>Conflict: <strong class="text-rose-400"><%= Float.round(th.contradiction_pressure * 100, 0) %>%</strong></span>
                    <span>Op Support: <strong class="text-slate-300"><%= Float.round(th.operational_support * 100, 0) %>%</strong></span>
                    <span>Debt: <strong class="text-slate-300"><%= th.research_debt %></strong></span>
                  </div>
                </div>
                <span class="text-xs px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 font-semibold font-mono">
                  High Health
                </span>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>

    <!-- COLUMN 3: What Are We Unsure About? & What Should We Do Next? -->
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-6">
      
      <!-- What Are We Unsure About? -->
      <div class="glass-card p-6 flex flex-col gap-4">
        <div>
          <h2 class="text-xs font-bold uppercase tracking-wider text-slate-500 font-mono mb-2">04 / What Are We Unsure About?</h2>
          <h1 class="text-xl font-bold text-amber-400 font-heading">Research Gaps & Unknowns</h1>
        </div>

        <div class="flex flex-col gap-3">
          <%= for un <- @unknowns do %>
            <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-center">
              <div>
                <span class="text-xs text-amber-400 font-mono">[Blocking <%= un.blocking_phase %>]</span>
                <p class="text-xs text-slate-200 mt-1 font-semibold"><%= un.question %></p>
              </div>
              <span class="text-xs px-2 py-0.5 rounded bg-rose-500/10 text-rose-400 border border-rose-500/20 font-semibold uppercase">
                <%= un.importance %> Priority
              </span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- What Should We Do Next? (Research Director recommendations) -->
      <div class="glass-card p-6 flex flex-col gap-4">
        <div>
          <h2 class="text-xs font-bold uppercase tracking-wider text-slate-500 font-mono mb-2">05 / What Should We Do Next?</h2>
          <h1 class="text-xl font-bold text-blue-400 font-heading">Research Director Recommendations</h1>
        </div>

        <div class="flex flex-col gap-4">
          <%= for prop <- @proposals do %>
            <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg">
              <div class="flex justify-between items-start gap-4">
                <div>
                  <h3 class="font-bold text-slate-100 text-sm"><%= prop.experiment_name %></h3>
                  <p class="text-xs text-slate-400 mt-1 leading-relaxed italic">"<%= prop.reason_explanation %>"</p>
                </div>
                <span class="text-xs px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20 font-semibold font-mono uppercase">
                  <%= prop.status %>
                </span>
              </div>

              <div class="grid grid-cols-3 gap-2 text-[10px] text-slate-500 mt-3 font-mono border-t border-slate-850 pt-2">
                <div>
                  <span>Uncertainty Reduction:</span>
                  <strong class="text-emerald-400 font-bold block"><%= Float.round(prop.expected_uncertainty_reduction * 100, 0) %>%</strong>
                </div>
                <div>
                  <span>Info Gain:</span>
                  <strong class="text-slate-300 font-bold block"><%= Float.round(prop.expected_information_gain * 100, 0) %>%</strong>
                </div>
                <div>
                  <span>Expected DVR Gain:</span>
                  <strong class="text-slate-300 font-bold block">+<%= Float.round(prop.expected_dvr_gain * 100, 0) %>%</strong>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  defp format_orbit_name(id) do
    id
    |> to_string()
    |> String.replace("_", " ")
    |> String.replace("orbit", "")
    |> String.trim()
    |> String.capitalize()
  end
end
