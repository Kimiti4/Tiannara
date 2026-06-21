defmodule TiannaraWeb.PortfolioDynamicsLive do
  @moduledoc """
  Interactive Theory Portfolio Dynamics & Governance Dashboard.
  Provides controls for governance modes, parameter sweeps, shock injections, and risk meters.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.TheorySelection
  alias Tiannara.REA.MetaTheoryExtractor
  alias Tiannara.REA.MetaTheoryPredictor
  alias Tiannara.REA.DomainCrucible
  alias Tiannara.REA.TheoryPortfolio
  alias Tiannara.REA.PortfolioRebalancer
  alias Tiannara.REA.PortfolioRiskAnalyzer

  def mount(_params, _session, socket) do
    theories = TheorySelection.load_theories()
    domains = DomainCrucible.all_domains()
    selected_domain = hd(domains)

    context = %{volatility: 0.15, complexity: 0.10, adversariality: 0.05}
    tensor = MetaTheoryExtractor.extract(theories)

    # Initial portfolio setup
    initial_weights = Map.new(theories, & {&1.theory_id, 1.0 / length(theories)})
    initial_portfolio = %TheoryPortfolio{
      weights: initial_weights,
      yields: initial_weights,
      tracking_error: 0.0,
      hhi: 0.25,
      capture_index: 0.25,
      correlation_risk: 0.0,
      extinction_risk: 0.10,
      dependency_risk: 0.0,
      recovery_capacity: 1.0,
      cascading_failure_risk: 0.0,
      adaptation_velocity: 0.0,
      security_score: 0.90,
      history: [],
      governance_history: [],
      current_mode: :balanced
    }

    # First rebalance to populate exact metrics
    portfolio = PortfolioRebalancer.rebalance(initial_portfolio, tensor, context, selected_domain, :balanced, 0.0)

    {:ok,
     assign(socket,
       portfolio: portfolio,
       tensor: tensor,
       domains: domains,
       selected_domain: selected_domain,
       volatility: 0.15,
       complexity: 0.10,
       adversariality: 0.05,
       mode: :balanced,
       shock_details: nil,
       message: nil,
       provenance: get_provenance()
     )}
  end

  def handle_event("update_parameters", %{"volatility" => vol_str, "complexity" => comp_str, "adversariality" => adv_str, "domain" => dom_str}, socket) do
    volatility = String.to_float(vol_str)
    complexity = String.to_float(comp_str)
    adversariality = String.to_float(adv_str)
    selected_domain = String.to_existing_atom(dom_str)

    context = %{volatility: volatility, complexity: complexity, adversariality: adversariality}
    portfolio = PortfolioRebalancer.rebalance(
      socket.assigns.portfolio,
      socket.assigns.tensor,
      context,
      selected_domain,
      socket.assigns.mode,
      0.05
    )

    {:noreply,
     assign(socket,
       volatility: volatility,
       complexity: complexity,
       adversariality: adversariality,
       selected_domain: selected_domain,
       portfolio: portfolio,
       message: "Sweep coordinates updated. Dynamic rebalancing applied.",
       provenance: get_provenance()
     )}
  end

  def handle_event("change_mode", %{"mode" => mode_str}, socket) do
    mode = String.to_existing_atom(mode_str)
    context = %{
      volatility: socket.assigns.volatility,
      complexity: socket.assigns.complexity,
      adversariality: socket.assigns.adversariality
    }

    portfolio = PortfolioRebalancer.rebalance(
      socket.assigns.portfolio,
      socket.assigns.tensor,
      context,
      socket.assigns.selected_domain,
      mode,
      0.0  # Force update on mode change
    )

    {:noreply,
     assign(socket,
       mode: mode,
       portfolio: portfolio,
       message: "Governance Mode changed to #{String.capitalize(mode_str)}.",
       provenance: get_provenance()
     )}
  end

  def handle_event("trigger_shock", _params, socket) do
    context = %{
      volatility: socket.assigns.volatility,
      complexity: socket.assigns.complexity,
      adversariality: socket.assigns.adversariality
    }

    # Calculate pre-shock yield
    theories = TheorySelection.load_theories()
    theory_map = Map.new(theories, & {&1.theory_id, &1})
    pre_yield =
      Enum.reduce(socket.assigns.portfolio.weights, 0.0, fn {tid, w}, acc ->
        t = Map.get(theory_map, tid)
        fit = if t, do: TheorySelection.calculate_fitness(t, context.volatility, context.complexity), else: 0.5
        acc + w * fit
      end)

    # Apply severe coordinate shock
    shock_context = %{
      volatility: min(1.0, context.volatility + 0.35),
      complexity: min(1.0, context.complexity + 0.35),
      adversariality: min(1.0, context.adversariality + 0.40)
    }

    # Calculate post-shock yield under emergency mode rebalancing
    emergency_portfolio = PortfolioRebalancer.rebalance(
      socket.assigns.portfolio,
      socket.assigns.tensor,
      shock_context,
      socket.assigns.selected_domain,
      :emergency,
      0.0
    )

    post_yield =
      Enum.reduce(emergency_portfolio.weights, 0.0, fn {tid, w}, acc ->
        t = Map.get(theory_map, tid)
        fit = if t, do: TheorySelection.calculate_fitness(t, shock_context.volatility, shock_context.complexity), else: 0.5
        acc + w * fit
      end)

    details = %{
      pre_shock_yield: Float.round(pre_yield, 4),
      post_shock_yield: Float.round(post_yield, 4),
      recovery_capacity: emergency_portfolio.recovery_capacity,
      shock_volatility: shock_context.volatility,
      shock_complexity: shock_context.complexity,
      shock_adversariality: shock_context.adversariality
    }

    {:noreply,
     assign(socket,
       portfolio: emergency_portfolio,
       mode: :emergency,
       shock_details: details,
       message: "Epistemic Shock Injected! Switched to Emergency Governance Mode.",
       provenance: get_provenance()
     )}
  end

  def handle_event("clear_shock", _params, socket) do
    context = %{
      volatility: socket.assigns.volatility,
      complexity: socket.assigns.complexity,
      adversariality: socket.assigns.adversariality
    }

    portfolio = PortfolioRebalancer.rebalance(
      socket.assigns.portfolio,
      socket.assigns.tensor,
      context,
      socket.assigns.selected_domain,
      :balanced,
      0.0
    )

    {:noreply,
     assign(socket,
       portfolio: portfolio,
       mode: :balanced,
       shock_details: nil,
       message: "Resilience restoration completed. Restored to Balanced Mode.",
       provenance: get_provenance()
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Phase 11.18</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Theory Governance Stack</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Theory Portfolio Dynamics</h1>
          <p class="text-sm text-slate-400 mt-1">Multi-theory allocation, dynamic risk hedging, dependency graph tracking, and epistemic resilience rebalancing.</p>
        </div>
        
        <div class="flex gap-2">
          <%= if @shock_details do %>
            <button phx-click="clear_shock" class="px-4 py-2 bg-emerald-500 text-slate-950 font-bold hover:bg-emerald-600 rounded-lg text-xs font-mono transition-all">
              Restore Normal Mode
            </button>
          <% else %>
            <button phx-click="trigger_shock" class="px-4 py-2 bg-rose-500/10 border border-rose-500/20 hover:bg-rose-500/20 text-rose-400 rounded-lg text-xs font-semibold font-mono transition-all">
              Inject Epistemic Shock
            </button>
          <% end %>
        </div>
      </div>

      <%= if @message do %>
        <div class="p-3 bg-indigo-500/10 border border-indigo-500/20 rounded-lg text-xs font-mono text-indigo-400 animate-pulse">
          <%= @message %>
        </div>
      <% end %>

      <!-- Shock Alert Details Panel -->
      <%= if @shock_details do %>
        <div class="p-6 bg-rose-500/5 border border-rose-500/20 rounded-xl grid grid-cols-1 md:grid-cols-4 gap-6 font-mono text-xs text-slate-300">
          <div class="md:col-span-4 flex items-center gap-2 text-rose-400 font-bold text-sm">
            <span class="w-2 h-2 bg-rose-500 rounded-full animate-ping"></span>
            ACTIVE COGNITIVE IMMUNE EVENT: ENVIRONMENTAL DISTORTION INJECTED
          </div>
          <div>
            <span class="text-slate-500 uppercase text-[10px] block">Pre-Shock Yield</span>
            <span class="text-slate-200 text-sm font-bold"><%= @shock_details.pre_shock_yield %></span>
          </div>
          <div>
            <span class="text-slate-500 uppercase text-[10px] block">Post-Shock Yield</span>
            <span class="text-slate-200 text-sm font-bold"><%= @shock_details.post_shock_yield %></span>
          </div>
          <div>
            <span class="text-slate-500 uppercase text-[10px] block">Restoration Speed (PRC)</span>
            <span class="text-emerald-400 text-sm font-bold"><%= Float.round(@shock_details.recovery_capacity * 100, 2) %>%</span>
          </div>
          <div>
            <span class="text-slate-500 uppercase text-[10px] block">Shock Vectors</span>
            <span class="text-rose-400 text-[10px]">V: <%= @shock_details.shock_volatility %> | C: <%= @shock_details.shock_complexity %> | A: <%= @shock_details.shock_adversariality %></span>
          </div>
        </div>
      <% end %>

      <!-- Governance Mode & Param Selectors -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Parameters Sweep Sliders -->
        <div class="glass-card p-6 lg:col-span-2">
          <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Context Parameter Sweeper
          </h2>
          <form phx-change="update_parameters" class="grid grid-cols-1 md:grid-cols-4 gap-6 font-mono text-xs text-slate-300">
            <div>
              <label class="block mb-2 text-slate-400 uppercase text-[10px]">Volatility</label>
              <input type="range" name="volatility" min="0.0" max="1.0" step="0.05" value={@volatility} class="w-full accent-indigo-500" />
              <output class="text-indigo-400 block mt-1 text-right"><%= @volatility %></output>
            </div>

            <div>
              <label class="block mb-2 text-slate-400 uppercase text-[10px]">Complexity</label>
              <input type="range" name="complexity" min="0.0" max="1.0" step="0.05" value={@complexity} class="w-full accent-indigo-500" />
              <output class="text-indigo-400 block mt-1 text-right"><%= @complexity %></output>
            </div>

            <div>
              <label class="block mb-2 text-slate-400 uppercase text-[10px]">Adversariality</label>
              <input type="range" name="adversariality" min="0.0" max="1.0" step="0.05" value={@adversariality} class="w-full accent-indigo-500" />
              <output class="text-indigo-400 block mt-1 text-right"><%= @adversariality %></output>
            </div>

            <div>
              <label class="block mb-2 text-slate-400 uppercase text-[10px]">Target Laboratory Domain</label>
              <select name="domain" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-indigo-500">
                <%= for d <- @domains do %>
                  <option value={to_string(d)} selected={d == @selected_domain}>
                    <%= to_string(d) |> String.capitalize() %>
                  </option>
                <% end %>
              </select>
            </div>
          </form>
        </div>

        <!-- Governance Mode Buttons -->
        <div class="glass-card p-6 lg:col-span-1">
          <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Civilizational Mode
          </h2>
          <div class="grid grid-cols-2 gap-2 font-mono text-xs">
            <button phx-click="change_mode" phx-value-mode="exploration" class={"py-2.5 rounded-lg border text-center font-bold transition-all " <> (if @mode == :exploration, do: "bg-indigo-500/20 text-indigo-400 border-indigo-500/40", else: "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700")}>
              EXPLORATION
            </button>
            <button phx-click="change_mode" phx-value-mode="exploitation" class={"py-2.5 rounded-lg border text-center font-bold transition-all " <> (if @mode == :exploitation, do: "bg-indigo-500/20 text-indigo-400 border-indigo-500/40", else: "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700")}>
              EXPLOITATION
            </button>
            <button phx-click="change_mode" phx-value-mode="balanced" class={"py-2.5 rounded-lg border text-center font-bold transition-all " <> (if @mode == :balanced, do: "bg-indigo-500/20 text-indigo-400 border-indigo-500/40", else: "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700")}>
              BALANCED
            </button>
            <button phx-click="change_mode" phx-value-mode="emergency" class={"py-2.5 rounded-lg border text-center font-bold transition-all " <> (if @mode == :emergency, do: "bg-rose-500/20 text-rose-400 border-rose-500/40", else: "bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700")}>
              EMERGENCY
            </button>
          </div>
        </div>

      </div>

      <!-- Main Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Left: Allocations & History -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Theory Portfolio Weights -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Active Theory Resource Allocations
            </h2>
            <div class="flex flex-col gap-4 font-mono text-xs text-slate-300">
              <%= for {tid, weight} <- @portfolio.weights do %>
                <div class="flex flex-col gap-1.5 border-b border-slate-800/20 pb-3 last:border-0 last:pb-0">
                  <div class="flex justify-between items-center text-[11px]">
                    <span class="font-bold text-slate-200"><%= tid %></span>
                    <span class="text-indigo-400 font-bold"><%= Float.round(weight * 100, 2) %>%</span>
                  </div>
                  <div class="w-full bg-slate-950 h-2 rounded-full overflow-hidden">
                    <div class="h-full bg-indigo-500 transition-all duration-300" style={"width: " <> to_string(round(weight * 100)) <> "%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Governance History Timeline -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-purple-500"></span> Governance History & Institutional Memory
            </h2>
            <div class="overflow-y-auto max-h-60 flex flex-col gap-3 font-mono text-xs text-slate-400">
              <%= for ep <- @portfolio.governance_history do %>
                <div class="p-3 bg-slate-900/60 border border-slate-800/40 rounded-lg flex flex-col gap-1">
                  <div class="flex justify-between items-center">
                    <span class={"font-bold uppercase text-[10px] " <> (if ep.mode == :emergency, do: "text-rose-400", else: "text-indigo-400")}>
                      <%= ep.mode %> mode
                    </span>
                    <span class="text-[9px] text-slate-500"><%= ep.timestamp %></span>
                  </div>
                  <p class="text-slate-300 text-[11px]"><%= ep.notes %></p>
                </div>
              <% end %>
              <%= if @portfolio.governance_history == [] do %>
                <div class="py-6 text-center text-slate-500">No mode transitions recorded. Toggle governance modes to generate history logs.</div>
              <% end %>
            </div>
          </div>

        </div>

        <!-- Right: Risk & Security Monitoring -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Constitutional Security score -->
          <div class="glass-card p-6 bg-indigo-500/5 border-indigo-500/10 flex flex-col items-center justify-center text-center">
            <span class="text-[10px] font-mono text-slate-500 uppercase">Constitutional Security Score</span>
            <div class="text-4xl font-black text-indigo-400 font-heading mt-2">
              <%= @portfolio.security_score %>
            </div>
            <p class="text-[10px] text-slate-400 mt-2 max-w-xs">Product value reflecting overall robustness, low correlation, decentralized structural risk, and high recovery capacity.</p>
          </div>

          <!-- Metric Provenance Trace Section -->
          <div class="glass-card p-4 flex flex-col gap-2">
            <h3 class="text-xs font-bold text-slate-350 uppercase tracking-wider font-heading text-slate-200">Metric Provenance</h3>
            <p class="text-[10px] text-slate-400 leading-normal font-mono text-left">
              Grounded directly in:<br/>
              • <%= @provenance.theories_count %> active theories<br/>
              • <%= @provenance.evidence_nodes_count %> evidence nodes<br/>
              • <%= @provenance.replication_events_count %> replication events<br/>
              • <%= @provenance.repository_worlds_count %> repository twin worlds
            </p>
          </div>

          <!-- Performance & Risk Indexes -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-rose-500"></span> Governance Risk Metrics
            </h2>
            <div class="flex flex-col gap-4 font-mono text-xs">
              <!-- HHI Concentration -->
              <div class="flex justify-between items-center border-b border-slate-800 pb-2.5">
                <div>
                  <span class="text-slate-300 block font-semibold">HHI Concentration</span>
                  <span class="text-[9px] text-slate-500">Concentration density (lower is better)</span>
                </div>
                <span class="text-slate-200 font-bold"><%= @portfolio.hhi %></span>
              </div>

              <!-- Capture Index (Monoculture) -->
              <div class="flex justify-between items-center border-b border-slate-800 pb-2.5">
                <div>
                  <span class="text-slate-300 block font-semibold">Capture / Monoculture Index</span>
                  <span class="text-[9px] text-slate-500">Max single allocation share</span>
                </div>
                <span class={"font-bold " <> (if @portfolio.capture_index >= 0.5, do: "text-rose-400", else: "text-slate-200")}><%= @portfolio.capture_index %></span>
              </div>

              <!-- Dependency Graph Risk -->
              <div class="flex justify-between items-center border-b border-slate-800 pb-2.5">
                <div>
                  <span class="text-slate-300 block font-semibold">Ancestry Dependency Risk</span>
                  <span class="text-[9px] text-slate-500">Overlap of lineage ancestors</span>
                </div>
                <span class="text-slate-200 font-bold"><%= @portfolio.dependency_risk %></span>
              </div>

              <!-- Cascading Failure Risk (CFR) -->
              <div class="flex justify-between items-center border-b border-slate-800 pb-2.5">
                <div>
                  <span class="text-slate-300 block font-semibold">Cascading Failure Risk (CFR)</span>
                  <span class="text-[9px] text-slate-500">Fraction of collateral collapse</span>
                </div>
                <span class="text-slate-200 font-bold"><%= @portfolio.cascading_failure_risk %></span>
              </div>

              <!-- Portfolio Adaptation Velocity (PAV) -->
              <div class="flex justify-between items-center border-b border-slate-800 pb-2.5">
                <div>
                  <span class="text-slate-300 block font-semibold">Adaptation Velocity (PAV)</span>
                  <span class="text-[9px] text-slate-500">Reconfiguration responsiveness</span>
                </div>
                <span class="text-slate-200 font-bold"><%= @portfolio.adaptation_velocity %></span>
              </div>

              <!-- Recovery Capacity (PRC) -->
              <div class="flex justify-between items-center">
                <div>
                  <span class="text-slate-300 block font-semibold">Recovery Capacity (PRC)</span>
                  <span class="text-[9px] text-slate-500">Yield recovery after shock</span>
                </div>
                <span class="text-emerald-400 font-bold"><%= @portfolio.recovery_capacity %></span>
              </div>
            </div>
          </div>

        </div>

      </div>

    </div>
    """
  end

  defp get_provenance do
    state =
      case Process.whereis(TiannaraOS.CivilizationKernel) do
        nil -> nil
        pid ->
          if Process.alive?(pid) do
            TiannaraOS.CivilizationKernel.get_state()
          else
            nil
          end
      end

    if state do
      TiannaraOS.MetricWithProvenance.from_state(0.0, state).provenance
    else
      %{theories_count: 0, evidence_nodes_count: 0, replication_events_count: 0, repository_worlds_count: 0}
    end
  end
end
