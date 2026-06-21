defmodule TiannaraWeb.UnifiedImmuneLive do
  @moduledoc """
  Interactive Unified Cognitive Immune System Dashboard.
  Provides controls for injecting pathogens, registering cures (vaccination),
  running mutation cycles, tracking strategy evolution, and monitoring security stress.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.Epistemic.{
    PathogenRegistry,
    VaccineRegistry,
    QuarantineManager,
    ImmuneMemoryEcology,
    UnifiedImmuneSystem
  }
  alias Tiannara.REA.TheorySelection

  def mount(_params, _session, socket) do
    # Ensure all registries are started (for development/demo purposes)
    ensure_started(PathogenRegistry)
    ensure_started(VaccineRegistry)
    ensure_started(QuarantineManager)
    ensure_started(ImmuneMemoryEcology)
    ensure_started(UnifiedImmuneSystem)

    theories = TheorySelection.load_theories()
    theory_ids = Enum.map(theories, & &1.theory_id)

    # Initial load of state
    {:ok, assign_immune_state(socket, theory_ids, nil)}
  end

  def handle_event("inject_pathogen", %{"pathogen" => path_str, "target_type" => type_str, "target" => target_str}, socket) do
    pathogen_id = String.to_existing_atom(path_str)
    target_type = String.to_existing_atom(type_str)
    target_id = String.to_existing_atom(target_str)

    # Make the pathogen active in registry
    PathogenRegistry.update_status(pathogen_id, :active)

    # Let the immune system triage the pathogen threat
    {:ok, severity} = UnifiedImmuneSystem.handle_pathogen_threat(pathogen_id, %{
      target_type: target_type,
      target_id: target_id,
      epoch: socket.assigns.epoch
    })

    # Record infection trace
    trace = "🚨 Threat detected: #{pathogen_id} on #{type_str} '#{target_str}'. Triaged to #{String.upcase(to_string(severity))} severity."
    new_traces = [trace | socket.assigns.esg_traces] |> Enum.take(10)

    # If severity is outbreak or pandemic, quarantine target
    message = "Pathogen #{pathogen_id} injected. Immune severity scaled to #{String.capitalize(to_string(severity))}."

    # Update strategy fitness dynamically
    ImmuneMemoryEcology.evaluate_fitness(%{
      epoch: socket.assigns.epoch,
      active_pathogen_family: pathogen_id,
      threat_resolved: false,
      resolution_time: 12.5,
      yield_drop: 0.15,
      cfr: 0.2,
      false_positives: 0.0
    })

    {:noreply,
     socket
     |> assign_immune_state(socket.assigns.theory_ids, message)
     |> assign(esg_traces: new_traces)}
  end

  def handle_event("cure_pathogen", %{"pathogen_id" => path_str}, socket) do
    pathogen_id = String.to_existing_atom(path_str)
    
    case PathogenRegistry.get_pathogen(pathogen_id) do
      nil ->
        {:noreply, socket}

      pathogen ->
        # 1. Register cure (creates vaccine)
        VaccineRegistry.register_cure(pathogen_id, pathogen.signature, socket.assigns.epoch)

        # 2. Update status in pathogen registry
        PathogenRegistry.update_status(pathogen_id, :cured)

        # 3. Lift quarantined entity if applicable
        # Lift any quarantines matching the cured pathogen
        quars = QuarantineManager.get_quarantines()
        
        Enum.each(quars.theories, fn {tid, details} ->
          if String.contains?(details.reason, to_string(pathogen_id)), do: QuarantineManager.lift_quarantine(tid)
        end)
        Enum.each(quars.shards, fn {sid, details} ->
          if String.contains?(details.reason, to_string(pathogen_id)), do: QuarantineManager.lift_quarantine(sid)
        end)

        # 4. Trigger Strategy Fitness evolution
        ImmuneMemoryEcology.evaluate_fitness(%{
          epoch: socket.assigns.epoch,
          active_pathogen_family: pathogen_id,
          threat_resolved: true,
          resolution_time: 4.2,
          yield_drop: 0.0,
          cfr: 0.0,
          false_positives: 0.0
        })

        trace = "✅ Cure registered for #{pathogen_id}. Adaptive vaccine generated. Efficacy: 1.0."
        new_traces = [trace | socket.assigns.esg_traces] |> Enum.take(10)

        {:noreply,
         socket
         |> assign_immune_state(socket.assigns.theory_ids, "Pathogen #{pathogen_id} successfully cured and vaccinated.")
         |> assign(esg_traces: new_traces)}
    end
  end

  def handle_event("mutate_pathogens", _params, socket) do
    {:ok, rt} = PathogenRegistry.mutate_all()
    message = "Mutation cycle executed. Current Pathogen Rt: #{Float.round(rt, 4)}."

    trace = "🧬 Pathogen mutations completed. Pathogen Rt scaled to #{Float.round(rt, 4)}."
    new_traces = [trace | socket.assigns.esg_traces] |> Enum.take(10)

    {:noreply,
     socket
     |> assign_immune_state(socket.assigns.theory_ids, message)
     |> assign(esg_traces: new_traces)}
  end

  def handle_event("run_simulation_tick", _params, socket) do
    # Increment epoch
    new_epoch = socket.assigns.epoch + 1

    # Apply Immune Drift decay (Law P5)
    ImmuneMemoryEcology.apply_drift_decay(new_epoch)
    VaccineRegistry.decay_efficacy(0.02)

    # Mutate active pathogens
    {:ok, rt} = PathogenRegistry.mutate_all()

    trace = "⏳ Simulation advanced to Epoch #{new_epoch}. Pathogen Rt: #{Float.round(rt, 4)}."
    new_traces = [trace | socket.assigns.esg_traces] |> Enum.take(10)

    {:noreply,
     socket
     |> assign_immune_state(socket.assigns.theory_ids, "Simulation advanced one epoch.")
     |> assign(epoch: new_epoch, esg_traces: new_traces)}
  end

  def handle_event("reset_system", _params, socket) do
    PathogenRegistry.reset()
    VaccineRegistry.reset()
    QuarantineManager.reset()
    ImmuneMemoryEcology.reset()
    UnifiedImmuneSystem.reset()

    trace = "🔄 Unified Immune registries reset to default baselines."
    
    {:noreply,
     socket
     |> assign_immune_state(socket.assigns.theory_ids, "System reset successfully.")
     |> assign(epoch: 0, esg_traces: [trace])}
  end

  defp assign_immune_state(socket, theory_ids, message) do
    # Run threat evaluation to update health metrics
    dummy_snapshot = %{epoch: socket.assigns[:epoch] || 0}
    sys_eval = UnifiedImmuneSystem.evaluate_threats(dummy_snapshot)

    active_pathogens = PathogenRegistry.active_pathogens()
    all_pathogens = PathogenRegistry.all_pathogens()
    vaccines = VaccineRegistry.get_vaccines()
    quarantines = QuarantineManager.get_quarantines()
    strategies = ImmuneMemoryEcology.get_strategies()
    memories = ImmuneMemoryEcology.get_memories()
    pathogen_rt = PathogenRegistry.get_pathogen_rt()

    assign(socket,
      theory_ids: theory_ids,
      active_pathogens: active_pathogens,
      all_pathogens: all_pathogens,
      vaccines: vaccines,
      quarantines: quarantines,
      strategies: strategies,
      memories: memories,
      security_stress: sys_eval.security_stress,
      severity: sys_eval.severity,
      active_strategy: sys_eval.active_strategy,
      pathogen_rt: pathogen_rt,
      epoch: socket.assigns[:epoch] || 0,
      esg_traces: socket.assigns[:esg_traces] || ["🛡️ Unified Cognitive Immune System initialized."],
      message: message
    )
  end

  defp ensure_started(module) do
    if Code.ensure_loaded?(module) and !Process.whereis(module) do
      module.start_link()
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Phase 11.19</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Constitutional Control Stack</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Unified Cognitive Immune System</h1>
          <p class="text-sm text-slate-400 mt-1">Evolving immune memory, severity-based escalation, vaccine registration, and dynamic pathogen mutation modeling.</p>
        </div>
        
        <div class="flex gap-2">
          <button phx-click="run_simulation_tick" class="px-4 py-2 bg-indigo-500 text-slate-950 font-bold hover:bg-indigo-600 rounded-lg text-xs font-mono transition-all">
            Advance Simulation Tick
          </button>
          <button phx-click="reset_system" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:bg-slate-800 text-slate-400 rounded-lg text-xs font-mono transition-all">
            Reset System
          </button>
        </div>
      </div>

      <%= if @message do %>
        <div class="p-3 bg-indigo-500/10 border border-indigo-500/20 rounded-lg text-xs font-mono text-indigo-400 animate-pulse">
          <%= @message %>
        </div>
      <% end %>

      <!-- Top Overview Panel: Security Stress & Severity -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
        
        <!-- Security Stress Gauge -->
        <div class="glass-card p-6 bg-indigo-500/5 border-indigo-500/10 flex flex-col items-center justify-center text-center">
          <span class="text-[10px] font-mono text-slate-500 uppercase">Derived Security Stress</span>
          <div class="text-4xl font-black text-indigo-400 font-heading mt-2">
            <%= Float.round(@security_stress, 4) %>
          </div>
          <div class="w-full bg-slate-950 h-1.5 rounded-full mt-3 overflow-hidden">
            <div class="h-full bg-indigo-500 transition-all" style={"width: " <> to_string(round(@security_stress * 100)) <> "%"}></div>
          </div>
        </div>

        <!-- Severity Level -->
        <div class="glass-card p-6 bg-rose-500/5 border-rose-500/10 flex flex-col items-center justify-center text-center">
          <span class="text-[10px] font-mono text-slate-500 uppercase">Immune Severity Level</span>
          <div class={"text-2xl font-extrabold uppercase mt-3 font-heading " <> (if @severity in [:pandemic, :constitutional], do: "text-rose-400 animate-pulse", else: "text-slate-200")}>
            <%= @severity %>
          </div>
          <span class="text-[9px] text-slate-400 font-mono mt-2 uppercase">Active Trigger</span>
        </div>

        <!-- Pathogen Rt -->
        <div class="glass-card p-6 flex flex-col items-center justify-center text-center">
          <span class="text-[10px] font-mono text-slate-500 uppercase">Pathogen Reproduction (Rt)</span>
          <div class="text-3xl font-extrabold text-slate-200 mt-2">
            <%= Float.round(@pathogen_rt, 2) %>
          </div>
          <span class="text-[9px] text-slate-400 font-mono mt-2 uppercase">Viral Transmission Velocity</span>
        </div>

        <!-- Active Immune Strategy -->
        <div class="glass-card p-6 flex flex-col items-center justify-center text-center">
          <span class="text-[10px] font-mono text-slate-500 uppercase">Active Strategy Evolved</span>
          <div class="text-lg font-bold text-slate-200 uppercase mt-3">
            <%= @active_strategy |> to_string() |> String.replace("_", " ") %>
          </div>
          <span class="text-[9px] text-slate-400 font-mono mt-2 uppercase">Niche-Optimized</span>
        </div>

      </div>

      <!-- Main Columns -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Column 1: Pathogen Registry & Injector -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Threat Injector -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-rose-500"></span> Threat Injection Room
            </h2>
            <form phx-submit="inject_pathogen" class="flex flex-col gap-4 font-mono text-xs">
              <div>
                <label class="block text-slate-400 uppercase text-[10px] mb-2">Select Pathogen</label>
                <select name="pathogen" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-indigo-500">
                  <%= for p <- @all_pathogens do %>
                    <option value={to_string(p.id)}><%= to_string(p.id) |> String.replace("_", " ") |> String.capitalize() %></option>
                  <% end %>
                </select>
              </div>

              <div>
                <label class="block text-slate-400 uppercase text-[10px] mb-2">Target Type</label>
                <select name="target_type" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-indigo-500">
                  <option value="theory">Theory Species</option>
                  <option value="shard">Civilization Shard</option>
                  <option value="civilization">Civilization Core</option>
                </select>
              </div>

              <div>
                <label class="block text-slate-400 uppercase text-[10px] mb-2">Target Name/ID</label>
                <select name="target" class="bg-slate-900 border border-slate-800 text-slate-200 text-xs rounded-lg p-2.5 outline-none w-full focus:border-indigo-500">
                  <%= for tid <- @theory_ids do %>
                    <option value={to_string(tid)}><%= to_string(tid) %></option>
                  <% end %>
                </select>
              </div>

              <button type="submit" class="w-full py-2.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/30 hover:border-rose-500/50 rounded-lg text-center font-bold font-mono transition-all">
                Inject Pathogen
              </button>
            </form>
          </div>

          <!-- Active Pathogens list -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-rose-500"></span> Active Pathogen Registry
            </h2>
            <div class="overflow-y-auto max-h-60 flex flex-col gap-3 font-mono text-xs text-slate-400">
              <%= for p <- @active_pathogens do %>
                <div class="p-3 bg-slate-900/60 border border-slate-800/40 rounded-lg flex flex-col gap-2">
                  <div class="flex justify-between items-center">
                    <span class="text-rose-400 font-bold text-[11px]"><%= p.id %></span>
                    <span class="text-[9px] text-slate-500">Gen: <%= p.generation %></span>
                  </div>
                  <div class="text-[10px] text-slate-300">
                    <div>Type: <%= p.type %></div>
                    <div>Virulence: <%= p.virulence %></div>
                  </div>
                  <button phx-click="cure_pathogen" phx-value-pathogen_id={to_string(p.id)} class="mt-1 px-3 py-1 bg-emerald-500 text-slate-950 font-bold rounded text-[10px] transition-all hover:bg-emerald-600">
                    Register Cure & Vaccinate
                  </button>
                </div>
              <% end %>
              <%= if @active_pathogens == [] do %>
                <div class="py-6 text-center text-slate-500">No active pathogens detected. Epistemic ecosystem is healthy.</div>
              <% end %>
            </div>
          </div>

        </div>

        <!-- Column 2: Vaccines & Quarantines -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Vaccine Efficacy Monitor -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-emerald-500"></span> Vaccine Registry (Immunological Memory)
            </h2>
            <div class="overflow-y-auto max-h-60 flex flex-col gap-3 font-mono text-xs text-slate-400">
              <%= for v <- @vaccines do %>
                <div class="p-3 bg-slate-900/60 border border-slate-800/40 rounded-lg flex flex-col gap-1.5">
                  <div class="flex justify-between items-center">
                    <span class="text-emerald-400 font-bold"><%= v.pathogen_id %></span>
                    <span class="text-indigo-400 font-bold">Efficacy: <%= Float.round(v.efficacy * 100, 1) %>%</span>
                  </div>
                  <div class="text-[9px] text-slate-500">Registered at Epoch <%= v.epoch_created %> (subject to P5 Immune Drift)</div>
                  <div class="w-full bg-slate-950 h-1 rounded-full overflow-hidden mt-1">
                    <div class="h-full bg-emerald-500 transition-all" style={"width: " <> to_string(round(v.efficacy * 100)) <> "%"}></div>
                  </div>
                </div>
              <% end %>
              <%= if @vaccines == [] do %>
                <div class="py-6 text-center text-slate-500 font-mono">No vaccine records registered. Cure pathogens to produce vaccines.</div>
              <% end %>
            </div>
          </div>

          <!-- Quarantine Control Room -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-purple-500"></span> Quarantine Control Room
            </h2>
            <div class="overflow-y-auto max-h-60 flex flex-col gap-3 font-mono text-xs text-slate-400">
              <!-- Quarantined Theories -->
              <%= for {tid, details} <- @quarantines.theories do %>
                <div class="p-3 bg-purple-950/20 border border-purple-500/20 rounded-lg flex flex-col gap-1">
                  <div class="flex justify-between items-center text-[10px]">
                    <span class="text-purple-300 font-bold">THEORY: <%= tid %></span>
                    <button phx-click="cure_pathogen" phx-value-pathogen_id={to_string(tid)} class="text-[9px] hover:text-white text-purple-400">Lift</button>
                  </div>
                  <div class="text-[10px] text-slate-300"><%= details.reason %></div>
                </div>
              <% end %>
              <!-- Quarantined Shards -->
              <%= for {sid, details} <- @quarantines.shards do %>
                <div class="p-3 bg-purple-950/20 border border-purple-500/20 rounded-lg flex flex-col gap-1">
                  <div class="flex justify-between items-center text-[10px]">
                    <span class="text-purple-300 font-bold">SHARD: <%= sid %></span>
                  </div>
                  <div class="text-[10px] text-slate-300"><%= details.reason %></div>
                </div>
              <% end %>
              <%= if Map.keys(@quarantines.theories) == [] and Map.keys(@quarantines.shards) == [] do %>
                <div class="py-6 text-center text-slate-500 font-mono">No entities currently quarantined. Shards and theories are operating normally.</div>
              <% end %>
            </div>
          </div>

        </div>

        <!-- Column 3: Immune Strategy & ESG Tracer -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          
          <!-- Immune Strategy Selection & Fitness -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Immune Memory & Strategy Weights
            </h2>
            <div class="flex flex-col gap-4 font-mono text-xs text-slate-300">
              <%= for strat <- @strategies do %>
                <div class="flex flex-col gap-1.5 border-b border-slate-800/20 pb-3 last:border-0 last:pb-0">
                  <div class="flex justify-between items-center text-[10px]">
                    <span class="font-bold text-slate-200 uppercase"><%= strat.name %></span>
                    <span class="text-indigo-400 font-bold">Fitness: <%= Float.round(strat.fitness, 3) %></span>
                  </div>
                  <div class="flex justify-between text-[9px] text-slate-500">
                    <span>Quar Threshold: <%= strat.quarantine_threshold %></span>
                    <span>Rebalance: <%= strat.rebalance_intensity %></span>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- ESG Dry-run Anomaly Tracer -->
          <div class="glass-card p-6">
            <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-slate-500"></span> ESG Shadow Simulation Tracer
            </h2>
            <div class="overflow-y-auto max-h-64 flex flex-col gap-2 font-mono text-[10px] text-slate-400 leading-tight">
              <%= for trace <- @esg_traces do %>
                <div class="p-2.5 bg-slate-900 border-l-2 border-slate-700 text-slate-300 rounded-r">
                  <%= trace %>
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
