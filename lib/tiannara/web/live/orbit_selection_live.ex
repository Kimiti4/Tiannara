defmodule TiannaraWeb.OrbitSelectionLive do
  @moduledoc """
  Interactive Orbit Memory Selection Physics Dashboard.
  Displays species leaderboards, extinction risk monitors, phylogenetic radiation trees,
  fitness variable rankings, and discovered Selection Laws S1-S5.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.OrbitMemorySelection
  alias Tiannara.REA.OrbitMemoryFitnessAnalyzer
  alias Tiannara.REA.OrbitMemoryRadiation
  alias Tiannara.REA.OrbitMemoryNiches

  def mount(_params, _session, socket) do
    species = OrbitMemorySelection.load_species()
    generations = 10
    volatility = 0.10

    {final_pop, trace} = OrbitMemorySelection.run_selection_sweep(species, generations, volatility)
    rankings = OrbitMemoryFitnessAnalyzer.rank_fitness_invariants(species)
    radiation = OrbitMemoryRadiation.detect_adaptive_radiation(species)
    niches = OrbitMemoryNiches.classify_niches(species)

    first_species_id = case species do
      [first | _] -> first.species_id
      _ -> ""
    end

    {:ok,
     assign(socket,
       species: species,
       generations: generations,
       volatility: volatility,
       sweep_results: trace,
       final_population: final_pop,
       rankings: rankings,
       radiation: radiation,
       niches: niches,
       selected_species_id: first_species_id,
       edit_pop_val: "",
       message: nil
     )}
  end

  def handle_event("select_species", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_species_id: id, message: nil)}
  end

  def handle_event("update_parameters", %{"generations" => gen_str, "volatility" => vol_str}, socket) do
    gen = String.to_integer(gen_str)
    vol = String.to_float(vol_str)

    {final_pop, trace} = OrbitMemorySelection.run_selection_sweep(socket.assigns.species, gen, vol)

    {:noreply,
     assign(socket,
       generations: gen,
       volatility: vol,
       sweep_results: trace,
       final_population: final_pop
     )}
  end

  def handle_event("adjust_population", %{"species_id" => id, "pop" => pop_str}, socket) do
    new_pop_val = case Integer.parse(pop_str) do
      {val, _} -> max(0, val)
      _ -> 0
    end

    updated_species =
      Enum.map(socket.assigns.species, fn s ->
        if s.species_id == id do
          # Recalculate fitness-dependent risk
          extinction_risk = 
            cond do
              new_pop_val == 0 -> 1.0
              new_pop_val < 20 -> 0.85
              true -> Float.round(max(0.01, 1.0 - (new_pop_val / 300.0)), 4)
            end

          %{s | population: new_pop_val, extinction_risk: extinction_risk}
        else
          s
        end
      end)

    {final_pop, trace} = OrbitMemorySelection.run_selection_sweep(updated_species, socket.assigns.generations, socket.assigns.volatility)
    rankings = OrbitMemoryFitnessAnalyzer.rank_fitness_invariants(updated_species)
    radiation = OrbitMemoryRadiation.detect_adaptive_radiation(updated_species)
    niches = OrbitMemoryNiches.classify_niches(updated_species)

    {:noreply,
     assign(socket,
       species: updated_species,
       sweep_results: trace,
       final_population: final_pop,
       rankings: rankings,
       radiation: radiation,
       niches: niches,
       message: "Population of #{id} adjusted to #{new_pop_val}."
     )}
  end

  def handle_event("save_to_archive", _params, socket) do
    OrbitMemorySelection.save_species(socket.assigns.species)
    {:noreply, assign(socket, message: "Current population configuration successfully saved to data/orbit_memory_species.ndjson")}
  end

  def handle_event("reset_defaults", _params, socket) do
    species = OrbitMemorySelection.default_species()
    OrbitMemorySelection.save_species(species)
    
    {final_pop, trace} = OrbitMemorySelection.run_selection_sweep(species, socket.assigns.generations, socket.assigns.volatility)
    rankings = OrbitMemoryFitnessAnalyzer.rank_fitness_invariants(species)
    radiation = OrbitMemoryRadiation.detect_adaptive_radiation(species)
    niches = OrbitMemoryNiches.classify_niches(species)

    {:noreply,
     assign(socket,
       species: species,
       sweep_results: trace,
       final_population: final_pop,
       rankings: rankings,
       radiation: radiation,
       niches: niches,
       selected_species_id: hd(species).species_id,
       message: "Species archive reset to standard scientific defaults."
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20 uppercase">Phase 11.13</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Orbit Memory Selection Physics</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Orbit Memory Selection Physics</h1>
          <p class="text-sm text-slate-400 mt-1">Discovering selection laws, invariant ranking correlations, radiation lineages, and extinction thresholds.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="save_to_archive" class="px-4 py-2 bg-blue-600/80 hover:bg-blue-600 text-white rounded-lg text-xs font-semibold font-mono border border-blue-500/30 transition-all">
            Save to Archive
          </button>
          <button phx-click="reset_defaults" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-semibold font-mono transition-all">
            Reset Defaults
          </button>
        </div>
      </div>

      <%= if @message do %>
        <div class="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs font-mono text-emerald-400 animate-pulse">
          <%= @message %>
        </div>
      <% end %>

      <!-- Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- COLUMN 1: Leaderboard & Controls -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Leaderboard Card -->
          <div class="glass-card p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-bold font-heading text-slate-200 flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Species Leaderboard
              </h2>
              <span class="text-[10px] font-mono text-slate-400">Sorted by Population</span>
            </div>

            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse text-xs font-mono">
                <thead>
                  <tr class="border-b border-slate-800 text-slate-500 text-[10px] uppercase tracking-wider">
                    <th class="pb-2">Species ID</th>
                    <th class="pb-2">Parent</th>
                    <th class="pb-2 text-center">Initial Pop</th>
                    <th class="pb-2 text-center">Final Pop</th>
                    <th class="pb-2 text-center">Fitness</th>
                    <th class="pb-2 text-center">MPP</th>
                    <th class="pb-2 text-center">Transferability</th>
                    <th class="pb-2 text-center">Extinction Risk</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40">
                  <%= for s <- Enum.sort_by(@species, & &1.population, :desc) do %>
                    <% final_s = Enum.find(@final_population, &(&1.species_id == s.species_id)) %>
                    <tr phx-click="select_species" phx-value-id={s.species_id} class={"hover:bg-slate-900/40 cursor-pointer transition-colors " <> (if @selected_species_id == s.species_id, do: "bg-blue-500/10 border-l-2 border-blue-500", else: "")}>
                      <td class="py-3 font-semibold text-slate-200"><%= s.species_id %></td>
                      <td class="py-3 text-slate-400"><%= s.parent_species || "None (Root)" %></td>
                      <td class="py-3 text-center text-slate-300"><%= s.population %></td>
                      <td class="py-3 text-center font-bold text-emerald-400">
                        <%= if final_s, do: final_s.population, else: 0 %>
                      </td>
                      <td class="py-3 text-center text-blue-400"><%= s.fitness %></td>
                      <td class="py-3 text-center text-indigo-400"><%= s.mpp %></td>
                      <td class="py-3 text-center text-purple-400"><%= s.functor_retention %></td>
                      <td class="py-3 text-center">
                        <span class={"px-2 py-0.5 rounded text-[9px] font-bold " <> extinction_risk_class(s.extinction_risk)}>
                          <%= s.extinction_risk %>
                        </span>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Selection Sweep Simulator -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Selection Sweep Simulator
            </h2>
            
            <form phx-change="update_parameters" class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
              <div>
                <label class="text-[10px] font-mono text-slate-400 uppercase tracking-wider block mb-1">
                  Simulation Generations: <%= @generations %>
                </label>
                <input type="range" name="generations" min="1" max="50" step="1" value={@generations} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-emerald-500" />
              </div>
              <div>
                <label class="text-[10px] font-mono text-slate-400 uppercase tracking-wider block mb-1">
                  Environmental Volatility: <%= @volatility %>
                </label>
                <input type="range" name="volatility" min="0.0" max="0.5" step="0.05" value={@volatility} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-emerald-500" />
              </div>
            </form>

            <span class="text-xs font-bold text-slate-200 block mb-2">Simulation Run Log</span>
            <div class="p-4 bg-slate-950 border border-slate-900 rounded-xl max-h-60 overflow-y-auto flex flex-col gap-2 font-mono text-[10px]">
              <%= for step <- @sweep_results do %>
                <div class="border-b border-slate-800/40 pb-2 last:border-0 last:pb-0">
                  <div class="flex justify-between text-slate-400 font-semibold">
                    <span>Gen <%= step.generation %></span>
                    <span>Total Pop: <%= Enum.sum(Map.values(step.populations)) %></span>
                  </div>
                  <div class="flex flex-wrap gap-x-4 gap-y-1 text-slate-500 mt-1">
                    <%= for {id, pop} <- step.populations do %>
                      <span><%= id %>: <strong class="text-slate-300"><%= pop %></strong></span>
                    <% end %>
                  </div>
                  <%= if step.events != [] do %>
                    <div class="mt-1 flex flex-col gap-0.5">
                      <%= for event <- step.events do %>
                        <span class={event_class(event.type)}>
                          [<%= String.upcase(to_string(event.type)) %>] <%= event.message %>
                        </span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>

        </div>

        <!-- COLUMN 2: Details, Variable Rankings, Niches -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Detailed Inspector -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-purple-500"></span> Lineage Inspector
            </h2>

            <% inspect_s = Enum.find(@species, &(&1.species_id == @selected_species_id)) %>
            <%= if inspect_s do %>
              <div class="flex flex-col gap-3 font-mono text-xs text-slate-400">
                <div class="flex justify-between border-b border-slate-800/40 pb-1">
                  <span>Species ID:</span>
                  <span class="text-slate-200 font-bold"><%= inspect_s.species_id %></span>
                </div>
                <div class="flex justify-between border-b border-slate-800/40 pb-1">
                  <span>Parent Species:</span>
                  <span class="text-slate-300"><%= inspect_s.parent_species || "None (Root)" %></span>
                </div>
                
                <form phx-change="adjust_population" class="mt-2">
                  <input type="hidden" name="species_id" value={inspect_s.species_id} />
                  <label class="text-[10px] uppercase text-slate-500 block mb-1">Adjust Population Size</label>
                  <input type="number" name="pop" value={inspect_s.population} class="bg-slate-900 border border-slate-800 text-slate-200 rounded p-2 w-full outline-none focus:border-purple-500" />
                </form>

                <div class="grid grid-cols-2 gap-2 mt-4 text-[10px]">
                  <div class="p-2 bg-slate-900 border border-slate-800 rounded">
                    <span class="text-slate-500 block">Compression Ratio</span>
                    <span class="text-slate-200 font-bold"><%= inspect_s.compression_ratio %>x</span>
                  </div>
                  <div class="p-2 bg-slate-900 border border-slate-800 rounded">
                    <span class="text-slate-500 block">Inheritance Stability</span>
                    <span class="text-slate-200 font-bold"><%= inspect_s.inheritance_stability * 100 %>%</span>
                  </div>
                  <div class="p-2 bg-slate-900 border border-slate-800 rounded">
                    <span class="text-slate-500 block">Domain Coverage</span>
                    <span class="text-slate-200 font-bold"><%= inspect_s.domain_coverage %> worlds</span>
                  </div>
                  <div class="p-2 bg-slate-900 border border-slate-800 rounded">
                    <span class="text-slate-500 block">Mutation Recovery</span>
                    <span class="text-slate-200 font-bold"><%= inspect_s.mutation_recovery * 100 %>%</span>
                  </div>
                </div>
              </div>
            <% else %>
              <p class="text-xs text-slate-500 font-mono">Select a lineage from the leaderboard to inspect.</p>
            <% end %>
          </div>

          <!-- Fitness Variable Rankings -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-indigo-500"></span> Fitness Rankings
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Correlation of selection variables with survival probability P(Survival | Var).</p>

            <div class="flex flex-col gap-3 font-mono text-xs">
              <%= for {r, idx} <- Enum.with_index(@rankings) do %>
                <div class="flex flex-col gap-1">
                  <div class="flex justify-between text-[10px]">
                    <span class={if idx == 0, do: "text-emerald-400 font-bold", else: "text-slate-300"}>
                      <%= idx + 1 %>. <%= String.upcase(to_string(r.variable)) %>
                    </span>
                    <span class="text-slate-400">Corr: <%= r.correlation %></span>
                  </div>
                  <div class="w-full bg-slate-900 h-2 rounded-full overflow-hidden border border-slate-800">
                    <div class={"h-full " <> (if idx == 0, do: "bg-emerald-500", else: "bg-indigo-500")} style={"width: " <> to_string(max(1, round(abs(r.correlation) * 100))) <> "%"}></div>
                  </div>
                  <div class="text-[9px] text-slate-500 flex justify-between">
                    <span>P(Survival|Var &gt; median):</span>
                    <span><%= r.p_survival * 100 %>%</span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Ecological Niches -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-amber-500"></span> Ecological Niches
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Grouping the lineage population by adaptive strategy profiles.</p>

            <div class="flex flex-col gap-3 font-mono text-xs">
              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Generalist Guild</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for s <- @niches.generalists do %>
                    <span class="px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-[9px]"><%= s.species_id %></span>
                  <% end %>
                  <%= if @niches.generalists == [], do: "None" %>
                </div>
              </div>

              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Specialist Guild</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for s <- @niches.specialists do %>
                    <span class="px-2 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 text-[9px]"><%= s.species_id %></span>
                  <% end %>
                  <%= if @niches.specialists == [], do: "None" %>
                </div>
              </div>

              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Dominant Species</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for s <- @niches.dominant do %>
                    <span class="px-2 py-0.5 rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 text-[9px]"><%= s.species_id %></span>
                  <% end %>
                  <%= if @niches.dominant == [], do: "None" %>
                </div>
              </div>

              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Endangered / Extinct</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for s <- @niches.endangered ++ @niches.extinct do %>
                    <span class="px-2 py-0.5 rounded bg-rose-500/10 text-rose-400 border border-rose-500/20 text-[9px]"><%= s.species_id %></span>
                  <% end %>
                  <%= if @niches.endangered ++ @niches.extinct == [], do: "None" %>
                </div>
              </div>
            </div>
          </div>

          <!-- Radiation Tree -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span> Radiation Tree
            </h2>
            <p class="text-[10px] text-slate-400 mb-3">Lineages branched from parent species showing divergence scores.</p>

            <div class="flex flex-col gap-3 font-mono text-[10px] text-slate-400">
              <%= for rad <- @radiation.radiations do %>
                <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-lg">
                  <div class="flex justify-between items-center mb-1">
                    <strong class="text-slate-200"><%= rad.parent_species %></strong>
                    <span class="text-[9px] text-blue-400 bg-blue-500/10 px-2 border border-blue-500/20 rounded">
                      Divergence: <%= rad.divergence_score %>
                    </span>
                  </div>
                  <div class="flex flex-col gap-1 pl-3 border-l border-slate-800 mt-2">
                    <%= for child <- rad.children do %>
                      <div class="flex items-center gap-1.5">
                        <span class="text-slate-600">&rarr;</span>
                        <span class="text-slate-300"><%= child %></span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <%= if @radiation.radiation_events_count == 0, do: "No adaptive radiations detected." %>
            </div>
          </div>

        </div>

      </div>

      <!-- Selection Laws Section -->
      <div class="glass-card p-6">
        <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
          <span class="w-3.5 h-3.5 rounded bg-blue-600 flex items-center justify-center text-[10px] text-white">S</span> Discovered Selection Laws
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 font-mono text-xs">
          
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-rose-400 font-bold block mb-1">Law S1 — Extinction</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Lineages with low inheritance stability and low mutation recovery face immediate extinction risk when world coordinates shift.
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-emerald-400 font-bold block mb-1">Law S2 — Dominance</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              High predictive utility (MPP) combined with high domain coverage guarantees long-term lineage population dominance.
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-indigo-400 font-bold block mb-1">Law S3 — Niche Formation</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Memory species coexist by balancing high compression efficiency (specialists) with broad functor transferability (generalists).
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-amber-400 font-bold block mb-1">Law S4 — Generalists vs Specialists</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Generalists dominate highly volatile, multi-domain environments, whereas specialists dominate high-complexity, single-domain basins.
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-purple-400 font-bold block mb-1">Law S5 — Radiation</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Sudden environment shifts (lowered functor retention) force heritable memories to mutate rapidly, triggering adaptive radiation.
            </p>
          </div>

        </div>
      </div>

    </div>
    """
  end

  defp extinction_risk_class(risk) do
    cond do
      risk >= 0.70 -> "bg-rose-500/10 text-rose-400 border border-rose-500/20"
      risk >= 0.30 -> "bg-amber-500/10 text-amber-400 border border-amber-500/20"
      true -> "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
    end
  end

  defp event_class(type) do
    case type do
      :extinction -> "text-rose-400"
      :dominance -> "text-amber-400 font-bold"
      :growth -> "text-emerald-400"
      :decline -> "text-slate-400"
      _ -> "text-slate-400"
    end
  end
end
