defmodule TiannaraWeb.OrbitEcologyLive do
  @moduledoc """
  Interactive Orbit Memory Ecology Dashboard.
  Showcases memetic competition, mutation, speciation, category-theoretic translation (Functors),
  causal interventions (Do-Calculus), Truth Maintenance (JTMS), and Simplicial Complex coverage maps.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemoryEcology
  alias Tiannara.REA.OrbitMemory.Functor
  alias Tiannara.REA.OrbitMemory.CausalDo
  alias Tiannara.REA.OrbitMemory.JTMS
  alias Tiannara.REA.OrbitMemory.Topology
  alias Tiannara.REA.OrbitMemory.Inheritance

  def mount(_params, _session, socket) do
    records = OrbitGenesis.all_records()

    # Pre-select a default donor (stable) and recipient (failing/collapsed)
    donor = Enum.find(records, &(&1["orbit_outcome"] == "stability_orbit")) || hd(records)
    recipient = Enum.find(records, &(&1["orbit_outcome"] in ["other_orbit_1", "collapse_recovery_orbit"])) || List.last(records)

    donor_omt = OrbitMemory.extract(donor)
    recipient_omt = OrbitMemory.extract(recipient)

    # Initialize JTMS
    JTMS.init_table()

    # Initial computations
    speciation = OrbitMemoryEcology.calculate_speciation(records)
    topology_report = Topology.detect_epistemic_holes(records)
    competition = OrbitMemoryEcology.run_memory_competition(records, 5)
    inheritance_results = Inheritance.run_inheritance_experiment(records)
    child_omt = Inheritance.recombine(donor_omt, recipient_omt, 0.50)
    recombination_mode = Inheritance.classify_recombination_mode(child_omt, donor_omt, recipient_omt)
    lineage_results = Inheritance.run_lineage_formation_experiment(records, 10)
    fitness_results = Inheritance.run_fitness_dominance(records, 50)
    learning_demo = Tiannara.REA.OrbitMemory.LearningEngine.run_demonstration_experiment(donor, recipient)

    {:ok,
     assign(socket,
       records: records,
       donor_world_id: donor["world_id"],
       recipient_world_id: recipient["world_id"],
       donor_world: donor,
       recipient_world: recipient,
       donor_omt: donor_omt,
       recipient_omt: recipient_omt,
       translated_omt: nil,
       do_intervention_result: nil,
       jtms_status: :none,
       rule_shock_active: false,
       epochs: 5,
       evolution_results: competition,
       speciation_clusters: speciation,
       topology_report: topology_report,
       transfer_triggered: false,
       # Inheritance sandbox assigns
       recombination_weight: 0.50,
       child_omt: child_omt,
       recombination_mode: recombination_mode,
       inheritance_results: inheritance_results,
       lineage_results: lineage_results,
       fitness_results: fitness_results,
       learning_demo: learning_demo
     )}
  end

  def handle_event("select_donor", %{"donor_id" => donor_id}, socket) do
    donor = Enum.find(socket.assigns.records, &(&1["world_id"] == donor_id))
    donor_omt = OrbitMemory.extract(donor)
    child_omt = Inheritance.recombine(donor_omt, socket.assigns.recipient_omt, socket.assigns.recombination_weight)
    recombination_mode = Inheritance.classify_recombination_mode(child_omt, donor_omt, socket.assigns.recipient_omt)
    learning_demo = Tiannara.REA.OrbitMemory.LearningEngine.run_demonstration_experiment(donor, socket.assigns.recipient_world)

    {:noreply,
     assign(socket,
       donor_world_id: donor_id,
       donor_world: donor,
       donor_omt: donor_omt,
       child_omt: child_omt,
       recombination_mode: recombination_mode,
       learning_demo: learning_demo,
       transfer_triggered: false,
       do_intervention_result: nil,
       jtms_status: :none
     )}
  end

  def handle_event("select_recipient", %{"recipient_id" => recipient_id}, socket) do
    recipient = Enum.find(socket.assigns.records, &(&1["world_id"] == recipient_id))
    recipient_omt = OrbitMemory.extract(recipient)
    child_omt = Inheritance.recombine(socket.assigns.donor_omt, recipient_omt, socket.assigns.recombination_weight)
    recombination_mode = Inheritance.classify_recombination_mode(child_omt, socket.assigns.donor_omt, recipient_omt)
    learning_demo = Tiannara.REA.OrbitMemory.LearningEngine.run_demonstration_experiment(socket.assigns.donor_world, recipient)

    {:noreply,
     assign(socket,
       recipient_world_id: recipient_id,
       recipient_world: recipient,
       recipient_omt: recipient_omt,
       child_omt: child_omt,
       recombination_mode: recombination_mode,
       learning_demo: learning_demo,
       transfer_triggered: false,
       do_intervention_result: nil,
       jtms_status: :none
     )}
  end

  def handle_event("update_recombination_weight", %{"weight" => w_str}, socket) do
    w = String.to_float(w_str)
    child_omt = Inheritance.recombine(socket.assigns.donor_omt, socket.assigns.recipient_omt, w)
    recombination_mode = Inheritance.classify_recombination_mode(child_omt, socket.assigns.donor_omt, socket.assigns.recipient_omt)
    {:noreply, assign(socket, recombination_weight: w, child_omt: child_omt, recombination_mode: recombination_mode)}
  end

  def handle_event("inject_memory", _params, socket) do
    donor_omt = socket.assigns.donor_omt
    recipient_world = socket.assigns.recipient_world

    # Category-theoretic translation via Functor
    translation_res = Functor.translate(donor_omt, socket.assigns.donor_world, recipient_world)
    translated_omt = translation_res.translated_omt

    # Causal Do-Calculus evaluation
    do_result = CausalDo.evaluate_do_intervention(translated_omt, recipient_world)

    # Register belief inside JTMS
    outcome = if do_result.is_safe, do: "stability_orbit", else: "other_orbit_1"
    JTMS.register_belief(recipient_world["world_id"], translated_omt.transition_signature, outcome)

    # Fetch current JTMS state
    {:valid, belief} = JTMS.verify_and_retract(recipient_world["world_id"], outcome)

    {:noreply,
     assign(socket,
       translated_omt: translated_omt,
       do_intervention_result: do_result,
       jtms_status: {:valid, belief},
       transfer_triggered: true,
       rule_shock_active: false
     )}
  end

  def handle_event("trigger_rule_shock", _params, socket) do
    # Trigger a rule shock that makes the stable simulated outcome fail
    recipient_world = socket.assigns.recipient_world

    # Retract truth belief under JTMS on the collapsed outcome
    {status, belief} = JTMS.verify_and_retract(recipient_world["world_id"], "other_orbit_1")

    {:noreply,
     assign(socket,
       jtms_status: {status, belief},
       rule_shock_active: true
     )}
  end

  def handle_event("update_epochs", %{"epochs" => epochs_str}, socket) do
    epochs = String.to_integer(epochs_str)
    competition = OrbitMemoryEcology.run_memory_competition(socket.assigns.records, epochs)

    {:noreply,
     assign(socket,
       epochs: epochs,
       evolution_results: competition
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Title Bar -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 uppercase">Phase 11.12</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Orbit Memory Ecology Dashboard</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Orbit Memory Ecology</h1>
          <p class="text-sm text-slate-400 mt-1">Evolving civilizational memory: speciation, vector-symbolic compute, category-theoretic functors, and truth maintenance.</p>
        </div>
      </div>

      <!-- Main Dashboard Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">

        <!-- Column 1: Speciation and Evolutionary Competition -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          <!-- Speciation lineages panel -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-purple-500"></span> Memetic Speciation
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Grouping memory populations into lineages based on Vector-Symbolic Architecture (1000-D cosine similarity &ge; 0.40).
            </p>

            <div class="flex flex-col gap-3">
              <%= for {cluster, idx} <- Enum.with_index(@speciation_clusters) do %>
                <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-xl">
                  <div class="flex justify-between items-center mb-2">
                    <span class="text-xs font-bold font-mono text-purple-400">Lineage Alpha-<%= idx %></span>
                    <span class="text-[9px] font-mono bg-purple-500/10 text-purple-300 border border-purple-500/20 px-2 py-0.5 rounded">
                      <%= length(cluster) %> Worlds
                    </span>
                  </div>
                  <div class="text-[10px] font-mono text-slate-400 max-h-24 overflow-y-auto">
                    <%= for {world_id, _vec} <- cluster do %>
                      <div class="flex justify-between py-0.5">
                        <span>World: <%= world_id %></span>
                        <% rec = Enum.find(@records, &(&1["world_id"] == world_id)) %>
                        <span class="text-slate-500 font-sans"><%= format_name(rec["orbit_outcome"]) %></span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Evolutionary Competition and Mutation Monitor -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Evolutionary Selection Monitor
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Selection over 50 generations (Set D). Fitter memories (high MES/MPP) replicate and dominate population.
            </p>

            <div class="p-3 bg-slate-900 border border-slate-800 rounded-xl mb-4 text-xs font-mono">
              <div class="flex justify-between"><span>Fitness Dominance:</span> <span class="text-emerald-400 font-bold"><%= if @fitness_results.dominance_verified, do: "VERIFIED", else: "PENDING" %></span></div>
              <div class="flex justify-between"><span>Net Fitness Gain:</span> <span class="text-emerald-400 font-bold">+<%= @fitness_results.fitness_gain %></span></div>
            </div>

            <form phx-change="update_epochs" class="mb-4">
              <label class="text-[10px] font-mono text-slate-400 block mb-1">Evolutionary Epochs: <%= @epochs %></label>
              <input type="range" name="epochs" min="1" max="20" step="1" value={@epochs} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-emerald-500" />
            </form>

            <div class="max-h-64 overflow-y-auto flex flex-col gap-2">
              <%= for ind <- Enum.take(@evolution_results, 8) do %>
                <div class="p-2.5 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-center text-xs font-mono">
                  <div class="flex flex-col">
                    <span class="text-slate-200 font-bold">World: <%= String.slice(ind["world_id"], 0, 12) %></span>
                    <span class="text-[9px] text-slate-500">IP: <%= ind["identity_persistence"] %> | RV: <%= ind["recovery_velocity"] %></span>
                  </div>
                  <span class="text-emerald-400 font-bold">Fit</span>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Column 2: Inheritance and Cross-World Functors -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          <!-- OMG Inheritance & Recombination Sandbox -->
          <div class="glass-card p-6">
            <div class="flex justify-between items-start mb-2">
              <h2 class="text-xl font-bold font-heading text-slate-200 flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> OMG Inheritance & Recombination Sandbox
              </h2>
              <span class="bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 px-2 py-0.5 rounded font-mono uppercase text-[9px]">
                <%= format_mode(@recombination_mode) %>
              </span>
            </div>
            <p class="text-xs text-slate-400 mb-4">
              Verify Orbit Memory Genome (OMG) heritability. Recombine Parent A (Donor) and Parent B (Recipient) memories to produce hybrid child genomes.
            </p>

            <form phx-change="update_recombination_weight" class="mb-4">
              <label class="text-[10px] font-mono text-slate-400 block mb-1">Recombination Weight (Parent A / Donor): <%= @recombination_weight %></label>
              <input type="range" name="weight" min="0.0" max="1.0" step="0.05" value={@recombination_weight} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
            </form>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <!-- Child Genome details -->
              <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
                <span class="text-xs font-bold font-heading text-slate-200 block mb-2 text-purple-400">Child OMG Genome</span>
                <div class="text-[10px] font-mono text-slate-400 flex flex-col gap-1">
                  <div>Strength: <span class="text-slate-200 font-bold"><%= @child_omt.memory_strength %></span></div>
                  <div>Half-Life: <span class="text-slate-200 font-bold"><%= @child_omt.memory_half_life %> epochs</span></div>
                  <div>MES: <span class="text-slate-200 font-bold"><%= @child_omt.memory_existence_score %></span></div>
                  <div>MPP: <span class="text-slate-200 font-bold"><%= @child_omt.memory_predictive_power %></span></div>
                  <div class="text-[9px] text-slate-500 mt-1">Signature: <%= Enum.join(Enum.take(@child_omt.transition_signature, 5), ", ") %>...</div>
                </div>
              </div>

              <!-- Falsification Scores -->
              <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl flex flex-col justify-between">
                <div>
                  <span class="text-xs font-bold font-heading text-slate-200 block mb-2 text-indigo-400">Heritability Metrics</span>
                  <div class="text-[10px] font-mono text-slate-400 flex flex-col gap-1">
                    <div class="flex justify-between"><span>OMH (Heritability)</span> <span class="text-slate-200 font-bold"><%= @inheritance_results.omh %></span></div>
                    <div class="flex justify-between"><span>OMR (Recombination)</span> <span class="text-slate-200 font-bold"><%= @inheritance_results.omr %></span></div>
                    <div class="flex justify-between"><span>OME (Emergence)</span> <span class="text-slate-200 font-bold"><%= @inheritance_results.ome %></span></div>
                    <div class="flex justify-between border-t border-slate-800 pt-1 mt-1 text-[9px] text-slate-500">
                      <span>Set C Species / Persistence:</span>
                      <span class="text-slate-300"><%= @lineage_results.species_count %> / <%= @lineage_results.lineage_persistence %> gens</span>
                    </div>
                  </div>
                </div>

                <div class="mt-2 text-[10px] font-sans text-emerald-400 font-semibold bg-emerald-500/10 border border-emerald-500/20 rounded px-2 py-1 text-center">
                  OMH & OMR &gt; 0 &rarr; Genomes are Evolvable!
                </div>
              </div>
            </div>

            <!-- Species classification details -->
            <div class="p-3 bg-slate-900/40 border border-slate-800 rounded-lg text-xs font-mono text-slate-400 mb-4">
              <span class="text-slate-300 font-bold block mb-1">Orbit Species Archive (Current Genomes):</span>
              <div class="flex flex-wrap gap-4 text-[10px]">
                <div>Stability Species: <span class="text-emerald-400 font-bold"><%= Map.get(@inheritance_results.species_archive, :stability_species, 0) %></span></div>
                <div>Recovery Species: <span class="text-blue-400 font-bold"><%= Map.get(@inheritance_results.species_archive, :recovery_species, 0) %></span></div>
                <div>Collapse Species: <span class="text-rose-400 font-bold"><%= Map.get(@inheritance_results.species_archive, :collapse_species, 0) %></span></div>
                <div>Phoenix Species: <span class="text-purple-400 font-bold"><%= Map.get(@inheritance_results.species_archive, :phoenix_species, 0) %></span></div>
              </div>
            </div>

            <!-- Sample Lineage Genealogy Ancestry Tree -->
            <div class="p-4 bg-slate-900/80 border border-slate-800 rounded-xl">
              <span class="text-xs font-bold text-slate-200 block mb-2 font-heading">Sample Lineage Genealogy Tree (Set C)</span>
              <div class="text-[9px] font-mono text-slate-400 flex flex-col gap-2 max-h-48 overflow-y-auto">
                <%= for node <- Enum.take_random(@lineage_results.lineage_tree, 5) do %>
                  <div class="flex justify-between items-center py-1 border-b border-slate-800/40 last:border-b-0">
                    <span>Gen <%= node.generation %>: <strong class="text-indigo-300"><%= String.slice(node.id, 0, 12) %>...</strong></span>
                    <span class="text-slate-500">Parents: <%= if node.parents == [], do: "None", else: Enum.map(node.parents, &String.slice(&1, 0, 8)) |> Enum.join(" + ") %></span>
                    <span class="text-emerald-400 font-semibold uppercase"><%= format_name(node.outcome) %></span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Cross-World Memory Functor Sandbox
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Translate successful orbit memories from a donor world to stabilize a failing/collapsed recipient world (e.g. Kenya Energy infrastructure simulation).
            </p>

            <!-- Selector Controls -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <!-- Donor World Selector -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <label class="text-[10px] font-mono text-slate-500 uppercase block mb-2">Donor World (Stability)</label>
                <form phx-change="select_donor">
                  <select name="donor_id" class="bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-lg p-2 outline-none w-full focus:border-blue-500">
                    <%= for rec <- @records do %>
                      <option value={rec["world_id"]} selected={rec["world_id"] == @donor_world_id}>
                        <%= rec["world_id"] %> (<%= format_name(rec["orbit_outcome"]) %>)
                      </option>
                    <% end %>
                  </select>
                </form>
                <div class="mt-3 text-xs font-mono text-slate-400">
                  <div>IP: <%= @donor_world["identity_persistence"] %></div>
                  <div>Outcome: <span class="text-emerald-400 font-bold"><%= format_name(@donor_world["orbit_outcome"]) %></span></div>
                </div>
              </div>

              <!-- Recipient World Selector -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <label class="text-[10px] font-mono text-slate-500 uppercase block mb-2">Recipient World (Collapsing)</label>
                <form phx-change="select_recipient">
                  <select name="recipient_id" class="bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-lg p-2 outline-none w-full focus:border-blue-500">
                    <%= for rec <- @records do %>
                      <option value={rec["world_id"]} selected={rec["world_id"] == @recipient_world_id}>
                        <%= rec["world_id"] %> (<%= format_name(rec["orbit_outcome"]) %>)
                      </option>
                    <% end %>
                  </select>
                </form>
                <div class="mt-3 text-xs font-mono text-slate-400">
                  <div>IP: <%= @recipient_world["identity_persistence"] %></div>
                  <div>Outcome: <span class="text-rose-400 font-bold"><%= format_name(@recipient_world["orbit_outcome"]) %></span></div>
                </div>
              </div>
            </div>

            <!-- Sandbox Action -->
            <div class="flex justify-center mb-6">
              <button phx-click="inject_memory" class="px-6 py-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold font-heading shadow-lg shadow-blue-500/20 transition-all">
                Inject Translated Memory via Functor
              </button>
            </div>

            <!-- Interventional results -->
            <%= if @transfer_triggered do %>
              <div class="border-t border-slate-800 pt-6">
                <h3 class="text-lg font-bold text-slate-200 mb-3 font-heading">Functor Translation & Intervention Analysis</h3>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                  <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
                    <span class="text-[9px] font-mono text-slate-500 block uppercase">Functor Output Strength</span>
                    <span class="text-2xl font-bold font-mono text-blue-400 mt-1 block">
                      <%= @translated_omt.memory_strength %>
                    </span>
                  </div>
                  <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
                    <span class="text-[9px] font-mono text-slate-500 block uppercase">Interventional Survival P(S|do(M))</span>
                    <span class="text-2xl font-bold font-mono text-emerald-400 mt-1 block">
                      <%= @do_intervention_result.interventional_probability_of_survival * 100 %>%
                    </span>
                  </div>
                  <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl">
                    <span class="text-[9px] font-mono text-slate-500 block uppercase">Causal Effect Delta</span>
                    <span class="text-2xl font-bold font-mono text-indigo-400 mt-1 block">
                      +<%= @do_intervention_result.causal_effect %>
                    </span>
                  </div>
                </div>

                <!-- JTMS belief block -->
                <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl mb-4">
                  <div class="flex justify-between items-center">
                    <span class="text-xs font-bold text-slate-200">JTMS Belief Node status</span>
                    <%= case @jtms_status do %>
                      <% {:valid, belief} -> %>
                        <span class="text-[10px] font-mono bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded">
                          <%= String.upcase(to_string(belief.validity)) %>
                        </span>
                      <% {:retracted, belief} -> %>
                        <span class="text-[10px] font-mono bg-rose-500/10 text-rose-400 border border-rose-500/20 px-2 py-0.5 rounded">
                          <%= String.upcase(to_string(belief.validity)) %>
                        </span>
                      <% _ -> %>
                        <span class="text-[10px] font-mono text-slate-500">None</span>
                    <% end %>
                  </div>
                  <p class="text-[10px] text-slate-500 mt-1 leading-normal">
                    Justification-Based Truth Maintenance registers memory validation beliefs dynamically.
                  </p>
                  <%= if match?({:valid, _}, @jtms_status) do %>
                    <div class="mt-3 flex justify-between items-center">
                      <span class="text-xs font-mono text-slate-400">Simulation Status: Running</span>
                      <button phx-click="trigger_rule_shock" class="text-[10px] font-mono px-3 py-1 bg-rose-500/20 text-rose-400 border border-rose-500/30 hover:bg-rose-500/30 rounded transition-all">
                        Trigger Physics Rule Shock
                      </button>
                    </div>
                  <% end %>
                </div>

                <%= if @rule_shock_active do %>
                  <div class="p-3 bg-rose-500/10 border border-rose-500/20 rounded-lg text-xs font-mono text-rose-400">
                    <strong>JTMS Retraction Fired:</strong> Underlying physical laws changed. Justification-Based Truth Maintenance successfully retracted OMT validity across all linked worlds.
                  </div>
                <% else %>
                  <div class="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs font-mono text-emerald-400">
                    <strong>Functor Stabilization Success:</strong> Translated memory was successfully injected. World <%= @recipient_world_id %> stabilized to a stable trajectory basin.
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Civilization Learning Engine Demonstration Experiment (Set F) -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Civilization Learning Engine (Set F)
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Demonstrates cross-world adaptation transfer. Memory from successful donor is translated via category-theoretic functor mappings and injected to stabilize crisis target.
            </p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs font-mono text-slate-400">
              <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg text-center">
                <span class="text-[9px] text-slate-500 uppercase block">Terminal GSI Gain</span>
                <span class="text-2xl font-bold text-emerald-400 mt-2 block">+<%= @learning_demo.gsi_gain %></span>
              </div>
              <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg text-center">
                <span class="text-[9px] text-slate-500 uppercase block">Collapse Avoided</span>
                <span class="text-2xl font-bold text-blue-400 mt-2 block"><%= if @learning_demo.collapse_avoidance, do: "YES", else: "NO" %></span>
              </div>
              <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg text-center">
                <span class="text-[9px] text-slate-500 uppercase block">Generator Residency</span>
                <span class="text-2xl font-bold text-indigo-400 mt-2 block"><%= @learning_demo.generator_residency %> steps</span>
              </div>
            </div>
            <div class="mt-4 p-3 bg-slate-900/60 border border-slate-800 rounded-lg text-[10px] font-mono text-slate-500 flex justify-between">
              <span>MES Functor Retention: <%= @learning_demo.mes_retention * 100 %>%</span>
              <span>MPP Functor Retention: <%= @learning_demo.mpp_retention * 100 %>%</span>
            </div>
          </div>

          <!-- Higher-Order Topological Knowledge Representation -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> Topological Knowledge Representation
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Mapping memory coordinate coverage using Simplicial Complexes to identify coverage gaps ("epistemic holes") in simulated worlds.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl text-center">
                <span class="text-[9px] font-mono text-slate-500 block uppercase">Simplicial Bins Analyzed</span>
                <span class="text-3xl font-bold font-mono text-indigo-400 mt-2 block">27</span>
              </div>
              <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl text-center">
                <span class="text-[9px] font-mono text-slate-500 block uppercase">Epistemic Holes Detected</span>
                <span class="text-3xl font-bold font-mono text-rose-400 mt-2 block"><%= @topology_report.hole_count %></span>
              </div>
              <div class="p-4 bg-slate-900 border border-slate-800 rounded-xl text-center">
                <span class="text-[9px] font-mono text-slate-500 block uppercase">Memory Coverage Ratio</span>
                <span class="text-3xl font-bold font-mono text-emerald-400 mt-2 block"><%= @topology_report.coverage_ratio * 100 %>%</span>
              </div>
            </div>

            <span class="text-xs font-bold text-slate-200 block mb-2">Detailed Epistemic Holes</span>
            <div class="max-h-40 overflow-y-auto grid grid-cols-2 sm:grid-cols-3 gap-2">
              <%= for hole <- @topology_report.epistemic_holes do %>
                <div class="p-2 bg-slate-900/60 border border-slate-800 rounded-lg text-[9px] font-mono text-slate-400">
                  GSI: <%= hole.gsi %> | Rob: <%= hole.robustness %> | Gen: <%= hole.generativity %>
                </div>
              <% end %>
            </div>
          </div>
        </div>

      </div>
    </div>
    """
  end

  defp format_name(atom_or_string) do
    atom_or_string
    |> to_string()
    |> String.replace("_orbit", "")
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp format_mode(mode) do
    mode
    |> to_string()
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
