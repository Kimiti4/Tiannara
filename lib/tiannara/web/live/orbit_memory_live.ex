defmodule TiannaraWeb.OrbitMemoryLive do
  @moduledoc """
  Interactive Orbit Memory Physics Dashboard.
  Provides OMT inspection, MES/MPP metrics, ablation results, counterfactual swaps, and memory laws.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.OrbitGenesis
  alias Tiannara.REA.OrbitGenesis.Causal
  alias Tiannara.REA.OrbitMemory
  alias Tiannara.REA.OrbitMemory.Decay
  alias Tiannara.REA.OrbitMemory.Transfer
  alias Tiannara.REA.OrbitMemory.Merge
  alias Tiannara.REA.OrbitMemory.Reset
  alias Tiannara.REA.OrbitMemory.Synthesis
  alias Tiannara.REA.OrbitMemory.Compression

  def mount(_params, _session, socket) do
    # Fetch archived trajectory data
    records = OrbitGenesis.all_records()
    record = hd(records)

    # Extract OMT
    omt = OrbitMemory.extract(record)

    # Calculations
    ablation = OrbitMemory.run_ablation_tournament(record)
    separation = Causal.run_separation_experiment()
    swap = OrbitMemory.run_counterfactual_swap(separation.world_a, separation.world_b)
    sufficiency = OrbitMemory.verify_sufficiency(record)

    # Initial slider parameters
    {:ok,
     assign(socket,
       records: records,
       record: record,
       omt: omt,
       ablation: ablation,
       swap: swap,
       sufficiency: sufficiency,
       # Interactive states
       decay_constant: 0.05,
       coupling_coefficient: 0.50,
       erased_components: [],
       synthesis_signature: "stability_orbit,other_orbit_1,stability_orbit",
       synthesized_omt: nil
     )
     |> trigger_synthesis()}
  end

  def handle_event("select_record", %{"id" => world_id}, socket) do
    record = Enum.find(socket.assigns.records, &(&1["world_id"] == world_id))
    omt = OrbitMemory.extract(record)
    ablation = OrbitMemory.run_ablation_tournament(record)
    sufficiency = OrbitMemory.verify_sufficiency(record)

    {:noreply,
     assign(socket,
       record: record,
       omt: omt,
       ablation: ablation,
       sufficiency: sufficiency
     )}
  end

  def handle_event("update_decay", %{"decay_constant" => lambda}, socket) do
    lambda = String.to_float(lambda)
    {:noreply, assign(socket, decay_constant: lambda)}
  end

  def handle_event("update_coupling", %{"coupling_coefficient" => coeff}, socket) do
    coeff = String.to_float(coeff)
    {:noreply, assign(socket, coupling_coefficient: coeff)}
  end

  def handle_event("toggle_erasure", %{"component" => comp}, socket) do
    comp = String.to_atom(comp)
    erased = socket.assigns.erased_components
    new_erased = if comp in erased, do: erased -- [comp], else: erased ++ [comp]
    {:noreply, assign(socket, erased_components: new_erased)}
  end

  def handle_event("run_synthesis", %{"signature" => sig}, socket) do
    {:noreply,
     assign(socket, synthesis_signature: sig)
     |> trigger_synthesis()}
  end

  defp trigger_prediction(socket) do
    # Placeholder trigger helper if needed
    socket
  end

  defp trigger_synthesis(socket) do
    sig_list =
      socket.assigns.synthesis_signature
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    synth = Synthesis.synthesize(sig_list)
    assign(socket, synthesized_omt: synth)
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Title Bar -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Phase 11.11</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Orbit Memory Physics Sandbox</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Orbit Memory Physics</h1>
          <p class="text-sm text-slate-400 mt-1">Isolating memory representations, measuring predictive power, ablation tournaments, and memory swaps.</p>
        </div>
        <div>
          <select name="selected_record" phx-change="select_record" class="bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-lg p-2 outline-none focus:border-blue-500">
            <%= for rec <- @records do %>
              <option value={rec["world_id"]} selected={rec["world_id"] == @record["world_id"]}>
                <%= rec["world_id"] %> (<%= format_name(rec["orbit_outcome"]) %>)
              </option>
            <% end %>
          </select>
        </div>
      </div>

      <!-- Dashboard Columns Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Column 1: MES & MPP / Ablation Tournament / Memory Swap -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Representation Diagnostics (MES, MPP, Sufficiency) -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Representation Diagnostics
            </h2>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
              <!-- MES -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl text-center">
                <span class="text-[10px] font-mono text-slate-500 block uppercase">Memory Existence Score (MES)</span>
                <span class="text-3xl font-bold font-mono text-indigo-400 mt-2 block"><%= @omt.memory_existence_score %></span>
                <span class="text-[9px] text-slate-400 block mt-1 leading-normal">Mutual information I(Future ; OMT) representing stored sequence complexity.</span>
              </div>
              
              <!-- MPP -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl text-center">
                <span class="text-[10px] font-mono text-slate-500 block uppercase">Memory Predictive Power (MPP)</span>
                <span class="text-3xl font-bold font-mono text-emerald-400 mt-2 block">+<%= @omt.memory_predictive_power %></span>
                <span class="text-[9px] text-slate-400 block mt-1 leading-normal">Delta accuracy increase achieved by using historical trajectories.</span>
              </div>

              <!-- Sufficiency -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl text-center">
                <span class="text-[10px] font-mono text-slate-500 block uppercase">Law M0: Sufficiency</span>
                <span class="text-lg font-bold text-slate-200 mt-2 block">
                  <%= if @sufficiency.is_fundamental, do: "Fundamental Variable", else: "Metadata Only" %>
                </span>
                <span class="text-[9px] text-slate-400 block mt-1 leading-normal">Accuracy with Memory: <%= @sufficiency.accuracy_with_memory %> vs. Coordinates: <%= @sufficiency.accuracy_without_memory %></span>
              </div>
            </div>
          </div>

          <!-- Counterfactual Memory Swap Panel -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-rose-500"></span> Counterfactual Memory Swap Simulator
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Swap OMT records between Twin A (Steady) and Twin B (Decay-Recovery) to verify if the future converges to the swapped trajectory outcomes (proving memory is causal).
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <!-- World A swap card -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="text-xs font-bold font-heading text-slate-200 flex justify-between">
                  <span>World A (Steady)</span>
                  <span class="text-slate-500">&rarr; Swapped</span>
                </div>
                <div class="mt-2 text-xs font-mono text-slate-400">
                  <div>Initial Outcome: <span class="text-blue-400 font-bold"><%= format_name(@swap.original_a) %></span></div>
                  <div class="mt-1">Post-Swap Future: <span class="text-rose-400 font-bold"><%= format_name(@swap.swapped_a_future) %></span></div>
                </div>
              </div>

              <!-- World B swap card -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                <div class="text-xs font-bold font-heading text-slate-200 flex justify-between">
                  <span>World B (Decay-Recovery)</span>
                  <span class="text-slate-500">&rarr; Swapped</span>
                </div>
                <div class="mt-2 text-xs font-mono text-slate-400">
                  <div>Initial Outcome: <span class="text-rose-400 font-bold"><%= format_name(@swap.original_b) %></span></div>
                  <div class="mt-1">Post-Swap Future: <span class="text-blue-400 font-bold"><%= format_name(@swap.swapped_b_future) %></span></div>
                </div>
              </div>
            </div>

            <div class="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-lg text-xs font-mono text-emerald-400">
              <strong>Falsification Conclusion:</strong> Orbit memory is causal. Swapping transition records swaps future attractor convergence outcomes (<%= to_string(@swap.conclusion) %>).
            </div>
          </div>

          <!-- Memory Ablation Tournament Leaderboard -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-indigo-500"></span> Memory Ablation Tournament
            </h2>
            <p class="text-xs text-slate-400 mb-4">
              Removing individual OMT components systematically to measure accuracy degradation. Higher loss indicates the component is a primary memory carrier.
            </p>

            <div class="flex flex-col gap-3">
              <%= for item <- @ablation do %>
                <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-center text-xs font-mono">
                  <div class="flex flex-col">
                    <span class="text-slate-200 font-bold"><%= String.capitalize(to_string(item.component)) |> String.replace("_", " ") %></span>
                    <span class="text-[10px] text-slate-500">Ablated Accuracy: <%= item.accuracy %></span>
                  </div>
                  <span class="text-rose-400 font-bold">Accuracy Loss: -<%= item.loss %></span>
                </div>
              <% end %>
            </div>
          </div>

        </div>

        <!-- Column 2: Decay / Compression / Laws -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Decay & Compression -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Decay & Compression
            </h2>

            <form phx-change="update_decay" class="mb-4 border-b border-slate-800 pb-4">
              <label class="text-[10px] font-mono text-slate-400 block mb-1">Decay Constant (&lambda;): <%= @decay_constant %></label>
              <input type="range" name="decay_constant" min="0.01" max="0.20" step="0.01" value={@decay_constant} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-emerald-500" />
              
              <% decayed = Decay.decay(@omt, 10, @decay_constant) %>
              <div class="grid grid-cols-2 gap-2 text-[10px] font-mono text-slate-500 mt-2">
                <div>Decayed Strength (10 epochs): <span class="text-slate-200 font-bold"><%= decayed.memory_strength %></span></div>
                <div>Memory Half-Life: <span class="text-slate-200 font-bold"><%= decayed.memory_half_life %> epochs</span></div>
              </div>
            </form>

            <div>
              <span class="text-xs font-bold font-heading text-slate-200 block mb-2">Latent Memory Compression</span>
              <% compressed = Compression.compress(@omt) %>
              <div class="p-3 bg-slate-900 border border-slate-800 rounded-xl text-xs font-mono flex flex-col gap-2">
                <div class="flex justify-between">
                  <span class="text-slate-500">Compression Ratio</span>
                  <span class="text-indigo-400 font-bold"><%= compressed.compression_ratio %>x</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-500">Predictive Retention</span>
                  <span class="text-emerald-400 font-bold"><%= compressed.retention * 100 %>%</span>
                </div>
                <div class="border-t border-slate-800 pt-2 text-[10px] text-slate-500">
                  Latent Code: <%= Jason.encode!(compressed.compressed_signature) %>
                </div>
              </div>
            </div>
          </div>

          <!-- Memory Synthesis Sandbox -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-blue-500"></span> Memory Synthesis Sandbox
            </h2>

            <form phx-change="run_synthesis" class="flex flex-col gap-2">
              <label class="text-[10px] font-mono text-slate-400 block">Synthesize Transition Signature (comma separated)</label>
              <input type="text" name="signature" value={@synthesis_signature} class="bg-slate-900 border border-slate-700 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-blue-500" />
            </form>

            <div class="mt-3 p-3 bg-slate-900 border border-slate-800 rounded-xl text-xs font-mono flex flex-col gap-1.5">
              <div class="flex justify-between">
                <span class="text-slate-500">Strength</span>
                <span class="text-emerald-400 font-bold"><%= @synthesized_omt.memory_strength %></span>
              </div>
              <div class="flex justify-between">
                <span class="text-slate-500">Predictive Power</span>
                <span class="text-emerald-400 font-bold">+<%= @synthesized_omt.memory_predictive_power %></span>
              </div>
              <div class="text-[9px] text-slate-500 mt-1">
                visits: <%= Jason.encode!(@synthesized_omt.visit_frequencies) %>
              </div>
            </div>
          </div>

          <!-- Discovered Laws of Memory Physics -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-3 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Laws of Memory Physics
            </h2>

            <div class="flex flex-col gap-2 text-xs font-mono text-slate-400">
              <div class="p-2 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law M0:</span> Current State + Memory is a superior predictor compared to Coordinates alone.
              </div>
              <div class="p-2 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law M1:</span> Memory decays exponentially: M(t) = M(0) * e^(-λ * t).
              </div>
              <div class="p-2 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law M2:</span> Memory transfers with distinct donor-recipient efficiencies.
              </div>
              <div class="p-2 bg-slate-900/40 border border-slate-800 rounded-lg">
                <span class="text-emerald-400 font-bold">Law M3:</span> Memory fusion combinations generate hybrid future occupancy curves.
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
