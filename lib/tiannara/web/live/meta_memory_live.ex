defmodule TiannaraWeb.MetaMemoryLive do
  @moduledoc """
  Interactive Meta-Memory Physics Dashboard.
  Displays trusted and failed memory species, trust evolution logs, context similarity maps,
  and active recommendation components for second-order adaptation knowledge.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.OrbitMemorySelection
  alias Tiannara.REA.MetaMemoryExtractor
  alias Tiannara.REA.MetaMemoryLearner
  alias Tiannara.REA.MetaMemoryPredictor
  alias Tiannara.REA.MetaMemoryCurriculum

  def mount(_params, _session, socket) do
    # Load default species population
    species = OrbitMemorySelection.load_species()
    tensor = MetaMemoryExtractor.extract(species)

    # Context values
    volatility = 0.15
    complexity = 0.50
    selected_species_id = hd(species).species_id

    # Recommendation
    recommendation = MetaMemoryPredictor.recommend(tensor, %{volatility: volatility, complexity: complexity})

    # Learning history tracker
    learning_history = [
      %{iteration: 1, species_id: "generalist_species_upsilon", trust: 0.85, status: :success},
      %{iteration: 2, species_id: "collapse_species_omega", trust: 0.15, status: :failure},
      %{iteration: 3, species_id: "specialist_species_sigma", trust: 0.65, status: :success}
    ]

    {:ok,
     assign(socket,
       species: species,
       tensor: tensor,
       volatility: volatility,
       complexity: complexity,
       selected_species_id: selected_species_id,
       recommendation: recommendation,
       learning_history: learning_history,
       iteration_count: 3,
       message: nil
     )}
  end

  def handle_event("update_context", %{"volatility" => vol_str, "complexity" => comp_str}, socket) do
    vol = String.to_float(vol_str)
    comp = String.to_float(comp_str)
    context = %{volatility: vol, complexity: comp}

    recommendation = MetaMemoryPredictor.recommend(socket.assigns.tensor, context)

    {:noreply,
     assign(socket,
       volatility: vol,
       complexity: comp,
       recommendation: recommendation
     )}
  end

  def handle_event("select_species", %{"species_id" => id}, socket) do
    {:noreply, assign(socket, selected_species_id: id, message: nil)}
  end

  def handle_event("simulate_success", _params, socket) do
    species_id = socket.assigns.selected_species_id
    context = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity}
    
    updated_tensor = MetaMemoryLearner.learn(socket.assigns.tensor, species_id, context, true)
    
    # Update recommendation
    recommendation = MetaMemoryPredictor.recommend(updated_tensor, context)

    # Track in history
    iteration = socket.assigns.iteration_count + 1
    new_trust = Map.get(updated_tensor.trust_weights, species_id, 0.50)
    new_history = socket.assigns.learning_history ++ [%{iteration: iteration, species_id: species_id, trust: new_trust, status: :success}]

    {:noreply,
     assign(socket,
       tensor: updated_tensor,
       recommendation: recommendation,
       learning_history: new_history,
       iteration_count: iteration,
       message: "Meta-Memory learned: Lineage #{species_id} succeeded in current context. Trust weight increased."
     )}
  end

  def handle_event("simulate_failure", _params, socket) do
    species_id = socket.assigns.selected_species_id
    context = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity}
    
    updated_tensor = MetaMemoryLearner.learn(socket.assigns.tensor, species_id, context, false)
    
    # Update recommendation
    recommendation = MetaMemoryPredictor.recommend(updated_tensor, context)

    # Track in history
    iteration = socket.assigns.iteration_count + 1
    new_trust = Map.get(updated_tensor.trust_weights, species_id, 0.50)
    new_history = socket.assigns.learning_history ++ [%{iteration: iteration, species_id: species_id, trust: new_trust, status: :failure}]

    {:noreply,
     assign(socket,
       tensor: updated_tensor,
       recommendation: recommendation,
       learning_history: new_history,
       iteration_count: iteration,
       message: "Meta-Memory learned: Lineage #{species_id} failed in current context. Trust weight penalized."
     )}
  end

  def handle_event("decay_unused", _params, socket) do
    species_id = socket.assigns.selected_species_id
    
    updated_tensor = MetaMemoryLearner.decay_trust(socket.assigns.tensor, species_id, 0.10)
    context = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity}
    recommendation = MetaMemoryPredictor.recommend(updated_tensor, context)

    {:noreply,
     assign(socket,
       tensor: updated_tensor,
       recommendation: recommendation,
       message: "Obsolete memory decay (Law MM2) applied to #{species_id}. Trust decayed by 10%."
     )}
  end

  def handle_event("transfer_trust", _params, socket) do
    species_id = socket.assigns.selected_species_id
    
    # Mismatched world functor scaling factor (e.g. 0.85)
    updated_tensor = MetaMemoryLearner.transfer_trust(socket.assigns.tensor, species_id, 0.85)
    context = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity}
    recommendation = MetaMemoryPredictor.recommend(updated_tensor, context)

    {:noreply,
     assign(socket,
       tensor: updated_tensor,
       recommendation: recommendation,
       message: "Law MM3 Applied: Functor translated trust in #{species_id} across world coordinates."
     )}
  end

  def handle_event("reset_meta", _params, socket) do
    tensor = MetaMemoryExtractor.extract(socket.assigns.species)
    context = %{volatility: socket.assigns.volatility, complexity: socket.assigns.complexity}
    recommendation = MetaMemoryPredictor.recommend(tensor, context)

    {:noreply,
     assign(socket,
       tensor: tensor,
       recommendation: recommendation,
       iteration_count: 0,
       learning_history: [],
       message: "Meta-Memory Tensor reset to baseline state."
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 uppercase">Phase 11.14</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Meta-Memory Physics</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Meta-Memory Physics</h1>
          <p class="text-sm text-slate-400 mt-1">Second-order adaptive layer discovering what kinds of memories can be trusted under varying world contexts.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="reset_meta" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-semibold font-mono transition-all">
            Reset Meta Tensor
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
        
        <!-- COLUMN 1: Recommendation Engine & Simulator -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Recommendation Panel -->
          <div class="glass-card p-6 bg-gradient-to-br from-indigo-500/5 to-purple-500/5">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> Recommended Memory Species
            </h2>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-center mb-6">
              <div class="p-5 bg-slate-950 border border-slate-900 rounded-xl">
                <span class="text-[10px] font-mono text-slate-500 block uppercase">Recommended Lineage</span>
                <span class="text-xl font-extrabold text-indigo-400 mt-2 block">
                  <%= @recommendation.recommended_species %>
                </span>
                <p class="text-[10px] text-slate-500 mt-2 leading-relaxed font-sans">
                  The second-order meta-predictor selects this lineage as the most robust strategy for current volatility.
                </p>
              </div>
              
              <div class="p-5 bg-slate-950 border border-slate-900 rounded-xl">
                <span class="text-[10px] font-mono text-slate-500 block uppercase">Prediction Confidence</span>
                <span class="text-3xl font-extrabold text-emerald-400 mt-1 block">
                  <%= Float.round(@recommendation.confidence * 100, 2) %>%
                </span>
                <div class="w-full bg-slate-900 h-1.5 rounded-full overflow-hidden mt-3 border border-slate-800">
                  <div class="h-full bg-emerald-500" style={"width: " <> to_string(round(@recommendation.confidence * 100)) <> "%"}></div>
                </div>
              </div>
            </div>

            <!-- Context Sliders -->
            <form phx-change="update_context" class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <label class="text-[10px] font-mono text-slate-400 uppercase tracking-wider block mb-1">
                  Target Context Volatility: <%= @volatility %>
                </label>
                <input type="range" name="volatility" min="0.0" max="0.5" step="0.05" value={@volatility} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
                <span class="text-[9px] text-slate-500 font-mono block mt-1">High Volatility (V &ge; 0.25) triggers Generalist recommendation.</span>
              </div>
              <div>
                <label class="text-[10px] font-mono text-slate-400 uppercase tracking-wider block mb-1">
                  Target Context Complexity: <%= @complexity %>
                </label>
                <input type="range" name="complexity" min="0.0" max="1.0" step="0.05" value={@complexity} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
                <span class="text-[9px] text-slate-500 font-mono block mt-1">High Complexity (C &ge; 0.70) triggers Specialist recommendation.</span>
              </div>
            </form>
          </div>

          <!-- Meta-Learning Simulator Controls -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Meta-Learning Feedback Loops
            </h2>
            <p class="text-xs text-slate-400 mb-6">
              Interact with the active meta-learning engine. Select a species, execute it, and feed the outcomes (Success/Failure) back into the meta-memory tensor.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 items-end mb-6">
              <div>
                <label class="text-[10px] font-mono text-slate-500 block uppercase mb-2">Target Species to Train</label>
                <form phx-change="select_species">
                  <select name="species_id" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-emerald-500">
                    <%= for s <- @species do %>
                      <option value={s.species_id} selected={s.species_id == @selected_species_id}>
                        <%= s.species_id %> (Trust: <%= Map.get(@tensor.trust_weights, s.species_id, 0.50) %>)
                      </option>
                    <% end %>
                  </select>
                </form>
              </div>

              <div class="flex flex-wrap gap-2">
                <button phx-click="simulate_success" class="flex-grow px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-lg text-xs font-semibold font-mono transition-all">
                  Learn Success (MM1)
                </button>
                <button phx-click="simulate_failure" class="flex-grow px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg text-xs font-semibold font-mono transition-all">
                  Learn Failure (MM1)
                </button>
              </div>
            </div>

            <div class="flex gap-2 border-t border-slate-800/60 pt-4">
              <button phx-click="decay_unused" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-mono transition-all">
                Forget Memory (MM2 Decay)
              </button>
              <button phx-click="transfer_trust" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-mono transition-all">
                Meta-Transfer Trust (MM3 Functor)
              </button>
            </div>
          </div>

          <!-- Meta-Learning Curves -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Meta-Learning Curves
            </h2>
            
            <div class="overflow-x-auto">
              <table class="w-full text-left border-collapse text-xs font-mono">
                <thead>
                  <tr class="border-b border-slate-800 text-slate-500 text-[10px] uppercase tracking-wider">
                    <th class="pb-2">Iteration</th>
                    <th class="pb-2">Target Species</th>
                    <th class="pb-2 text-center">Updated Trust</th>
                    <th class="pb-2 text-right">Execution Outcome</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/40">
                  <%= for h <- Enum.reverse(@learning_history) do %>
                    <tr>
                      <td class="py-2.5 text-slate-400">#<%= h.iteration %></td>
                      <td class="py-2.5 font-semibold text-slate-200"><%= h.species_id %></td>
                      <td class="py-2.5 text-center text-indigo-400 font-bold"><%= h.trust %></td>
                      <td class="py-2.5 text-right">
                        <span class={"px-2 py-0.5 rounded text-[9px] font-bold " <> (if h.status == :success, do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20", else: "bg-rose-500/10 text-rose-400 border border-rose-500/20")}>
                          <%= String.upcase(to_string(h.status)) %>
                        </span>
                      </td>
                    </tr>
                  <% end %>
                  <%= if @learning_history == [] do %>
                    <tr>
                      <td colspan="4" class="py-4 text-center text-slate-500">No learning logs available. Run feedback simulation.</td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>

        </div>

        <!-- COLUMN 2: Trust Monitors, Curriculum, Similarity -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Trusted Memory Species -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500"></span> Trusted Species (&ge; 0.50)
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Lineages categorized with active adaptation Optionality value.</p>

            <div class="flex flex-col gap-3 font-mono text-xs">
              <%= for species_id <- @tensor.successful_species do %>
                <% trust = Map.get(@tensor.trust_weights, species_id, 0.0) %>
                <div class="flex justify-between items-center p-2.5 bg-slate-900/40 border border-slate-800 rounded-lg">
                  <span class="text-slate-200 font-semibold"><%= species_id %></span>
                  <span class="text-emerald-400 font-bold"><%= trust %></span>
                </div>
              <% end %>
              <%= if @tensor.successful_species == [], do: "No trusted lineages in active pool." %>
            </div>
          </div>

          <!-- Failed Memory Species -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-rose-500"></span> Failed/Obsolete Species (&lt; 0.30)
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Lineages marked for selection decay or deletion.</p>

            <div class="flex flex-col gap-3 font-mono text-xs">
              <%= for species_id <- @tensor.failed_species do %>
                <% trust = Map.get(@tensor.trust_weights, species_id, 0.0) %>
                <div class="flex justify-between items-center p-2.5 bg-slate-900/40 border border-slate-800 rounded-lg">
                  <span class="text-slate-400"><%= species_id %></span>
                  <span class="text-rose-400 font-semibold"><%= trust %></span>
                </div>
              <% end %>
              <%= if @tensor.failed_species == [], do: "No lineages classified as failed/obsolete." %>
            </div>
          </div>

          <!-- Trust Evolution -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-indigo-500"></span> Trust Evolution Matrix
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Complete meta-memory trust weights for all species.</p>

            <div class="flex flex-col gap-2.5 font-mono text-xs">
              <%= for {id, weight} <- @tensor.trust_weights do %>
                <div class="flex flex-col gap-1">
                  <div class="flex justify-between text-[10px]">
                    <span class="text-slate-300"><%= id %></span>
                    <span class="text-slate-400"><%= weight %></span>
                  </div>
                  <div class="w-full bg-slate-900 h-1 rounded-full overflow-hidden">
                    <div class="h-full bg-indigo-500" style={"width: " <> to_string(round(weight * 100)) <> "%"}></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Context Similarity Map -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-purple-500"></span> Context Similarity Map
            </h2>
            <p class="text-[10px] text-slate-400 mb-4">Calculates topological distance between target coordinates and training experiences.</p>

            <div class="flex flex-col gap-2 font-mono text-[10px] text-slate-400">
              <%= for ctx <- @tensor.world_contexts do %>
                <% distance = Float.round(abs(ctx.volatility - @volatility) + abs(ctx.complexity - @complexity), 4) %>
                <div class="p-2.5 bg-slate-900/60 border border-slate-800 rounded-lg flex justify-between items-center">
                  <div>
                    <span class="text-slate-200 font-bold block"><%= Map.get(ctx, :label, "World Context") %></span>
                    <span class="text-slate-500 text-[9px]">V: <%= ctx.volatility %> | C: <%= ctx.complexity %></span>
                  </div>
                  <span class={"font-bold px-2 py-0.5 rounded text-[9px] " <> (if distance <= 0.15, do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20", else: "bg-slate-800 text-slate-400")}>
                    Dist: <%= distance %>
                  </span>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Adaptive Knowledge Graph (Curriculum) -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-amber-500"></span> Adaptive Knowledge Graph
            </h2>
            <p class="text-[10px] text-slate-400 mb-3">Second-order curriculum mapping of successful strategies to environmental classes.</p>

            <% graph = MetaMemoryCurriculum.get_adaptation_knowledge_graph(@tensor) %>
            <div class="flex flex-col gap-2 font-mono text-[10px]">
              <%= for edge <- graph.edges do %>
                <div class="p-2.5 bg-slate-950 border border-slate-900 rounded-lg flex justify-between items-center text-slate-400">
                  <div class="flex flex-col">
                    <span><%= edge.from %> &rarr; <%= edge.to %></span>
                    <span class="text-[8px] text-slate-500 uppercase mt-0.5"><%= edge.label %></span>
                  </div>
                  <span class="text-amber-400 font-bold"><%= Float.round(edge.weight, 4) %></span>
                </div>
              <% end %>
            </div>
          </div>

        </div>

      </div>

      <!-- Meta-Memory Physics Laws -->
      <div class="glass-card p-6">
        <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
          <span class="w-3.5 h-3.5 rounded bg-purple-600 flex items-center justify-center text-[10px] text-white">MM</span> Discovered Meta-Memory Laws
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 font-mono text-xs">
          
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-purple-400 font-bold block mb-1">Law MM1 — Memory Trust Formation</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Success feedback in a given context accumulates confidence and trust weights exponentially:
              T_t+1 = T_t + η * (1.0 - T_t)
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-rose-400 font-bold block mb-1">Law MM2 — Memory Forgetting</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Obsolete or unused memories gradually decay in trust weight, preventing outdated strategies from dominating decisions when environment profiles drift.
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-indigo-400 font-bold block mb-1">Law MM3 — Meta-Transfer</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Trust in a memory is translated across topologically mismatched worlds by projecting through the functor scaling matrix coefficient.
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-amber-400 font-bold block mb-1">Law MM4 — Meta-Generalization</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              Successful adaptation knowledge in one context predicts success in another if the topological context distance metric is minimized.
            </p>
          </div>

          <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
            <span class="text-emerald-400 font-bold block mb-1">Law MM5 — Meta-Learning</span>
            <p class="text-slate-400 text-[10px] leading-normal">
              The system optimizes its recommendation parameters based on historical curriculum execution logs, learning to learn.
            </p>
          </div>

        </div>
      </div>

    </div>
    """
  end
end
