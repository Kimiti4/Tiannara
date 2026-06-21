defmodule TiannaraWeb.TheoryEcologyLive do
  @moduledoc """
  Interactive Theory Ecology Dashboard.
  Displays relational theory leaderboards, domain crucible validation grids,
  recombination sandboxes, and universal candidate laws.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.TheoryEcology
  alias Tiannara.REA.TheoryMutator
  alias Tiannara.REA.DomainCrucible
  alias Tiannara.REA.TheoryNiches

  def mount(_params, _session, socket) do
    theories = DomainCrucible.baseline_theories()
    domains = DomainCrucible.all_domains()

    # Pre-select parents for sandbox
    parent_a_id = Enum.at(theories, 0).theory_id
    parent_b_id = Enum.at(theories, 3).theory_id

    # Classifications
    niches = TheoryNiches.classify_theories(theories)

    # Initial Predictor rankings
    rankings = TheoryEcology.rank_theory_predictors(theories)

    # Temporary domain list
    selected_domain = hd(domains)

    {:ok,
     assign(socket,
       theories: theories,
       domains: domains,
       parent_a_id: parent_a_id,
       parent_b_id: parent_b_id,
       selected_domain: selected_domain,
       niches: niches,
       rankings: rankings,
       generations: 10,
       volatility: 0.15,
       refutation_logs: [],
       message: nil
     )}
  end

  def handle_event("select_parents", %{"parent_a" => a_id, "parent_b" => b_id}, socket) do
    {:noreply, assign(socket, parent_a_id: a_id, parent_b_id: b_id, message: nil)}
  end

  def handle_event("select_domain", %{"domain" => domain_str}, socket) do
    domain = String.to_atom(domain_str)
    {:noreply, assign(socket, selected_domain: domain, message: nil)}
  end

  def handle_event("recombine_sandbox", _params, socket) do
    parent_a = Enum.find(socket.assigns.theories, &(&1.theory_id == socket.assigns.parent_a_id))
    parent_b = Enum.find(socket.assigns.theories, &(&1.theory_id == socket.assigns.parent_b_id))

    if parent_a && parent_b do
      child = TheoryMutator.recombine(parent_a, parent_b)
      updated_theories = [child | socket.assigns.theories]
      
      # Re-evaluate
      niches = TheoryNiches.classify_theories(updated_theories)
      rankings = TheoryEcology.rank_theory_predictors(updated_theories)

      {:noreply,
       assign(socket,
         theories: updated_theories,
         niches: niches,
         rankings: rankings,
         message: "Emergent recombination successful! Child theory #{child.theory_id} generated."
       )}
    else
      {:noreply, assign(socket, message: "Invalid parent selection.")}
    end
  end

  def handle_event("run_domain_crucible", %{"generations" => gen_str}, socket) do
    generations = String.to_integer(gen_str)
    domains = socket.assigns.domains

    # 1. Independently evolve theories inside the 20 domain labs
    domain_theory_maps =
      Map.new(domains, fn domain ->
        evolved_theories = DomainCrucible.evolve_theories_in_domain(domain, generations)
        {domain, evolved_theories}
      end)

    # 2. Measure cross-domain convergence (H3)
    converged_theories = DomainCrucible.measure_convergence(domain_theory_maps)

    # Merge with current list and re-evaluate
    combined_theories =
      (converged_theories ++ socket.assigns.theories)
      |> Enum.uniq_by(& &1.theory_id)

    niches = TheoryNiches.classify_theories(combined_theories)
    rankings = TheoryEcology.rank_theory_predictors(combined_theories)

    {:noreply,
     assign(socket,
       theories: combined_theories,
       niches: niches,
       rankings: rankings,
       generations: generations,
       message: "Evolved theories independently across all 20 domains. Evolved candidates converged."
     )}
  end

  def handle_event("test_single_domain", _params, socket) do
    domain = socket.assigns.selected_domain
    # Validate the first theory on the leaderboard against the selected domain
    target_theory = hd(Enum.sort_by(socket.assigns.theories, & &1.population, :desc))

    updated_theory = DomainCrucible.validate_theory(target_theory, domain)

    # Log failures if any occurred during verification
    new_logs =
      if length(updated_theory.failure_history) > length(target_theory.failure_history) do
        new_fail = List.last(updated_theory.failure_history)
        socket.assigns.refutation_logs ++ [%{domain: domain, reason: new_fail.reason}]
      else
        socket.assigns.refutation_logs
      end

    updated_theories =
      Enum.map(socket.assigns.theories, fn t ->
        if t.theory_id == target_theory.theory_id, do: updated_theory, else: t
      end)

    niches = TheoryNiches.classify_theories(updated_theories)
    rankings = TheoryEcology.rank_theory_predictors(updated_theories)

    message =
      if length(updated_theory.failure_history) > length(target_theory.failure_history) do
        "Theory #{target_theory.theory_id} refuted in #{to_string(domain)}: #{List.last(updated_theory.failure_history).reason}"
      else
        "Theory #{target_theory.theory_id} successfully validated in #{to_string(domain)} laboratory."
      end

    {:noreply,
     assign(socket,
       theories: updated_theories,
       niches: niches,
       rankings: rankings,
       refutation_logs: new_logs,
       message: message
     )}
  end

  def handle_event("reset_defaults", _params, socket) do
    theories = DomainCrucible.baseline_theories()
    niches = TheoryNiches.classify_theories(theories)
    rankings = TheoryEcology.rank_theory_predictors(theories)

    {:noreply,
     assign(socket,
       theories: theories,
       parent_a_id: Enum.at(theories, 0).theory_id,
       parent_b_id: Enum.at(theories, 3).theory_id,
       niches: niches,
       rankings: rankings,
       refutation_logs: [],
       message: "Theory repository reset to baseline defaults."
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 uppercase">Phase 11.15</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Theory Ecology Dashboard</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Theory Ecology</h1>
          <p class="text-sm text-slate-400 mt-1">Evolving relational theory genomes across 20 independent domain evolutionary laboratories.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="reset_defaults" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-semibold font-mono transition-all">
            Reset Baseline Theories
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
        
        <!-- COLUMN 1: Evolved Leaderboard & Sandbox -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Leaderboard Panel -->
          <div class="glass-card p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-bold font-heading text-slate-200 flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> Evolved Relational Theories
              </h2>
              <span class="text-[10px] font-mono text-slate-400">Sorted by Active Population</span>
            </div>

            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse text-xs font-mono">
                <thead>
                  <tr class="border-b border-slate-800 text-slate-500 text-[10px] uppercase tracking-wider">
                    <th class="pb-2">Theory ID</th>
                    <th class="pb-2">Relational Gene Statements</th>
                    <th class="pb-2 text-center">Gen</th>
                    <th class="pb-2 text-center">Domains</th>
                    <th class="pb-2 text-center">Convergence</th>
                    <th class="pb-2 text-center">Predictive Power</th>
                    <th class="pb-2 text-right">Population</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40">
                  <%= for t <- Enum.sort_by(@theories, & &1.population, :desc) do %>
                    <tr class="hover:bg-slate-900/40 transition-colors">
                      <td class="py-3 font-semibold text-slate-200"><%= t.theory_id %></td>
                      <td class="py-3 text-slate-400 max-w-xs truncate">
                        <%= for rel <- t.relations do %>
                          <div class="text-[10px] text-indigo-300">
                            <%= String.upcase(to_string(rel.lhs)) %> <%= to_string(rel.operator) %> <%= to_string(rel.rhs) %> [<%= to_string(rel.context) %>]
                          </div>
                        <% end %>
                      </td>
                      <td class="py-3 text-center text-slate-400"><%= t.generation %></td>
                      <td class="py-3 text-center text-slate-400"><%= length(t.domains_discovered) %> / 20</td>
                      <td class="py-3 text-center text-emerald-400 font-bold"><%= t.convergence_score %></td>
                      <td class="py-3 text-center text-blue-400"><%= t.predictive_power %></td>
                      <td class="py-3 text-right font-bold text-slate-200"><%= t.population %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Domain Crucible Grid Matrix -->
          <div class="glass-card p-6">
            <div class="flex justify-between items-start mb-4">
              <div>
                <h2 class="text-xl font-bold font-heading text-slate-200 flex items-center gap-2">
                  <span class="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Domain Crucible Laboratories (H3)
                </h2>
                <p class="text-xs text-slate-400 mt-1">
                  Parallel evolutionary runs in 20 domains. Measures independent rediscovery (convergence score).
                </p>
              </div>
            </div>

            <!-- Matrix Visualization -->
            <div class="grid grid-cols-4 sm:grid-cols-5 gap-3 mb-6">
              <%= for d <- @domains do %>
                <% # Check if the top theory holds in this domain %>
                <% top_theory = hd(Enum.sort_by(@theories, & &1.population, :desc)) %>
                <% has_discovered = to_string(d) in top_theory.domains_discovered %>
                <div class={"p-2.5 rounded-lg border text-center font-mono text-[9px] " <> (if has_discovered, do: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20 font-bold", else: "bg-slate-900/40 text-slate-500 border-slate-800")}>
                  <%= to_string(d) |> String.capitalize() %>
                </div>
              <% end %>
            </div>

            <form phx-submit="run_domain_crucible" class="flex flex-wrap gap-4 items-end border-t border-slate-800/60 pt-4">
              <div class="flex-grow">
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Ecology Evolutionary Generations</label>
                <input type="number" name="generations" value={@generations} class="bg-slate-900 border border-slate-800 text-slate-200 rounded p-2.5 w-full outline-none focus:border-amber-500 text-xs" />
              </div>
              <button type="submit" class="px-6 py-2.5 bg-amber-500 hover:bg-amber-600 text-slate-950 font-bold rounded-lg text-xs font-mono transition-all">
                Run Crucible Evolution (H3)
              </button>
            </form>
          </div>

          <!-- Single Laboratory Test Utility -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-purple-500"></span> Single Domain Crucible Verification
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Select an experimental laboratory and test the top-ranked theory to assert success or trigger logical refutations.
            </p>

            <div class="flex flex-wrap gap-4 items-end">
              <div class="flex-grow">
                <label class="text-[10px] font-mono text-slate-500 block uppercase mb-2">Select Target Laboratory</label>
                <form phx-change="select_domain">
                  <select name="domain" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-purple-500">
                    <%= for d <- @domains do %>
                      <option value={to_string(d)} selected={d == @selected_domain}>
                        <%= to_string(d) |> String.capitalize() %>
                      </option>
                    <% end %>
                  </select>
                </form>
              </div>

              <button phx-click="test_single_domain" class="px-6 py-2.5 bg-purple-600 hover:bg-purple-700 text-white rounded-lg text-xs font-semibold font-mono transition-all">
                Execute Verification Test
              </button>
            </div>
          </div>

        </div>

        <!-- COLUMN 2: Sandbox, Niches, Rankings -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Theory Recombination Sandbox -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-indigo-500"></span> Recombination Sandbox (H2)
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Recombine Parent A and Parent B logic clauses to evolve hybrid descendant theories.</p>

            <form phx-change="select_parents" class="flex flex-col gap-3 font-mono text-xs text-slate-400 mb-4">
              <div>
                <label class="text-[9px] uppercase text-slate-500 block mb-1">Parent Theory A</label>
                <select name="parent_a" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded p-2 w-full outline-none">
                  <%= for t <- @theories do %>
                    <option value={t.theory_id} selected={t.theory_id == @parent_a_id}><%= t.theory_id %></option>
                  <% end %>
                </select>
              </div>

              <div>
                <label class="text-[9px] uppercase text-slate-500 block mb-1">Parent Theory B</label>
                <select name="parent_b" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded p-2 w-full outline-none">
                  <%= for t <- @theories do %>
                    <option value={t.theory_id} selected={t.theory_id == @parent_b_id}><%= t.theory_id %></option>
                  <% end %>
                </select>
              </div>
            </form>

            <button phx-click="recombine_sandbox" class="w-full py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg text-xs font-semibold font-mono transition-all">
              Recombine Genomes (T4)
            </button>
          </div>

          <!-- Predictor Variables Rankings -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500"></span> Predictors of Theory Survival
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Selection Analysis correlation output proving which genomic traits guarantee survival.</p>

            <div class="flex flex-col gap-3 font-mono text-xs">
              <%= for {r, idx} <- Enum.with_index(@rankings) do %>
                <div class="flex flex-col gap-1">
                  <div class="flex justify-between text-[10px]">
                    <span class={if idx == 0, do: "text-emerald-400 font-bold", else: "text-slate-300"}>
                      <%= idx + 1 %>. <%= String.upcase(to_string(r.variable)) %>
                    </span>
                    <span class="text-slate-400">Corr: <%= r.correlation %></span>
                  </div>
                  <div class="w-full bg-slate-900 h-1.5 rounded-full overflow-hidden">
                    <div class={"h-full " <> (if idx == 0, do: "bg-emerald-500", else: "bg-indigo-500")} style={"width: " <> to_string(max(1, round(abs(r.correlation) * 100))) <> "%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Refutation Logs -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-rose-500"></span> Crucible Refutation Alerts
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Latest refutations registered in domain labs.</p>

            <div class="flex flex-col gap-2 max-h-48 overflow-y-auto font-mono text-[9px] text-slate-400">
              <%= for log <- @refutation_logs do %>
                <div class="p-2 bg-rose-500/5 border border-rose-500/10 rounded text-rose-400">
                  <strong><%= String.capitalize(to_string(log.domain)) %> Refutation:</strong> <%= log.reason %>
                </div>
              <% end %>
              <%= if @refutation_logs == [], do: "No refutation alerts. Theories remain robust." %>
            </div>
          </div>

          <!-- Ecological Niches Families -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span> Evolved Niche Families (T2)
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Clustering theory species into active ecological families.</p>

            <div class="flex flex-col gap-3 font-mono text-xs">
              <div class="flex flex-col gap-1">
                <span class="text-[10px] text-slate-500 uppercase">Universal Laws (V &ge; 15 domains)</span>
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
                <span class="text-[10px] text-slate-500 uppercase">Refuted Theories</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for t <- @niches.refuted do %>
                    <span class="px-2 py-0.5 rounded bg-rose-500/10 text-rose-400 border border-rose-500/20 text-[9px]"><%= t.theory_id %></span>
                  <% end %>
                  <%= if @niches.refuted == [], do: "None" %>
                </div>
              </div>
            </div>
          </div>

        </div>

      </div>

      <!-- Candidate Universal Laws -->
      <div class="glass-card p-6">
        <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
          <span class="w-3.5 h-3.5 rounded bg-indigo-600 flex items-center justify-center text-[10px] text-white">U</span> Candidate Universal Laws
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6 font-mono text-xs">
          
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <div class="flex justify-between items-center mb-1">
              <span class="text-emerald-400 font-bold">Theory Alpha (Transferability Hypothesis)</span>
              <span class="text-[9px] bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded">CONVERGENCE: 0.90</span>
            </div>
            <p class="text-slate-400 text-[10px] leading-normal">
              <strong>Relations:</strong> FUNCTOR_RETENTION dominates MPP under high environmental volatility.
              Survivability: 0.85 | Transferability: 0.92
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <div class="flex justify-between items-center mb-1">
              <span class="text-emerald-400 font-bold">Theory Delta (History Hypothesis)</span>
              <span class="text-[9px] bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded">CONVERGENCE: 0.85</span>
            </div>
            <p class="text-slate-400 text-[10px] leading-normal">
              <strong>Relations:</strong> HISTORY exceeds STATE_ALONE in all world environments.
              Survivability: 0.92 | Predictive Power: 0.85
            </p>
          </div>

        </div>
      </div>

    </div>
    """
  end
end
