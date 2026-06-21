defmodule TiannaraWeb.OrbitNavigationLive do
  @moduledoc """
  Interactive Orbit Navigation and Trajectory Engineering Dashboard.
  Provides Multi-Objective Planner, Gateway Centrality panels, and a Closed-Loop Simulator.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.OrbitReachabilityGraph
  alias Tiannara.REA.MultiObjectivePlanner
  alias Tiannara.REA.OrbitGatewayDetector
  alias Tiannara.REA.OrbitEnergyModel
  alias Tiannara.REA.OrbitResidency
  alias Tiannara.REA.OrbitResilience
  alias Tiannara.REA.OrbitObserver
  alias Tiannara.REA.OrbitEstimator
  alias Tiannara.REA.OrbitController

  def mount(_params, _session, socket) do
    # Load reachability graph
    {nodes, edges} = OrbitReachabilityGraph.load()

    # Default plan
    current_orbit = :collapse_recovery_orbit
    desired_orbit = :stability_orbit
    objective = :lowest_energy

    # Generate initial plan
    {:ok, plan_result} = MultiObjectivePlanner.plan(current_orbit, desired_orbit, objective)

    # Initialize Simulator State
    # Start at the centroid of the start orbit
    start_node = Enum.find(nodes, & &1.orbit_id == current_orbit)
    start_vector = start_node.orbit_vector || [0.5, 0.5, 0.5, 0.5]

    # Prepopulate custom observer fields
    [gsi, agency, rob, gen] = start_vector

    {:ok,
     assign(socket,
       nodes: nodes,
       edges: edges,
       current_orbit: current_orbit,
       desired_orbit: desired_orbit,
       objective: objective,
       plan: plan_result,
       # Simulator values
       sim_vector: start_vector,
       sim_history: [%{
         step: 0,
         vector: start_vector,
         estimation: OrbitEstimator.estimate(start_vector),
         action: "init",
         status: "Active"
       }],
       sim_step: 0,
       sim_status: :active,
       # Custom Telemetry Inputs
       tel_gsi: gsi,
       tel_agency: agency,
       tel_robustness: rob,
       tel_generativity: gen,
       tel_result: nil
     )}
  end

  def handle_event("calculate_plan", %{"current_orbit" => curr, "desired_orbit" => dest, "objective" => obj}, socket) do
    curr = String.to_atom(curr)
    dest = String.to_atom(dest)
    obj = String.to_atom(obj)

    case MultiObjectivePlanner.plan(curr, dest, obj) do
      {:ok, plan_result} ->
        # Reset simulator to new starting node centroid
        {nodes, _} = OrbitReachabilityGraph.load()
        start_node = Enum.find(nodes, & &1.orbit_id == curr)
        start_vector = start_node.orbit_vector || [0.5, 0.5, 0.5, 0.5]
        [gsi, agency, rob, gen] = start_vector

        {:noreply,
         assign(socket,
           current_orbit: curr,
           desired_orbit: dest,
           objective: obj,
           plan: plan_result,
           sim_vector: start_vector,
           sim_history: [%{
             step: 0,
             vector: start_vector,
             estimation: OrbitEstimator.estimate(start_vector),
             action: "init",
             status: "Active"
           }],
           sim_step: 0,
           sim_status: :active,
           tel_gsi: gsi,
           tel_agency: agency,
           tel_robustness: rob,
           tel_generativity: gen
         )}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Target state path is unreachable.")}
    end
  end

  # Step through closed-loop controller simulation
  def handle_event("step_simulation", _params, socket) do
    # Get current index on planned path sequence
    plan = socket.assigns.plan
    sim_step = socket.assigns.sim_step
    sim_vector = socket.assigns.sim_vector
    desired_orbit = socket.assigns.desired_orbit
    objective = socket.assigns.objective

    interventions = plan[:recommended_interventions] || []

    if sim_step >= length(interventions) do
      {:noreply, assign(socket, sim_status: :arrived)}
    else
      # 1. Apply step policy coordinate adjustments (simulating environment output)
      next_intervention = Enum.at(interventions, sim_step)
      simulated_paths = OrbitController.simulate_trajectory(sim_vector, [next_intervention])
      next_vector = List.last(simulated_paths)

      # Introduce small random perturbation to simulate real-world parameter drift
      next_vector = Enum.map(next_vector, fn val ->
        Float.round(min(1.0, max(0.0, val + (:rand.uniform() * 0.08 - 0.04))), 4)
      end)

      # 2. Run Closed-loop Controller checking
      # Construct dummy telemetry
      [gsi, agency, rob, gen] = next_vector
      dummy_telemetry = %{
        redundancy_delta: agency - 0.5,
        dcr_retention: rob,
        novelty_rate: gen
      }

      # Run control step
      case OrbitController.navigate_step(dummy_telemetry, gsi, plan.path, desired_orbit, objective) do
        {:arrived, est} ->
          new_hist = %{
            step: sim_step + 1,
            vector: next_vector,
            estimation: est,
            action: next_intervention,
            status: "Arrived"
          }

          {:noreply,
           assign(socket,
             sim_vector: next_vector,
             sim_step: sim_step + 1,
             sim_history: socket.assigns.sim_history ++ [new_hist],
             sim_status: :arrived
           )}

        {:replanned, new_plan, est} ->
          new_hist = %{
            step: sim_step + 1,
            vector: next_vector,
            estimation: est,
            action: next_intervention,
            status: "Replanned (Drifted)"
          }

          {:noreply,
           assign(socket,
             sim_vector: next_vector,
             sim_step: 0, # restart sequence on new plan
             plan: new_plan,
             sim_history: socket.assigns.sim_history ++ [new_hist],
             sim_status: :replanned
           )}

        {:continue, est} ->
          new_hist = %{
            step: sim_step + 1,
            vector: next_vector,
            estimation: est,
            action: next_intervention,
            status: "Active"
          }

          {:noreply,
           assign(socket,
             sim_vector: next_vector,
             sim_step: sim_step + 1,
             sim_history: socket.assigns.sim_history ++ [new_hist],
             sim_status: :active
           )}

        {:error, _reason, est} ->
          new_hist = %{
            step: sim_step + 1,
            vector: next_vector,
            estimation: est,
            action: next_intervention,
            status: "Error (Unreachable)"
          }

          {:noreply,
           assign(socket,
             sim_vector: next_vector,
             sim_step: sim_step + 1,
             sim_history: socket.assigns.sim_history ++ [new_hist],
             sim_status: :error
           )}
      end
    end
  end

  # Reset Simulation
  def handle_event("reset_simulation", _params, socket) do
    {nodes, _} = OrbitReachabilityGraph.load()
    start_node = Enum.find(nodes, & &1.orbit_id == socket.assigns.current_orbit)
    start_vector = start_node.orbit_vector || [0.5, 0.5, 0.5, 0.5]
    [gsi, agency, rob, gen] = start_vector

    {:noreply,
     assign(socket,
       sim_vector: start_vector,
       sim_step: 0,
       sim_history: [%{
         step: 0,
         vector: start_vector,
         estimation: OrbitEstimator.estimate(start_vector),
         action: "init",
         status: "Active"
       }],
       sim_status: :active,
       tel_gsi: gsi,
       tel_agency: agency,
       tel_robustness: rob,
       tel_generativity: gen
     )}
  end

  # Custom Telemetry estimation
  def handle_event("estimate_custom", %{"gsi" => g, "agency" => a, "robustness" => r, "generativity" => n}, socket) do
    g = String.to_float(g)
    a = String.to_float(a)
    r = String.to_float(r)
    n = String.to_float(n)

    vector = [g, a, r, n]
    est = OrbitEstimator.estimate(vector)

    {:noreply,
     assign(socket,
       tel_gsi: g,
       tel_agency: a,
       tel_robustness: r,
       tel_generativity: n,
       tel_result: est
     )}
  end

  # Render LiveView
  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Top Title Bar -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Phase 11.9B</span>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-xs text-slate-400 font-mono">Trajectory Engineering & Navigation System</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2">Orbit Reachability & Navigation</h1>
          <p class="text-sm text-slate-400 mt-1">Multi-objective path planning, gateway detection, and closed-loop control simulation.</p>
        </div>
        <div>
          <a href="/data/orbit_reachability_matrix.csv" class="text-xs font-mono px-3 py-1.5 rounded bg-indigo-500/20 text-indigo-400 border border-indigo-500/30 hover:bg-indigo-500/30 transition-all cursor-pointer">
            Export Reachability Matrix (CSV)
          </a>
        </div>
      </div>

      <!-- Main Columns Grid -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        
        <!-- Column 1: Multi-Objective Planner Form & Plan Output -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span> Multi-Objective Path Planner
            </h2>
            
            <form phx-change="calculate_plan" class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
              <div>
                <label class="text-xs font-mono text-slate-400 block mb-1">Current Orbit</label>
                <select name="current_orbit" class="bg-slate-900 border border-slate-700 text-slate-200 text-sm rounded-lg p-2.5 w-full outline-none focus:border-blue-500">
                  <%= for node <- @nodes do %>
                    <option value={node.orbit_id} selected={node.orbit_id == @current_orbit}>
                      <%= format_name(node.orbit_id) %>
                    </option>
                  <% end %>
                </select>
              </div>

              <div>
                <label class="text-xs font-mono text-slate-400 block mb-1">Desired Orbit</label>
                <select name="desired_orbit" class="bg-slate-900 border border-slate-700 text-slate-200 text-sm rounded-lg p-2.5 w-full outline-none focus:border-blue-500">
                  <%= for node <- @nodes do %>
                    <option value={node.orbit_id} selected={node.orbit_id == @desired_orbit}>
                      <%= format_name(node.orbit_id) %>
                    </option>
                  <% end %>
                </select>
              </div>

              <div>
                <label class="text-xs font-mono text-slate-400 block mb-1">Planning Objective</label>
                <select name="objective" class="bg-slate-900 border border-slate-700 text-slate-200 text-sm rounded-lg p-2.5 w-full outline-none focus:border-blue-500">
                  <option value="lowest_energy" selected={@objective == :lowest_energy}>Lowest Energy</option>
                  <option value="shortest_path" selected={@objective == :shortest_path}>Shortest Path</option>
                  <option value="highest_probability" selected={@objective == :highest_probability}>Highest Probability</option>
                  <option value="maximum_residency" selected={@objective == :maximum_residency}>Maximum Residency</option>
                </select>
              </div>
            </form>

            <!-- Plan Result Display -->
            <div class="p-4 bg-slate-900/60 border border-blue-500/20 rounded-xl">
              <div class="flex justify-between items-center mb-3">
                <span class="text-xs font-mono text-slate-400">Planning Solution Output</span>
                <span class="text-[10px] font-mono bg-blue-500/10 text-blue-400 border border-blue-500/20 px-2 py-0.5 rounded font-semibold uppercase">
                  <%= to_string(@objective) %>
                </span>
              </div>
              
              <div class="flex flex-wrap items-center gap-2 mb-4">
                <%= for {orbit, index} <- Enum.with_index(@plan.path) do %>
                  <span class="text-xs font-mono bg-slate-800 text-slate-200 border border-slate-700 px-3 py-1 rounded-lg">
                    <%= format_name(orbit) %>
                  </span>
                  <%= if index < length(@plan.path) - 1 do %>
                    <span class="text-slate-500 font-bold">&rarr;</span>
                  <% end %>
                <% end %>
              </div>

              <div class="grid grid-cols-2 md:grid-cols-4 gap-4 border-t border-slate-800 pt-4">
                <div>
                  <span class="text-[10px] font-mono text-slate-500 block">Joint Probability</span>
                  <span class="text-lg font-bold font-mono text-emerald-400"><%= @plan.success_probability %></span>
                </div>
                <div>
                  <span class="text-[10px] font-mono text-slate-500 block">Expected Epochs</span>
                  <span class="text-lg font-bold font-mono text-amber-400"><%= @plan.expected_epochs %></span>
                </div>
                <div>
                  <span class="text-[10px] font-mono text-slate-500 block">Total Energy Cost</span>
                  <span class="text-lg font-bold font-mono text-indigo-400"><%= @plan.energy_cost %></span>
                </div>
                <div>
                  <span class="text-[10px] font-mono text-slate-500 block">Interventions</span>
                  <span class="text-xs font-bold font-mono text-slate-300 block mt-1">
                    <%= if @plan.recommended_interventions == [], do: "None", else: Enum.map(@plan.recommended_interventions, &to_string/1) |> Enum.join(", ") %>
                  </span>
                </div>
              </div>
            </div>
          </div>

          <!-- Closed-Loop Simulator -->
          <div class="glass-card p-6">
            <div class="flex justify-between items-center mb-4">
              <h2 class="text-xl font-bold font-heading text-slate-200 flex items-center gap-2">
                <span class="w-2 h-2 rounded-full bg-emerald-500"></span> Closed-Loop Simulator
              </h2>
              <div class="flex gap-2">
                <button phx-click="step_simulation" class="text-xs font-mono px-3 py-1.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 hover:bg-emerald-500/30 transition-all">
                  Simulate Step
                </button>
                <button phx-click="reset_simulation" class="text-xs font-mono px-3 py-1.5 rounded bg-slate-800 text-slate-400 border border-slate-700 hover:text-slate-200 transition-all">
                  Reset
                </button>
              </div>
            </div>

            <p class="text-xs text-slate-400 mb-4">
              Simulate dynamic civilizational navigation along the planned trajectory path. The controller checks for drift perturbations and triggers dynamic path replanning.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
              <!-- Observer Telemetry Gauges -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl md:col-span-1 flex flex-col gap-3">
                <span class="text-xs font-mono text-slate-400">Current Observer Coordinates</span>
                
                <% [gsi, agency, rob, gen] = @sim_vector %>
                
                <div class="flex flex-col gap-1.5">
                  <div class="flex justify-between text-xs font-mono">
                    <span class="text-slate-400">Constitutional (GSI)</span>
                    <span class="text-indigo-400 font-bold"><%= gsi %></span>
                  </div>
                  <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                    <div class="bg-indigo-500 h-full" style={"width: #{gsi * 100}%"}></div>
                  </div>
                </div>

                <div class="flex flex-col gap-1.5">
                  <div class="flex justify-between text-xs font-mono">
                    <span class="text-slate-400">Agency (Redundancy)</span>
                    <span class="text-indigo-400 font-bold"><%= agency %></span>
                  </div>
                  <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                    <div class="bg-indigo-500 h-full" style={"width: #{agency * 100}%"}></div>
                  </div>
                </div>

                <div class="flex flex-col gap-1.5">
                  <div class="flex justify-between text-xs font-mono">
                    <span class="text-slate-400">Robustness (DCR)</span>
                    <span class="text-indigo-400 font-bold"><%= rob %></span>
                  </div>
                  <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                    <div class="bg-indigo-500 h-full" style={"width: #{rob * 100}%"}></div>
                  </div>
                </div>

                <div class="flex flex-col gap-1.5">
                  <div class="flex justify-between text-xs font-mono">
                    <span class="text-slate-400">Generativity (Novelty)</span>
                    <span class="text-indigo-400 font-bold"><%= gen %></span>
                  </div>
                  <div class="w-full bg-slate-800 h-2 rounded-full overflow-hidden">
                    <div class="bg-indigo-500 h-full" style={"width: #{gen * 100}%"}></div>
                  </div>
                </div>
              </div>

              <!-- Estimator & Drift Logs -->
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl md:col-span-2 flex flex-col gap-3">
                <div class="flex justify-between items-center">
                  <span class="text-xs font-mono text-slate-400">Estimator Decision Output</span>
                  <span class={"text-[10px] font-mono px-2 py-0.5 rounded border uppercase " <> status_class(@sim_status)}>
                    <%= to_string(@sim_status) %>
                  </span>
                </div>

                <div class="flex justify-between items-center py-2 border-b border-slate-800">
                  <span class="text-xs text-slate-400">Current Orbit Classification</span>
                  <span class="text-sm font-bold font-mono text-slate-100"><%= format_name(List.last(@sim_history).estimation.orbit_id) %></span>
                </div>

                <div class="flex justify-between items-center py-2 border-b border-slate-800">
                  <span class="text-xs text-slate-400">Membership Confidence</span>
                  <span class="text-sm font-bold font-mono text-indigo-400"><%= List.last(@sim_history).estimation.confidence %></span>
                </div>

                <div class="flex flex-col gap-2 max-h-[140px] overflow-y-auto mt-2 pr-2">
                  <span class="text-[10px] font-mono text-slate-500">Execution Log Trail:</span>
                  <%= for step <- @sim_history do %>
                    <div class="text-xs font-mono flex justify-between text-slate-400 border-b border-slate-900 py-1">
                      <span>Step <%= step.step %>: <%= step.action %></span>
                      <span class={if String.contains?(step.status, "Replanned") or String.contains?(step.status, "Error"), do: "text-rose-400", else: "text-emerald-400"}>
                        <%= step.status %>
                      </span>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Column 2: Gateway Centrality & Orbit Resilience Panel -->
        <div class="lg:col-span-1 flex flex-col gap-6">
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-indigo-500"></span> Resilience & Gateway States
            </h2>
            
            <div class="flex flex-col gap-4">
              <%= for node <- @nodes do %>
                <% 
                  resilience = OrbitResilience.classify_orbit(node.orbit_id)
                  metrics = OrbitResilience.calculate_metrics(node.orbit_id)
                %>
                <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-xl">
                  <div class="flex justify-between items-start mb-2">
                    <div>
                      <h3 class="text-sm font-bold text-slate-100 font-heading"><%= format_name(node.orbit_id) %></h3>
                      <span class={"text-[9px] font-mono px-2 py-0.5 rounded border uppercase mt-1 inline-block " <> type_class(node.orbit_type)}>
                        <%= to_string(node.orbit_type) %>
                      </span>
                    </div>
                    <span class={"text-[10px] font-mono px-2.5 py-1 rounded border uppercase font-bold " <> resilience_class(resilience)}>
                      <%= to_string(resilience) %>
                    </span>
                  </div>

                  <div class="grid grid-cols-2 gap-2 text-xs font-mono text-slate-400 mt-3 pt-3 border-t border-slate-800">
                    <div>
                      <span class="text-[10px] text-slate-500 block">Attraction Potential</span>
                      <span class="text-indigo-300 font-bold"><%= node.orbit_potential %></span>
                    </div>
                    <div>
                      <span class="text-[10px] text-slate-500 block">Gateway (Betweenness)</span>
                      <span class="text-indigo-300 font-bold"><%= node.gateway_score %></span>
                    </div>
                    <div>
                      <span class="text-[10px] text-slate-500 block">Return Probability</span>
                      <span class="text-emerald-400 font-bold"><%= metrics.return_probability %></span>
                    </div>
                    <div>
                      <span class="text-[10px] text-slate-500 block">Reproduction Index</span>
                      <span class="text-amber-400 font-bold"><%= metrics.reproduction_rate %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Dynamic Proximity Estimator Tool -->
          <div class="glass-card p-6">
            <h2 class="text-xl font-bold font-heading text-slate-200 mb-4 flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span> Proximity Estimator
            </h2>

            <form phx-change="estimate_custom" class="flex flex-col gap-3">
              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">GSI (Constitutional): <%= @tel_gsi %></label>
                <input type="range" name="gsi" min="0.0" max="1.0" step="0.01" value={@tel_gsi} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-blue-500" />
              </div>
              
              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Agency (Redundancy): <%= @tel_agency %></label>
                <input type="range" name="agency" min="0.0" max="1.0" step="0.01" value={@tel_agency} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-blue-500" />
              </div>

              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Robustness (DCR): <%= @tel_robustness %></label>
                <input type="range" name="robustness" min="0.0" max="1.0" step="0.01" value={@tel_robustness} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-blue-500" />
              </div>

              <div>
                <label class="text-[10px] font-mono text-slate-400 block mb-1">Generativity (Novelty): <%= @tel_generativity %></label>
                <input type="range" name="generativity" min="0.0" max="1.0" step="0.01" value={@tel_generativity} class="w-full h-1 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-blue-500" />
              </div>
            </form>

            <%= if @tel_result do %>
              <div class="mt-4 p-3 bg-slate-900 border border-slate-800 rounded-lg text-xs font-mono flex flex-col gap-1.5">
                <div class="flex justify-between">
                  <span class="text-slate-500">Closest Centroid</span>
                  <span class="text-slate-200 font-bold"><%= format_name(@tel_result.orbit_id) %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-500">Confidence</span>
                  <span class="text-indigo-400 font-bold"><%= @tel_result.confidence %></span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-500">Distance</span>
                  <span class="text-rose-400 font-bold"><%= @tel_result.distance %></span>
                </div>
              </div>
            <% end %>
          </div>
        </div>

      </div>
    </div>
    """
  end

  # Helper functions
  defp format_name(atom) do
    atom
    |> to_string()
    |> String.replace("_orbit", "")
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp status_class(:active), do: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
  defp status_class(:arrived), do: "bg-blue-500/10 text-blue-400 border-blue-500/20"
  defp status_class(:replanned), do: "bg-amber-500/10 text-amber-400 border-amber-500/20"
  defp status_class(:error), do: "bg-rose-500/10 text-rose-400 border-rose-500/20"

  defp type_class(:elite), do: "bg-blue-500/10 text-blue-400 border-blue-500/20"
  defp type_class(:transient), do: "bg-indigo-500/10 text-indigo-400 border-indigo-500/20"
  defp type_class(:brittle), do: "bg-rose-500/10 text-rose-400 border-rose-500/20"
  defp type_class(:sink), do: "bg-amber-500/10 text-amber-400 border-amber-500/20"

  defp resilience_class(:reproductive), do: "bg-indigo-500/10 text-indigo-400 border-indigo-500/20"
  defp resilience_class(:regenerative), do: "bg-emerald-500/10 text-emerald-400 border-emerald-500/20"
  defp resilience_class(:metastable), do: "bg-amber-500/10 text-amber-400 border-amber-500/20"
  defp resilience_class(:stable), do: "bg-blue-500/10 text-blue-400 border-blue-500/20"
  defp resilience_class(:fragile), do: "bg-rose-500/10 text-rose-400 border-rose-500/20"
end
