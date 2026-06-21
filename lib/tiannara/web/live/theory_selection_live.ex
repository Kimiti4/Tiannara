defmodule TiannaraWeb.TheorySelectionLive do
  @moduledoc """
  Interactive Theory Selection Physics Dashboard.
  Provides controls for selection sweeps, correlation predictors, and environmental regime mappings.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.TheorySelection
  alias Tiannara.REA.TheoryFitnessAnalyzer
  alias Tiannara.REA.TheoryRadiation
  alias Tiannara.REA.TheoryNiches

  def mount(_params, _session, socket) do
    theories = TheorySelection.load_theories()
    niches = TheoryNiches.classify_niches(theories)
    rankings = TheoryFitnessAnalyzer.rank_theory_invariants(theories, 0.15, 0.10)
    radiation = TheoryRadiation.detect_theory_radiation(theories)

    {:ok,
     assign(socket,
       theories: theories,
       niches: niches,
       rankings: rankings,
       radiation: radiation,
       generations: 10,
       volatility: 0.15,
       complexity: 0.10,
       events: [],
       message: nil
     )}
  end

  def handle_event("run_sweep", %{"generations" => gen_str, "volatility" => vol_str, "complexity" => comp_str}, socket) do
    generations = String.to_integer(gen_str)
    volatility = String.to_float(vol_str)
    complexity = String.to_float(comp_str)

    {updated, trace} = TheorySelection.run_theory_selection_sweep(socket.assigns.theories, generations, volatility, complexity)
    
    # Save the updated populations
    TheorySelection.save_theories(updated)

    niches = TheoryNiches.classify_niches(updated)
    rankings = TheoryFitnessAnalyzer.rank_theory_invariants(updated, volatility, complexity)
    radiation = TheoryRadiation.detect_theory_radiation(updated)

    # Collect events across the sweep trace
    events = Enum.flat_map(trace, & &1.events)

    {:noreply,
     assign(socket,
       theories: updated,
       niches: niches,
       rankings: rankings,
       radiation: radiation,
       generations: generations,
       volatility: volatility,
       complexity: complexity,
       events: events,
       message: "Selection sweep completed over #{generations} generations."
     )}
  end

  def handle_event("reset_simulation", _params, socket) do
    defaults = TheorySelection.default_theories()
    TheorySelection.save_theories(defaults)

    niches = TheoryNiches.classify_niches(defaults)
    rankings = TheoryFitnessAnalyzer.rank_theory_invariants(defaults, 0.15, 0.10)
    radiation = TheoryRadiation.detect_theory_radiation(defaults)

    {:noreply,
     assign(socket,
       theories: defaults,
       niches: niches,
       rankings: rankings,
       radiation: radiation,
       events: [],
       message: "Simulation state reset to default baseline population."
     )}
  end

  # Helper to compute winning theory dynamically for a hypothetical regime coordinate
  defp get_regime_winner(theories, vol, comp) do
    best =
      Enum.max_by(theories, fn t ->
        TheorySelection.calculate_fitness(t, vol, comp)
      end, fn -> nil end)

    if best, do: best.theory_id, else: "N/A"
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 uppercase">Phase 11.16</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Theory Selection Physics Workbench</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Theory Selection Physics</h1>
          <p class="text-sm text-slate-400 mt-1">Analyzing why theories survive and whether theory fitness correlates with truth across environmental axes.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="reset_simulation" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-semibold font-mono transition-all">
            Reset Theories Archive
          </button>
        </div>
      </div>

      <%= if @message do %>
        <div class="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs font-mono text-emerald-400 animate-pulse">
          <%= @message %>
        </div>
      <% end %>

      <!-- Simulator Controls -->
      <div class="glass-card p-6">
        <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
          <span class="w-2.5 h-2.5 rounded bg-amber-500"></span> Replicator Dynamics Simulator
        </h2>
        <form phx-submit="run_sweep" class="grid grid-cols-1 md:grid-cols-4 gap-6 items-end font-mono text-xs text-slate-300">
          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Generations Sweep</label>
            <input type="range" name="generations" min="1" max="50" value={@generations} class="w-full accent-amber-500" oninput="this.nextElementSibling.value = this.value" />
            <output class="text-amber-400 block mt-1 text-right"><%= @generations %></output>
          </div>

          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Volatility Coordinate</label>
            <input type="range" name="volatility" min="0.0" max="1.0" step="0.05" value={@volatility} class="w-full accent-amber-500" oninput="this.nextElementSibling.value = this.value" />
            <output class="text-amber-400 block mt-1 text-right"><%= @volatility %></output>
          </div>

          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Complexity Coordinate</label>
            <input type="range" name="complexity" min="0.0" max="1.0" step="0.05" value={@complexity} class="w-full accent-amber-500" oninput="this.nextElementSibling.value = this.value" />
            <output class="text-amber-400 block mt-1 text-right"><%= @complexity %></output>
          </div>

          <button type="submit" class="w-full py-3 bg-amber-500 hover:bg-amber-600 text-slate-950 font-bold rounded-lg text-xs transition-all uppercase tracking-wider">
            Run Selection Sweep
          </button>
        </form>
      </div>

      <!-- Main Layout Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

        <!-- Column 1 & 2: Leaderboard & Environmental Sweep -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Theories Leaderboard -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Active Theory Populations
            </h2>
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse text-xs font-mono">
                <thead>
                  <tr class="border-b border-slate-800 text-slate-500 text-[10px] uppercase tracking-wider">
                    <th class="pb-2">Theory ID</th>
                    <th class="pb-2 text-center">Extinction Risk</th>
                    <th class="pb-2 text-center">CDR</th>
                    <th class="pb-2 text-center">Rt (Reprod)</th>
                    <th class="pb-2 text-center">Lifetime</th>
                    <th class="pb-2 text-center">TLI</th>
                    <th class="pb-2 text-right">Population</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40">
                  <%= for t <- Enum.sort_by(@theories, & &1.population, :desc) do %>
                    <tr class="hover:bg-slate-900/40 transition-colors">
                      <td class="py-3 font-semibold text-slate-200"><%= t.theory_id %></td>
                      <td class="py-3 text-center">
                        <span class={"px-2 py-0.5 rounded text-[10px] " <> (if t.extinction_risk >= 0.50, do: "bg-rose-500/10 text-rose-400 border border-rose-500/20", else: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20")}>
                          <%= t.extinction_risk %>
                        </span>
                      </td>
                      <td class="py-3 text-center text-blue-400 font-bold"><%= t.cross_domain_resilience || 0.0 %></td>
                      <td class="py-3 text-center text-indigo-400"><%= t.reproduction_rate || 0.0 %></td>
                      <td class="py-3 text-center text-slate-400"><%= t.lifetime || 0 %></td>
                      <td class="py-3 text-center text-purple-400"><%= t.longevity_index || 1.0 %></td>
                      <td class="py-3 text-right font-bold text-slate-100"><%= t.population %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Environmental Regime Discovery Grid -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-emerald-500"></span> Geometric Environmental Regimes
            </h2>
            <p class="text-xs text-slate-400 mb-4">Dynamically calculated winning theory species mapping to environment geometry coordinates.</p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4 font-mono text-xs">
              
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="flex justify-between items-center mb-1">
                  <span class="text-slate-400 uppercase text-[9px] tracking-wider block">Volatile Regime (V >= 0.50)</span>
                  <span class="text-[9px] bg-amber-500/10 text-amber-400 border border-amber-500/20 px-2 py-0.5 rounded font-bold">Transferability</span>
                </div>
                <div class="text-slate-200 font-semibold mt-1">Winner: <%= get_regime_winner(@theories, 0.60, 0.10) %></div>
              </div>

              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="flex justify-between items-center mb-1">
                  <span class="text-slate-400 uppercase text-[9px] tracking-wider block">Complex Regime (C >= 0.60)</span>
                  <span class="text-[9px] bg-purple-500/10 text-purple-400 border border-purple-500/20 px-2 py-0.5 rounded font-bold">Compression</span>
                </div>
                <div class="text-slate-200 font-semibold mt-1">Winner: <%= get_regime_winner(@theories, 0.10, 0.75) %></div>
              </div>

              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="flex justify-between items-center mb-1">
                  <span class="text-slate-400 uppercase text-[9px] tracking-wider block">Stable Regime (V &lt; 0.20, C &lt; 0.30)</span>
                  <span class="text-[9px] bg-blue-500/10 text-blue-400 border border-blue-500/20 px-2 py-0.5 rounded font-bold">Predictive Power</span>
                </div>
                <div class="text-slate-200 font-semibold mt-1">Winner: <%= get_regime_winner(@theories, 0.05, 0.05) %></div>
              </div>

              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="flex justify-between items-center mb-1">
                  <span class="text-slate-400 uppercase text-[9px] tracking-wider block">Mixed Regime (Intermediate)</span>
                  <span class="text-[9px] bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded font-bold">Convergence</span>
                </div>
                <div class="text-slate-200 font-semibold mt-1">Winner: <%= get_regime_winner(@theories, 0.30, 0.30) %></div>
              </div>

            </div>
          </div>

        </div>

        <!-- Column 3: Predictors, Hazard Ratios, Niche classifications -->
        <div class="lg:col-span-1 flex flex-col gap-6">

          <!-- Selection Physics Variable Rankings -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-amber-500"></span> Selection Predictor Rankings
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Correlation analysis &amp; Hazard Ratios. $HR &lt; 1.0$ indicates active protection.</p>
            <div class="flex flex-col gap-4 font-mono text-xs">
              <%= for {r, idx} <- Enum.with_index(@rankings) do %>
                <div class="flex flex-col gap-1.5 border-b border-slate-800/40 pb-2.5 last:border-0 last:pb-0">
                  <div class="flex justify-between text-[10px]">
                    <span class={if idx == 0, do: "text-amber-400 font-bold", else: "text-slate-300"}>
                      <%= idx + 1 %>. <%= String.upcase(to_string(r.variable)) %>
                    </span>
                    <span class="text-slate-400">Corr: <%= r.correlation %></span>
                  </div>
                  <div class="flex justify-between text-[9px] text-slate-500 mt-0.5">
                    <span>P(Surv): <%= r.p_survival %></span>
                    <span>Hazard Ratio: <%= r.hazard_ratio %></span>
                  </div>
                  <div class="w-full bg-slate-900 h-1.5 rounded-full overflow-hidden mt-1">
                    <div class={"h-full " <> (if idx == 0, do: "bg-amber-500", else: "bg-indigo-500")} style={"width: " <> to_string(max(1, round(abs(r.correlation) * 100))) <> "%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Evolutionary Niches families -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Evolutionary Niches
            </h2>
            <div class="flex flex-col gap-3 font-mono text-xs">
              
              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Universal Laws (CDR &ge; 0.75)</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for t <- @niches.universal do %>
                    <span class="px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[9px]"><%= t.theory_id %></span>
                  <% end %>
                  <%= if @niches.universal == [], do: "None" %>
                </div>
              </div>

              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Domain-Specific Laws</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for t <- @niches.domain_specific do %>
                    <span class="px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20 text-[9px]"><%= t.theory_id %></span>
                  <% end %>
                  <%= if @niches.domain_specific == [], do: "None" %>
                </div>
              </div>

              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Endangered Niches</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for t <- @niches.endangered do %>
                    <span class="px-2 py-0.5 rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 text-[9px]"><%= t.theory_id %></span>
                  <% end %>
                  <%= if @niches.endangered == [], do: "None" %>
                </div>
              </div>

              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Refuted / Extinct</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for t <- @niches.refuted do %>
                    <span class="px-2 py-0.5 rounded bg-rose-500/10 text-rose-400 border border-rose-500/20 text-[9px]"><%= t.theory_id %></span>
                  <% end %>
                  <%= if @niches.refuted == [], do: "None" %>
                </div>
              </div>

            </div>
          </div>

          <!-- Evolutionary Sweep Event Logger -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-rose-500"></span> Sweep Event Logs
            </h2>
            <div class="flex flex-col gap-2 max-h-48 overflow-y-auto font-mono text-[9px] text-slate-400">
              <%= for log <- @events do %>
                <div class={"p-2 rounded border " <> (if log.type == :extinction, do: "bg-rose-500/5 border-rose-500/10 text-rose-400", else: "bg-emerald-500/5 border-emerald-500/10 text-emerald-400")}>
                  <%= log.message %>
                </div>
              <% end %>
              <%= if @events == [], do: "No selection events recorded in last sweep." %>
            </div>
          </div>

        </div>

      </div>
    </div>
    """
  end
end
