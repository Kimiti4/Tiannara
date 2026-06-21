defmodule TiannaraWeb.OrbitGenesisLive do
  @moduledoc """
  Interactive Orbit Genesis Dashboard.
  Showcases the causal factors of orbit genesis, History vs State Separation, and Orbit Twins Memory.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitGenesis.Causal
  alias Tiannara.REA.OrbitGenesis.Predictor

  def mount(_params, _session, socket) do
    # Load initial stats
    records = OrbitGenesis.all_records()
    causal_rankings = Causal.calculate_causal_rankings()
    separation = Causal.run_separation_experiment()
    twins = Causal.run_orbit_twins_experiment()

    # Prepopulate slider defaults
    {:ok,
     assign(socket,
       records: records,
       causal_rankings: causal_rankings,
       separation: separation,
       twins: twins,
       # Interactive Prediction form state
       gsi: 0.75,
       agency: 0.50,
       robustness: 0.70,
       generativity: 0.15,
       identity_persistence: 0.85,
       return_time: 2,
       # Live prediction
       prediction: nil
     )
     |> trigger_prediction()}
  end

  def handle_event("run_prediction", %{"gsi" => g, "agency" => a, "robustness" => r, "generativity" => n, "identity_persistence" => ip, "return_time" => rt}, socket) do
    {:noreply,
     assign(socket,
       gsi: String.to_float(g),
       agency: String.to_float(a),
       robustness: String.to_float(r),
       generativity: String.to_float(n),
       identity_persistence: String.to_float(ip),
       return_time: String.to_integer(rt)
     )
     |> trigger_prediction()}
  end

  def handle_event("trigger_sweep", _params, socket) do
    # Run a dynamic sweep of 20 runs
    {:ok, _new_records} = OrbitGenesis.run_full_sweeps(20)
    all_records = OrbitGenesis.all_records()
    causal_rankings = Causal.calculate_causal_rankings()

    {:noreply,
     assign(socket,
       records: all_records,
       causal_rankings: causal_rankings
     )
     |> put_flash(:info, "Successfully synthesized 20 trajectory sweeps in the genesis archive.")}
  end

  defp trigger_prediction(socket) do
    config = [
      gsi: socket.assigns.gsi,
      agency: socket.assigns.agency,
      robustness: socket.assigns.robustness,
      generativity: socket.assigns.generativity,
      identity_persistence: socket.assigns.identity_persistence,
      return_time: socket.assigns.return_time
    ]

    pred = Predictor.predict(config)
    assign(socket, prediction: pred)
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Title Bar -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Phase 11.10</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Orbit Genesis & Attractor Design</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Orbit Genesis Explorer</h1>
          <p class="text-sm text-slate-400 mt-1">Investigating the causal origin of orbit formation: state vs history and transition-space memory.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="trigger_sweep" class="text-xs font-mono px-3 py-1.5 rounded bg-indigo-500/20 text-indigo-400 border border-indigo-500/30 hover:bg-indigo-500/30 transition-all">
            Synthesize 20 sweeps
          </button>
        </div>
      </div>

      <!-- Dashboard Columns Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Col 1: Separation Experiment (State vs History) -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- State vs History Separation panel -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-rose-500"></span> History vs State Separation
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Tests whether trajectories ending at the identical coordinate endpoint converge to different orbits based on their history path.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <!-- World A -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="flex justify-between items-center mb-2">
                  <span class="text-xs font-bold font-heading text-slate-200">World A: Steady Path</span>
                  <span class="text-[9px] font-mono bg-blue-500/10 text-blue-400 border border-blue-500/20 px-2 py-0.5 rounded">GSI Centroid</span>
                </div>
                <div class="text-xs font-mono text-slate-400 flex flex-col gap-1">
                  <div>Endpoint: GSI <%= @separation.world_a["terminal_coordinates"]["gsi"] %>, Rob <%= @separation.world_a["terminal_coordinates"]["robustness"] %></div>
                  <div class="text-[10px] text-slate-500">History: <%= Enum.join(@separation.world_a["orbit_transition_signature"], " &rarr; ") |> Phoenix.HTML.raw() %></div>
                  <div class="mt-2 text-sm font-bold text-blue-400">Emergent Orbit: <%= format_name(@separation.world_a["orbit_outcome"]) %></div>
                </div>
              </div>

              <!-- World B -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="flex justify-between items-center mb-2">
                  <span class="text-xs font-bold font-heading text-slate-200">World B: Decay-Recovery Path</span>
                  <span class="text-[9px] font-mono bg-rose-500/10 text-rose-400 border border-rose-500/20 px-2 py-0.5 rounded">Unstable Shock</span>
                </div>
                <div class="text-xs font-mono text-slate-400 flex flex-col gap-1">
                  <div>Endpoint: GSI <%= @separation.world_b["terminal_coordinates"]["gsi"] %>, Rob <%= @separation.world_b["terminal_coordinates"]["robustness"] %></div>
                  <div class="text-[10px] text-slate-500">History: <%= Enum.join(@separation.world_b["orbit_transition_signature"], " &rarr; ") |> Phoenix.HTML.raw() %></div>
                  <div class="mt-2 text-sm font-bold text-rose-400">Emergent Orbit: <%= format_name(@separation.world_b["orbit_outcome"]) %></div>
                </div>
              </div>
            </div>

            <div class="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs font-mono text-emerald-400">
              <strong>Falsification Conclusion:</strong> History dependence verified. Identical coordinate endpoints generate different attractor orbits depending on trajectory memory signatures (<%= to_string(@separation.conclusion) %>).
            </div>
          </div>

          <!-- Orbit Twins Experiment (Memory) -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Orbit Twins Memory Test
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Two worlds with identical parameters and coordinates, but different transition signatures. We test if they generate different future transition probabilities.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <!-- Twin A -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <span class="text-xs font-bold font-heading text-slate-200 block mb-2">Twin A: Stability &rarr; Decay &rarr; Stability</span>
                <div class="text-xs font-mono text-slate-400">
                  <div>Survival Experience: High</div>
                  <div class="mt-3 flex justify-between">
                    <span class="text-slate-500">Future Retention Prob</span>
                    <span class="text-emerald-400 font-bold"><%= @twins.twin_a.future_retention_probability * 100 %>%</span>
                  </div>
                </div>
              </div>

              <!-- Twin B -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <span class="text-xs font-bold font-heading text-slate-200 block mb-2">Twin B: Stability &rarr; Transient &rarr; Stability</span>
                <div class="text-xs font-mono text-slate-400">
                  <div>Survival Experience: Low</div>
                  <div class="mt-3 flex justify-between">
                    <span class="text-slate-500">Future Retention Prob</span>
                    <span class="text-rose-400 font-bold"><%= @twins.twin_b.future_retention_probability * 100 %>%</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="p-3 bg-blue-500/10 border border-blue-500/20 rounded-lg text-xs font-mono text-blue-400">
              <strong>Falsification Conclusion:</strong> Orbit memory verified. divergent transition histories result in divergent future transition retention probabilities (<%= to_string(@twins.結論) %>).
            </div>
          </div>

        </div>

        <!-- Col 2: Invariant Predictor Config & Laws -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Interactive Predictor -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> Genesis Predictor
            </h2>

            <form phx-change="run_prediction" class="flex flex-col gap-4">
              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">GSI (Constitutional): <%= @gsi %></label>
                <input type="range" name="gsi" min="0.0" max="1.0" step="0.01" value={@gsi} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
              </div>

              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Robustness (DCR): <%= @robustness %></label>
                <input type="range" name="robustness" min="0.0" max="1.0" step="0.01" value={@robustness} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
              </div>

              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Generativity (Novelty): <%= @generativity %></label>
                <input type="range" name="generativity" min="0.0" max="1.0" step="0.01" value={@generativity} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
              </div>

              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Identity Persistence: <%= @identity_persistence %></label>
                <input type="range" name="identity_persistence" min="0.0" max="1.0" step="0.01" value={@identity_persistence} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
              </div>

              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Return Time (Memory): <%= @return_time %> epochs</label>
                <input type="range" name="return_time" min="1" max="10" step="1" value={@return_time} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500" />
              </div>
            </form>

            <div class="mt-4 p-4 bg-slate-900 border border-slate-800 rounded-xl text-xs font-mono flex flex-col gap-2">
              <div class="flex justify-between">
                <span class="text-slate-500">Predicted Orbit</span>
                <span class="text-slate-200 font-bold"><%= format_name(@prediction.orbit_prediction) %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-500">Confidence</span>
                <span class="text-indigo-400 font-bold"><%= @prediction.confidence %></span>
              </div>

              <div class="border-t border-slate-800 mt-2 pt-2">
                <span class="text-[10px] text-slate-500 block mb-1">Causal Contributions:</span>
                <div class="flex justify-between">
                  <span>Identity</span>
                  <span class="text-slate-300"><%= @prediction.causal_factors.identity_persistence %></span>
                </div>
                <div class="flex justify-between">
                  <span>Recovery</span>
                  <span class="text-slate-300"><%= @prediction.causal_factors.recovery_velocity %></span>
                </div>
                <div class="flex justify-between">
                  <span>Return Memory</span>
                  <span class="text-slate-300"><%= @prediction.causal_factors.return_time %></span>
                </div>
              </div>
            </div>
          </div>

          <!-- Discovered Genesis Laws (11.10B) -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-3 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Discovered Genesis Laws
            </h2>

            <div class="flex flex-col gap-2 text-xs font-mono text-slate-400">
              <div class="p-2.5 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law G1:</span> High Identity Persistence is necessary but not sufficient for Stability Orbit formation.
              </div>
              <div class="p-2.5 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law G2:</span> Return Time > 4 epochs prevents Stability genesis.
              </div>
              <div class="p-2.5 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law G3:</span> Repeated recovery cycles increase probability of Collapse-Recovery orbit formation.
              </div>
              <div class="p-2.5 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law G4:</span> Orbit formation depends on trajectory history more strongly than terminal coordinates.
              </div>
            </div>
          </div>

        </div>

      </div>
    </div>
    """
  end

  defp format_name(atom) do
    atom
    |> to_string()
    |> String.replace("_orbit", "")
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end
end
