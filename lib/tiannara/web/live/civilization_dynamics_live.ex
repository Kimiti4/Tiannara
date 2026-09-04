defmodule TiannaraWeb.CivilizationDynamicsLive do
  @moduledoc """
  Interactive Dashboard for Phase 11.20 - Autonomous Research Civilization (ARC).
  Visualizes Research Economy, Goal Ecology, Institution Speciation, and Civilization Memory.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.ResearchEconomy
  alias Tiannara.REA.Epistemic.{
    Goal,
    GoalRegistry,
    GoalEcology,
    InstitutionRegistry,
    InstitutionEcology,
    CivilizationMemory
  }

  def mount(_params, _session, socket) do
    ensure_started(ResearchEconomy)
    ensure_started(GoalRegistry)
    ensure_started(InstitutionRegistry)
    ensure_started(CivilizationMemory)

    # Initial context setup
    volatility = 0.50
    complexity = 0.50
    adversariality = 0.40
    security_pressure = 0.30

    socket =
      socket
      |> assign(
        volatility: volatility,
        complexity: complexity,
        adversariality: adversariality,
        security_pressure: security_pressure,
        epoch: 0,
        message: nil
      )
      |> assign_telemetry()

    {:ok, socket}
  end

  def handle_event("update_parameters", %{"volatility" => vol, "complexity" => comp, "adversariality" => adv, "security_pressure" => sec}, socket) do
    {:noreply,
     socket
     |> assign(
       volatility: String.to_float(vol),
       complexity: String.to_float(comp),
       adversariality: String.to_float(adv),
       security_pressure: String.to_float(sec)
     )
     |> assign_telemetry()}
  end

  def handle_event("step_simulation", _params, socket) do
    epoch = socket.assigns.epoch + 1
    env_context = %{
      volatility: socket.assigns.volatility,
      complexity: socket.assigns.complexity,
      adversariality: socket.assigns.adversariality,
      security_pressure: socket.assigns.security_pressure
    }

    # Step Research Economy, Goal Ecology, and Institution Ecology
    ResearchEconomy.tick()
    GoalEcology.tick(epoch, env_context)
    InstitutionEcology.tick(epoch, env_context)

    # Calculate CDI and TMI
    cdi = calculate_cdi()
    tmi = calculate_tmi()

    # Periodic milestone logging
    if rem(epoch, 5) == 0 do
      CivilizationMemory.log_event(
        :scientific_revolution,
        epoch,
        "ARC Epoch Completed",
        "Epoch #{epoch} simulation ticked. CDI: #{cdi}, TMI: #{tmi}."
      )
    end

    {:noreply,
     socket
     |> assign(epoch: epoch, message: "Simulation advanced to epoch #{epoch}.")
     |> assign_telemetry()}
  end

  def handle_event("propose_goal", %{"domain" => domain_str}, socket) do
    domain = String.to_existing_atom(domain_str)
    id = String.to_atom("goal_user_#{domain}_#{System.unique_integer([:positive])}")

    goal = %Goal{
      id: id,
      target_domain: domain,
      focus_coordinates: %{
        volatility: socket.assigns.volatility,
        complexity: socket.assigns.complexity,
        adversariality: socket.assigns.adversariality,
        security_pressure: socket.assigns.security_pressure
      },
      expected_information_gain: Float.round(:rand.uniform() * 0.8 + 0.1, 4),
      priority_weight: 1.5,
      generation: 1,
      status: :active,
      created_at_epoch: socket.assigns.epoch
    }

    GoalRegistry.register_goal(goal)
    CivilizationMemory.log_event(
      :major_discovery,
      socket.assigns.epoch,
      "New Goal Proposed",
      "Goal proposed for domain: #{String.capitalize(domain_str)} with priority 1.5."
    )

    {:noreply,
     socket
     |> assign(message: "Goal proposed successfully for #{String.capitalize(domain_str)}.")
     |> assign_telemetry()}
  end

  def handle_event("trigger_split", %{"id" => inst_id_str}, socket) do
    inst_id = String.to_existing_atom(inst_id_str)
    insts = InstitutionRegistry.get_institutions()

    case Enum.find(insts, &(&1.id == inst_id)) do
      nil ->
        {:noreply, assign(socket, message: "Institution not found.")}

      inst ->
        # Split requires credits >= 500, let's set it if not met to force split
        updated_inst = %{inst | credits_held: max(inst.credits_held, 550.0)}
        InstitutionRegistry.set_institutions([updated_inst | Enum.reject(insts, &(&1.id == inst_id))])
        
        # Trigger ecology split
        env_context = %{
          volatility: socket.assigns.volatility,
          complexity: socket.assigns.complexity,
          adversariality: socket.assigns.adversariality,
          security_pressure: socket.assigns.security_pressure
        }
        InstitutionEcology.tick(socket.assigns.epoch, env_context)

        CivilizationMemory.log_event(
          :scientific_revolution,
          socket.assigns.epoch,
          "Forced Institution Split",
          "Institution split manually triggered for: #{inst.name}."
        )

        {:noreply,
         socket
         |> assign(message: "Forced split completed for #{inst.name}.")
         |> assign_telemetry()}
    end
  end

  def handle_event("reset_simulation", _params, socket) do
    ResearchEconomy.reset()
    GoalRegistry.reset()
    InstitutionRegistry.reset()
    CivilizationMemory.reset()

    {:noreply,
     socket
     |> assign(epoch: 0, message: "Simulation state successfully reset.")
     |> assign_telemetry()}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Phase 11.20</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono font-heading">Autonomous Research Civilization Substrate</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Civilization Dynamics & Speciation</h1>
          <p class="text-sm text-slate-400 mt-1">Evolving institutional culture, managing research goal ecology, and enforcing L0 Historical Conservation.</p>
        </div>
        <div class="flex gap-2">
          <button phx-click="step_simulation" class="px-4 py-2 bg-indigo-500 hover:bg-indigo-600 text-slate-950 font-bold rounded-lg text-xs font-mono transition-all">
            Tick Simulation Step
          </button>
          <button phx-click="reset_simulation" class="px-4 py-2 bg-slate-900 border border-slate-800 hover:border-slate-700 text-slate-300 rounded-lg text-xs font-semibold font-mono transition-all">
            Reset State
          </button>
        </div>
      </div>

      <%= if @message do %>
        <div class="p-3 bg-indigo-500/10 border border-indigo-500/20 rounded-lg text-xs font-mono text-indigo-400 animate-pulse">
          <%= @message %>
        </div>
      <% end %>

      <!-- Metrics and Sweepers Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Sweeper Sliders -->
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
              <label class="block mb-2 text-slate-400 uppercase text-[10px]">Security Pressure</label>
              <input type="range" name="security_pressure" min="0.0" max="1.0" step="0.05" value={@security_pressure} class="w-full accent-indigo-500" />
              <output class="text-indigo-400 block mt-1 text-right"><%= @security_pressure %></output>
            </div>
          </form>
        </div>

        <!-- Research Economy States -->
        <div class="glass-card p-6 lg:col-span-1">
          <h2 class="text-lg font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
            <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Research Economy Pool
          </h2>
          <div class="grid grid-cols-2 gap-4 font-mono text-xs">
            <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-xl">
              <span class="text-slate-500 uppercase text-[9px]">Compute</span>
              <div class="text-slate-200 font-bold mt-0.5"><%= @economy.compute %> / 100.0</div>
            </div>
            <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-xl">
              <span class="text-slate-500 uppercase text-[9px]">Attention</span>
              <div class="text-slate-200 font-bold mt-0.5"><%= @economy.attention %> / 100.0</div>
            </div>
            <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-xl">
              <span class="text-slate-500 uppercase text-[9px]">Total Credits</span>
              <div class="text-slate-200 font-bold mt-0.5"><%= Float.round(@economy.credits, 2) %></div>
            </div>
            <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-xl">
              <span class="text-slate-500 uppercase text-[9px]">Simulation Age</span>
              <div class="text-slate-200 font-bold mt-0.5"><%= @economy.time %> Epochs</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Dashboards Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Left: Goals & Institutions -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          
          <!-- Institutions Speciation Board -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded bg-emerald-500"></span> Active Organs & Institutions
              </div>
              <div class="text-xs text-slate-400 font-mono">
                CDI: <span class="text-emerald-400 font-bold"><%= @cdi %></span> |
                TMI: <span class="text-indigo-400 font-bold"><%= @tmi %></span>
              </div>
            </h2>

            <div class="flex flex-col gap-4 font-mono text-xs text-slate-300">
              <%= for inst <- @institutions do %>
                <div class="p-4 bg-slate-900/40 border border-slate-800/60 rounded-xl flex flex-col gap-3">
                  <div class="flex justify-between items-start">
                    <div>
                      <div class="flex items-center gap-2">
                        <span class="font-bold text-slate-100"><%= inst.name %></span>
                        <span class={"px-1.5 py-0.5 text-[9px] rounded font-bold uppercase " <> (if inst.type == :constitutional, do: "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20", else: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20")}>
                          <%= inst.type %>
                        </span>
                      </div>
                      <span class="text-[10px] text-slate-500 block mt-0.5">Focus: <%= String.capitalize(to_string(inst.focus_domain)) %> | Age: <%= inst.age %> | Fitness: <%= inst.fitness %></span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="text-[10px] text-slate-400">Share: <%= Float.round(inst.compute_share * 100, 1) %>%</span>
                      <%= if inst.type == :evolvable do %>
                        <button phx-click="trigger_split" phx-value-id={to_string(inst.id)} class="px-2.5 py-1 bg-indigo-500/10 hover:bg-indigo-500/20 text-indigo-400 border border-indigo-500/20 rounded text-[9px] font-bold">
                          FORCE SPLIT
                        </button>
                      <% end %>
                    </div>
                  </div>

                  <!-- Culture Biases Bar Gauges -->
                  <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-[10px]">
                    <div>
                      <span class="text-slate-500 uppercase text-[9px] block">Exploration</span>
                      <div class="w-full bg-slate-950 h-1.5 rounded-full mt-1 overflow-hidden">
                        <div class="bg-indigo-500 h-full" style={"width: " <> to_string(round(inst.culture.exploration_bias * 100)) <> "%"}></div>
                      </div>
                    </div>
                    <div>
                      <span class="text-slate-500 uppercase text-[9px] block">Risk Tolerance</span>
                      <div class="w-full bg-slate-950 h-1.5 rounded-full mt-1 overflow-hidden">
                        <div class="bg-amber-500 h-full" style={"width: " <> to_string(round(inst.culture.risk_tolerance * 100)) <> "%"}></div>
                      </div>
                    </div>
                    <div>
                      <span class="text-slate-500 uppercase text-[9px] block">Collaboration</span>
                      <div class="w-full bg-slate-950 h-1.5 rounded-full mt-1 overflow-hidden">
                        <div class="bg-emerald-500 h-full" style={"width: " <> to_string(round(inst.culture.collaboration_bias * 100)) <> "%"}></div>
                      </div>
                    </div>
                    <div>
                      <span class="text-slate-500 uppercase text-[9px] block">Security Bias</span>
                      <div class="w-full bg-slate-950 h-1.5 rounded-full mt-1 overflow-hidden">
                        <div class="bg-rose-500 h-full" style={"width: " <> to_string(round(inst.culture.security_bias * 100)) <> "%"}></div>
                      </div>
                    </div>
                  </div>

                  <!-- Local Institution Memory Tooltip-friendly details -->
                  <div class="p-2.5 bg-slate-950/40 rounded-lg text-[10px] text-slate-400 flex flex-col gap-1">
                    <span class="text-slate-500 font-bold">Institution Memory Ledger:</span>
                    <div class="flex justify-between">
                      <span>Successful Projects: <%= length(inst.memory.successful_projects) %></span>
                      <span>Failed Projects: <%= length(inst.memory.failed_projects) %></span>
                      <span>Theories Validated: <%= length(inst.memory.discovered_theories) %></span>
                      <span>Crises Survived: <%= inst.memory.crises_survived %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Goal Ecology Dashboard -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="w-2.5 h-2.5 rounded bg-indigo-500"></span> Active Research Goal Ecology
              </div>
            </h2>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 font-mono text-xs">
              <%= for goal <- @goals do %>
                <div class="p-3 bg-slate-900/60 border border-slate-800 rounded-xl flex flex-col gap-2">
                  <div class="flex justify-between items-center">
                    <span class="font-bold text-slate-200"><%= goal.id %></span>
                    <span class="px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 text-[9px] uppercase"><%= goal.target_domain %></span>
                  </div>
                  <div class="flex justify-between text-[10px] text-slate-400">
                    <span>EIG: <%= goal.expected_information_gain %></span>
                    <span>Priority: <%= goal.priority_weight %></span>
                    <span>Gen: <%= goal.generation %></span>
                  </div>
                  <div class="text-[9px] text-slate-500">
                    Coordinates: V: <%= Float.round(goal.focus_coordinates.volatility, 2) %> | C: <%= Float.round(goal.focus_coordinates.complexity, 2) %> | A: <%= Float.round(goal.focus_coordinates.adversariality, 2) %>
                  </div>
                </div>
              <% end %>
              <%= if @goals == [] do %>
                <div class="col-span-2 py-6 text-center text-slate-500">No active goals registered in dynamic ecology.</div>
              <% end %>
            </div>

            <!-- Propose Custom Goal Selector -->
            <div class="mt-6 border-t border-slate-800/40 pt-4 flex flex-col md:flex-row gap-4 items-center font-mono text-xs">
              <span class="text-slate-400">Inject Goal Proposal:</span>
              <form phx-submit="propose_goal" class="flex gap-2 w-full md:w-auto">
                <select name="domain" class="bg-slate-900 border border-slate-850 text-slate-200 rounded-lg px-3 py-2 outline-none">
                  <%= for dom <- list_domains() do %>
                    <option value={to_string(dom)}><%= String.capitalize(to_string(dom)) %></option>
                  <% end %>
                </select>
                <button type="submit" class="px-4 py-2 bg-indigo-500 text-slate-950 font-bold hover:bg-indigo-600 rounded-lg text-xs font-mono transition-all">
                  PROPOSE
                </button>
              </form>
            </div>

          </div>

        </div>

        <!-- Right: Civilization Memory Scroll -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          <div class="glass-card p-6 flex-1 flex flex-col h-full">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-2 flex items-center gap-2">
              <span class="w-2.5 h-2.5 rounded bg-purple-500"></span> Civilization Memory
            </h2>
            <p class="text-[10px] text-slate-500 uppercase tracking-wider font-mono">Rule ARC1 Invariant: Ledger survives rollbacks</p>

            <div class="overflow-y-auto max-h-[500px] flex flex-col gap-3 font-mono text-xs text-slate-400 mt-4 flex-1">
              <%= for ev <- Enum.reverse(@events) do %>
                <div class={"p-3 bg-slate-900/60 border rounded-lg flex flex-col gap-1.5 " <> (if ev.type in [:major_discovery, :scientific_revolution], do: "border-emerald-500/10 text-slate-300", else: "border-rose-500/10 text-slate-300")}>
                  <div class="flex justify-between items-center text-[10px]">
                    <span class={"font-bold uppercase " <> (if ev.type in [:major_discovery, :scientific_revolution], do: "text-emerald-400", else: "text-rose-400")}>
                      <%= ev.type %>
                    </span>
                    <span class="text-[9px] text-slate-500">Epoch <%= ev.epoch %></span>
                  </div>
                  <div class="text-[11px] font-bold text-slate-200"><%= ev.title %></div>
                  <p class="text-slate-400 text-[10px] leading-relaxed"><%= ev.description %></p>
                </div>
              <% end %>
              <%= if @events == [] do %>
                <div class="py-6 text-center text-slate-500">No events logged in the Civilization Memory ledger.</div>
              <% end %>
            </div>
          </div>
        </div>

      </div>
    </div>
    """
  end

  # --- PRIVATE HELPERS ---

  defp ensure_started(module) do
    if Code.ensure_loaded?(module) and Process.whereis(module) == nil do
      module.start_link([])
    end
  end

  defp assign_telemetry(socket) do
    economy = ResearchEconomy.get_state()
    institutions = InstitutionRegistry.get_institutions()
    goals = GoalRegistry.get_goals()
    events = CivilizationMemory.get_events()

    assign(socket,
      economy: economy,
      institutions: institutions,
      goals: goals,
      events: events,
      cdi: calculate_cdi(),
      tmi: calculate_tmi()
    )
  end

  defp calculate_cdi do
    theories = if Code.ensure_loaded?(Tiannara.REA.TheorySelection), do: Tiannara.REA.TheorySelection.load_theories(), else: []
    total_pop = Enum.sum(Enum.map(theories, & &1.population))
    weights = if total_pop > 0, do: Map.new(theories, & {&1.theory_id, &1.population / total_pop}), else: %{}
    
    institutions = InstitutionRegistry.get_institutions()
    goals = GoalRegistry.get_goals()

    if Code.ensure_loaded?(Tiannara.REA.PortfolioRiskAnalyzer) do
      Tiannara.REA.PortfolioRiskAnalyzer.calculate_cdi(weights, institutions, goals)
    else
      0.5
    end
  end

  defp calculate_tmi do
    if Code.ensure_loaded?(Tiannara.REA.PortfolioRiskAnalyzer) do
      Tiannara.REA.PortfolioRiskAnalyzer.calculate_tmi([], 0.85, 0.05)
    else
      0.8
    end
  end

  defp list_domains do
    if Code.ensure_loaded?(Tiannara.Domains.CanonicalRegistry) do
      Tiannara.Domains.CanonicalRegistry.all()
    else
      [:engineering, :medicine, :governance, :computation, :agriculture, :energy, :logistics, :cognition, :materials, :robotics, :economics, :philosophy, :sociology, :linguistics, :aerospace, :ecology, :cybernetics, :architecture]
    end
  end
end
