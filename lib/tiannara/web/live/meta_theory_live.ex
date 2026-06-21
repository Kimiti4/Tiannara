defmodule TiannaraWeb.MetaTheoryLive do
  @moduledoc """
  Interactive Meta-Theory Physics Dashboard.
  Provides sliders for context coordinates, dynamic portfolios, validation loops, and episode history tables.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.TheorySelection
  alias Tiannara.REA.MetaTheoryExtractor
  alias Tiannara.REA.MetaTheoryLearner
  alias Tiannara.REA.MetaTheoryPredictor
  alias Tiannara.REA.DomainCrucible

  def mount(_params, _session, socket) do
    theories = TheorySelection.load_theories()
    domains = DomainCrucible.all_domains()
    selected_domain = hd(domains)

    # Initial context
    context = %{volatility: 0.15, complexity: 0.10, adversariality: 0.05}
    tensor = MetaTheoryExtractor.extract(theories)

    rec = MetaTheoryPredictor.recommend(tensor, context, selected_domain)
    weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(tensor, context, selected_domain)

    {:ok,
     assign(socket,
       tensor: tensor,
       domains: domains,
       selected_domain: selected_domain,
       volatility: 0.15,
       complexity: 0.10,
       adversariality: 0.05,
       rec: rec,
       weights: weights,
       message: nil
     )}
  end

  def handle_event("update_parameters", %{"volatility" => vol_str, "complexity" => comp_str, "adversariality" => adv_str, "domain" => dom_str}, socket) do
    volatility = String.to_float(vol_str)
    complexity = String.to_float(comp_str)
    adversariality = String.to_float(adv_str)
    selected_domain = String.to_existing_atom(dom_str)

    context = %{volatility: volatility, complexity: complexity, adversariality: adversariality}
    rec = MetaTheoryPredictor.recommend(socket.assigns.tensor, context, selected_domain)
    weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(socket.assigns.tensor, context, selected_domain)

    {:noreply,
     assign(socket,
       volatility: volatility,
       complexity: complexity,
       adversariality: adversariality,
       selected_domain: selected_domain,
       rec: rec,
       weights: weights,
       message: nil
     )}
  end

  def handle_event("run_validation_loop", _params, socket) do
    tensor = socket.assigns.tensor
    recommended_theory = socket.assigns.rec.recommended_theory

    if recommended_theory == "N/A" do
      {:noreply, assign(socket, message: "No active theory recommended to validate.")}
    else
      context = %{
        volatility: socket.assigns.volatility,
        complexity: socket.assigns.complexity,
        adversariality: socket.assigns.adversariality,
        domain: socket.assigns.selected_domain
      }

      # Simulate outcomes: success is more likely if we are close to the focus context
      focus = MetaTheoryPredictor.theory_focus_context(recommended_theory)
      v_diff = abs(focus.volatility - context.volatility)
      c_diff = abs(focus.complexity - context.complexity)
      a_diff = abs(focus.adversariality - context.adversariality)
      
      # Probability of success depends on compatibility
      success_prob = max(0.20, min(0.95, 1.0 - (v_diff + c_diff + a_diff) / 3.0))
      success? = :rand.uniform() <= success_prob

      survival_delta = if success?, do: :rand.uniform() * 0.15, else: -(:rand.uniform() * 0.20)

      updated_tensor = MetaTheoryLearner.learn(tensor, recommended_theory, context, success?, Float.round(survival_delta, 4))
      
      # Recalculate recommendations
      context_coords = %{volatility: context.volatility, complexity: context.complexity, adversariality: context.adversariality}
      rec = MetaTheoryPredictor.recommend(updated_tensor, context_coords, socket.assigns.selected_domain)
      weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(updated_tensor, context_coords, socket.assigns.selected_domain)

      msg =
        if success? do
          "Validation Success! Theory #{recommended_theory} gained trust."
        else
          "Validation Refutation! Theory #{recommended_theory} lost trust."
        end

      {:noreply,
       assign(socket,
         tensor: updated_tensor,
         rec: rec,
         weights: weights,
         message: msg
       )}
    end
  end

  def handle_event("decay_recommended", _params, socket) do
    tensor = socket.assigns.tensor
    recommended_theory = socket.assigns.rec.recommended_theory

    if recommended_theory == "N/A" do
      {:noreply, assign(socket, message: "No recommended theory to decay.")}
    else
      updated_tensor = MetaTheoryLearner.decay_trust(tensor, recommended_theory, 0.05)
      
      context_coords = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity, adversariality: socket.assigns.adversariality}
      rec = MetaTheoryPredictor.recommend(updated_tensor, context_coords, socket.assigns.selected_domain)
      weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(updated_tensor, context_coords, socket.assigns.selected_domain)

      {:noreply,
       assign(socket,
         tensor: updated_tensor,
         rec: rec,
         weights: weights,
         message: "Decayed trust weight of #{recommended_theory} by 5% (MT2 Forgetting)."
       )}
    end
  end

  def handle_event("transfer_recommended", _params, socket) do
    tensor = socket.assigns.tensor
    recommended_theory = socket.assigns.rec.recommended_theory

    if recommended_theory == "N/A" do
      {:noreply, assign(socket, message: "No recommended theory to transfer.")}
    else
      # Mapped scale representing domain compatibility transfer
      scale = 0.80
      updated_tensor = MetaTheoryLearner.transfer_trust(tensor, recommended_theory, scale)
      
      context_coords = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity, adversariality: socket.assigns.adversariality}
      rec = MetaTheoryPredictor.recommend(updated_tensor, context_coords, socket.assigns.selected_domain)
      weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(updated_tensor, context_coords, socket.assigns.selected_domain)

      {:noreply,
       assign(socket,
         tensor: updated_tensor,
         rec: rec,
         weights: weights,
         message: "Transferred trust of #{recommended_theory} across domains using compatibility scaling coefficient #{scale} (MT3 Transfer)."
       )}
    end
  end

  def handle_event("reset_meta_tensor", _params, socket) do
    theories = TheorySelection.load_theories()
    tensor = MetaTheoryExtractor.extract(theories)

    context = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity, adversariality: socket.assigns.adversariality}
    rec = MetaTheoryPredictor.recommend(tensor, context, socket.assigns.selected_domain)
    weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(tensor, context, socket.assigns.selected_domain)

    {:noreply,
     assign(socket,
       tensor: tensor,
       rec: rec,
       weights: weights,
       message: "Meta-Theory repository reset to extraction baseline defaults."
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 uppercase">Phase 11.17</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Meta-Theory Physics Dashboard</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Meta-Theory Physics</h1>
          <p class="text-sm text-slate-400 mt-1">Second-order learning over competing scientific explanations, managing trust profiles and domain transfers.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="reset_meta_tensor" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-semibold font-mono transition-all">
            Reset Trust Matrix
          </button>
        </div>
      </div>

      <%= if @message do %>
        <div class="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs font-mono text-emerald-400 animate-pulse">
          <%= @message %>
        </div>
      <% end %>

      <!-- Dynamic Context Parameter Sweeper -->
      <div class="glass-card p-6">
        <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
          <span class="w-2.5 h-2.5 rounded bg-emerald-500"></span> A-Priori Recommendation Inspector
        </h2>
        <form phx-change="update_parameters" class="grid grid-cols-1 md:grid-cols-4 gap-6 font-mono text-xs text-slate-300">
          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Volatility</label>
            <input type="range" name="volatility" min="0.0" max="1.0" step="0.05" value={@volatility} class="w-full accent-emerald-500" />
            <output class="text-emerald-400 block mt-1 text-right"><%= @volatility %></output>
          </div>

          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Complexity</label>
            <input type="range" name="complexity" min="0.0" max="1.0" step="0.05" value={@complexity} class="w-full accent-emerald-500" />
            <output class="text-emerald-400 block mt-1 text-right"><%= @complexity %></output>
          </div>

          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Adversariality</label>
            <input type="range" name="adversariality" min="0.0" max="1.0" step="0.05" value={@adversariality} class="w-full accent-emerald-500" />
            <output class="text-emerald-400 block mt-1 text-right"><%= @adversariality %></output>
          </div>

          <div>
            <label class="block mb-2 text-slate-400 uppercase text-[10px]">Target Laboratory Domain</label>
            <select name="domain" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-emerald-500">
              <%= for d <- @domains do %>
                <option value={to_string(d)} selected={d == @selected_domain}>
                  <%= to_string(d) |> String.capitalize() %>
                </option>
              <% end %>
            </select>
          </div>
        </form>
      </div>

      <!-- Recommendation and Simulator Layout -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

        <!-- Column 1 & 2: Simulator Action Controls & Episodes -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Recommendation Block -->
          <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-emerald-500/5 border-emerald-500/10">
            <div>
              <span class="text-[10px] font-mono text-slate-500 uppercase">A-Priori Optimal Strategy Selection (MT4)</span>
              <h2 class="text-2xl font-extrabold text-emerald-400 font-heading mt-1">
                <%= @rec.recommended_theory %>
              </h2>
              <p class="text-xs text-slate-400 mt-1">Recommender confidence rating: <%= @rec.confidence %></p>
            </div>

            <div class="flex flex-wrap gap-2">
              <button phx-click="run_validation_loop" class="px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-lg text-xs font-mono transition-all">
                Validate Selected Theory (MT1)
              </button>
              <button phx-click="decay_recommended" class="px-4 py-2.5 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-mono transition-all">
                Decay Trust (-5%) (MT2)
              </button>
              <button phx-click="transfer_recommended" class="px-4 py-2.5 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-mono transition-all">
                Transfer Domain (scale=0.80) (MT3)
              </button>
            </div>
          </div>

          <!-- Chronological Episodes Table -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Chronological Selection History (Episodes)
            </h2>
            <div class="overflow-x-auto max-h-64 overflow-y-auto">
              <table class="w-full text-left border-collapse text-xs font-mono">
                <thead>
                  <tr class="border-b border-slate-800 text-slate-500 text-[10px] uppercase tracking-wider">
                    <th class="pb-2">Selected Theory</th>
                    <th class="pb-2">Regime Coordinates (V, C, A)</th>
                    <th class="pb-2">Domain</th>
                    <th class="pb-2 text-center">Confidence</th>
                    <th class="pb-2 text-center">Result</th>
                    <th class="pb-2 text-right">Survival Delta</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40">
                  <%= for ep <- @tensor.selection_history do %>
                    <tr class="hover:bg-slate-900/40 transition-colors">
                      <td class="py-3 font-semibold text-slate-200"><%= ep.selected_theory %></td>
                      <td class="py-3 text-slate-400">
                        V: <%= ep.context.volatility %> | C: <%= ep.context.complexity %> | A: <%= ep.context.adversariality %>
                      </td>
                      <td class="py-3 text-slate-400"><%= to_string(ep.domain) |> String.capitalize() %></td>
                      <td class="py-3 text-center text-slate-400"><%= ep.confidence %></td>
                      <td class="py-3 text-center">
                        <span class={"px-2 py-0.5 rounded text-[10px] " <> (if ep.validation_result == :success, do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20", else: "bg-rose-500/10 text-rose-400 border border-rose-500/20")}>
                          <%= ep.validation_result %>
                        </span>
                      </td>
                      <td class={"py-3 text-right font-bold " <> (if ep.survival_delta >= 0.0, do: "text-emerald-400", else: "text-rose-400")}>
                        <%= ep.survival_delta %>
                      </td>
                    </tr>
                  <% end %>
                  <%= if @tensor.selection_history == [] do %>
                    <tr>
                      <td colspan="6" class="py-6 text-center text-slate-500">No theory episodes logged. Execute validation tests to build memory logs.</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

        </div>

        <!-- Column 3: Portfolios & Leaderboard -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Adaptive Portfolio Weights -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-emerald-500"></span> Adaptive Portfolio Selection (MT7)
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Contextual mixtures representing the optimal dynamic allocation ratio.</p>
            <div class="flex flex-col gap-4 font-mono text-xs">
              <%= for {tid, weight} <- @weights do %>
                <div class="flex flex-col gap-1.5">
                  <div class="flex justify-between text-[10px]">
                    <span class="text-slate-300 font-semibold"><%= tid %></span>
                    <span class="text-emerald-400 font-bold"><%= Float.round(weight * 100, 2) %>%</span>
                  </div>
                  <div class="w-full bg-slate-900 h-1.5 rounded-full overflow-hidden">
                    <div class="h-full bg-emerald-500" style={"width: " <> to_string(round(weight * 100)) <> "%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Meta-Trust Leaderboard -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Meta-Trust Leaderboard
            </h2>
            <div class="flex flex-col gap-3 font-mono text-xs">
              <%= for {tid, trust} <- Enum.sort_by(@tensor.theory_trust_weights, &elem(&1, 1), :desc) do %>
                <div class="flex flex-col gap-1 border-b border-slate-800/40 pb-2 last:border-0 last:pb-0">
                  <div class="flex justify-between text-[10px]">
                    <span class="text-slate-200 font-bold"><%= tid %></span>
                    <span class="text-indigo-400 font-bold">Trust: <%= trust %></span>
                  </div>
                  <div class="flex justify-between text-[9px] text-slate-500">
                    <span>Generations: <%= Map.get(@tensor.theory_generations, tid, 1) %></span>
                    <span>Validations: <%= Map.get(@tensor.lifetime_validations, tid, 0) %></span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

        </div>

      </div>

    </div>
    """
  end
end
