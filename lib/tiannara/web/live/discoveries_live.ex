defmodule TiannaraWeb.DiscoveriesLive do
  @moduledoc """
  Displays the Discoveries feed, showing confidence decomposition, lineages, and falsification tracking.
  """
  use Phoenix.LiveView

  alias Tiannara.Discoveries.Discovery

  def mount(_params, _session, socket) do
    discoveries = Discovery.all()
    orbits = Discovery.load_orbits()
    {:ok, assign(socket, discoveries: discoveries, orbits: orbits)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-emerald-400 font-heading">Discovery Feed</h1>
        <p class="text-xs text-slate-400 mt-1">Surfaces topological anomalies, attracts boundaries, and adaptative geometries.</p>
      </div>

      <%= if @orbits do %>
        <!-- Orbit Classification Atlas (Phase 11.8) -->
        <div class="p-6 bg-slate-950/40 border border-purple-500/10 rounded-xl flex flex-col gap-6" style="background: radial-gradient(circle at 100% 0%, hsla(270, 91%, 65%, 0.05) 0%, transparent 100%);">
          <div class="border-b border-slate-800 pb-3 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
            <div>
              <div class="flex items-center gap-2">
                <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 uppercase">Phase 11.8</span>
                <h2 class="text-lg font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400 font-heading">Orbit Classification Atlas</h2>
              </div>
              <p class="text-xs text-slate-400 mt-1">Empirical classification of regenerative orbits and invariants across 500 trajectories.</p>
            </div>
            <div class="flex flex-col gap-1 md:items-end">
              <span class="text-[10px] text-slate-500 font-mono uppercase tracking-wider">Scientific Verdict</span>
              <span class="text-xs font-bold text-amber-400 bg-amber-400/10 border border-amber-400/20 px-2 py-1 rounded">
                Choice B: Orbit Geometry is Fundamental
              </span>
            </div>
          </div>

          <!-- Falsification Statement -->
          <div class="p-4 bg-slate-900/40 border border-purple-500/15 rounded-lg text-xs md:text-sm text-slate-300 leading-relaxed">
            <span class="text-[10px] uppercase font-bold text-purple-400 font-mono block mb-1">Primary Falsification Result</span>
            <p><strong>Verdict Confirmed:</strong> Elite trajectories from opposite regimes (Phoenix & Settler) converge onto identical orbit geometries. Navigator families act as search heuristics; the orbit geometry itself is the causal driver of sustained generativity.</p>
            <p class="text-xs text-slate-500 mt-2 italic border-t border-slate-800/40 pt-2 font-mono">
              "Identity Persistence (I) is the dominant invariant sustaining repeated entry into generative orbits under collapse."
            </p>
          </div>

          <!-- Grid of Discovered Orbit Classes -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <%= for cluster <- @orbits.orbit_atlas do %>
              <div class="p-4 bg-slate-900/60 border border-slate-800 rounded-lg hover:border-purple-500/20 transition-all flex flex-col gap-3">
                <div class="flex justify-between items-center">
                  <div class="flex items-center gap-2">
                    <span class="w-6 h-6 rounded-full bg-purple-500/10 border border-purple-500/20 flex items-center justify-center font-mono font-bold text-xs text-purple-400">
                      <%= cluster.cluster_id %>
                    </span>
                    <h3 class="font-bold text-slate-200 text-sm"><%= cluster.archetype %></h3>
                  </div>
                  <span class="text-xs text-slate-500 font-mono">Size: <%= cluster.count %></span>
                </div>

                <div class="grid grid-cols-2 gap-x-4 gap-y-2 text-xs font-mono text-slate-400">
                  <div>
                    <span class="text-[9px] text-slate-500 block uppercase">Mean GSI</span>
                    <strong class="text-slate-300"><%= Float.round(cluster.mean_gsi, 4) %></strong>
                  </div>
                  <div>
                    <span class="text-[9px] text-slate-500 block uppercase">Return Time</span>
                    <strong class="text-slate-300"><%= Float.round(cluster.mean_return_time, 2) %></strong>
                  </div>
                  <div>
                    <span class="text-[9px] text-slate-500 block uppercase">Duty Cycle</span>
                    <strong class="text-slate-300"><%= Float.round(cluster.mean_duty_cycle, 2) %></strong>
                  </div>
                  <div>
                    <span class="text-[9px] text-slate-500 block uppercase">Recurrence</span>
                    <strong class="text-slate-300"><%= Float.round(cluster.mean_recurrence, 4) %></strong>
                  </div>
                  <div>
                    <span class="text-[9px] text-slate-500 block uppercase">Half Life</span>
                    <strong class="text-slate-300"><%= Float.round(cluster.mean_half_life, 2) %></strong>
                  </div>
                  <div>
                    <span class="text-[9px] text-slate-500 block uppercase">Identity Persistence</span>
                    <strong class="text-purple-400"><%= Float.round(cluster.mean_identity_persistence, 4) %></strong>
                  </div>
                </div>

                <!-- Navigator Composition -->
                <div class="mt-2 pt-2 border-t border-slate-850">
                  <span class="text-[9px] uppercase text-slate-500 font-semibold font-mono block mb-1">Navigator Composition</span>
                  <div class="flex flex-wrap gap-1.5">
                    <%= for {family, count} <- cluster.family_composition do %>
                      <% is_dom = to_string(family) == to_string(cluster.dominant_navigator) %>
                      <span class={"text-[9px] px-1.5 py-0.5 rounded font-mono " <> if(is_dom, do: "bg-purple-500/20 text-purple-300 border border-purple-500/30 font-semibold", else: "bg-slate-800/60 text-slate-400 border border-slate-800")}>
                        <%= family %>: <%= count %>
                      </span>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Equivalence Matrix & Invariant Rankings -->
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-2">
            <!-- Overlap Matrix -->
            <div class="flex flex-col gap-3">
              <span class="text-xs font-bold text-slate-300 font-heading">Orbit Equivalence Matrix (Navigator Overlap)</span>
              <div class="overflow-x-auto border border-slate-800 rounded-lg">
                <table class="w-full text-left border-collapse text-xs font-mono">
                  <thead>
                    <tr class="bg-slate-900 border-b border-slate-800 text-slate-550">
                      <th class="p-2">Archetype Class</th>
                      <th class="p-2 text-center">Phoenix</th>
                      <th class="p-2 text-center">Settler</th>
                      <th class="p-2 text-center">Survivor</th>
                      <th class="p-2 text-center">Trader</th>
                      <th class="p-2 text-center">Explorer</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-850 text-slate-300">
                    <%= for {archetype, values} <- @orbits.equivalence_matrix do %>
                      <tr class="hover:bg-slate-900/40">
                        <td class="p-2 font-bold text-slate-200"><%= to_string(archetype) %></td>
                        <td class="p-2 text-center text-purple-400 font-bold"><%= Map.get(values, :Phoenix) || Map.get(values, "Phoenix") || 0 %></td>
                        <td class="p-2 text-center text-indigo-400 font-bold"><%= Map.get(values, :Settler) || Map.get(values, "Settler") || 0 %></td>
                        <td class="p-2 text-center"><%= Map.get(values, :Survivor) || Map.get(values, "Survivor") || 0 %></td>
                        <td class="p-2 text-center"><%= Map.get(values, :Trader) || Map.get(values, "Trader") || 0 %></td>
                        <td class="p-2 text-center"><%= Map.get(values, :Explorer) || Map.get(values, "Explorer") || 0 %></td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>

            <!-- Invariant Rankings -->
            <div class="flex flex-col gap-3">
              <span class="text-xs font-bold text-slate-300 font-heading">Predictive Invariant Rankings</span>
              <div class="overflow-x-auto border border-slate-800 rounded-lg">
                <table class="w-full text-left border-collapse text-xs font-mono">
                  <thead>
                    <tr class="bg-slate-900 border-b border-slate-800 text-slate-550">
                      <th class="p-2">Rank</th>
                      <th class="p-2">Metric</th>
                      <th class="p-2">Feature Importance</th>
                      <th class="p-2">Mutual Info</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-slate-850 text-slate-300">
                    <%= for {item, idx} <- Enum.with_index(@orbits.invariants_ranked) do %>
                      <%= if idx < 5 do %>
                        <tr class="hover:bg-slate-900/40">
                          <td class="p-2 text-slate-500 font-bold"><%= idx + 1 %></td>
                          <td class="p-2 font-bold text-slate-200"><%= item.metric %></td>
                          <td class="p-2 text-emerald-400"><%= Float.round(item.feature_importance, 4) %></td>
                          <td class="p-2 text-blue-400"><%= Float.round(item.mutual_information, 4) %></td>
                        </tr>
                      <% end %>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- Candidate Regenerative Laws -->
          <div class="flex flex-col gap-3 border-t border-slate-800 pt-4">
            <span class="text-xs font-bold text-slate-300 font-heading">Empirical Regenerative Laws</span>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <%= for law <- @orbits.candidate_laws do %>
                <div class="p-3 bg-slate-900/60 border border-emerald-500/10 rounded-lg text-xs flex flex-col gap-1 hover:border-emerald-500/25 transition-all">
                  <span class="font-bold text-emerald-400 uppercase text-[9px] tracking-wider font-mono">Discovered Rule</span>
                  <span class="text-slate-200 font-mono leading-relaxed"><%= law %></span>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <div class="flex flex-col gap-6">
        <%= for disc <- @discoveries do %>
          <div class="p-5 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-4">
            <div class="flex justify-between items-start">
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="font-bold text-slate-100 text-lg"><%= disc.name %></h3>
                  <span class={"text-xs px-2 py-0.5 rounded font-semibold " <>
                    case disc.status do
                      :validated -> "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                      :supported_law -> "bg-blue-500/10 text-blue-400 border border-blue-500/20"
                      :candidate_law -> "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20"
                      _ -> "bg-slate-500/10 text-slate-400 border border-slate-500/20"
                    end
                  }>
                    <%= disc.status %>
                  </span>
                </div>
                <p class="text-sm text-slate-300 mt-1"><%= disc.claim %></p>
              </div>

              <!-- Timestamp & Promotion Action -->
              <div class="flex flex-col gap-2 items-end">
                <span class="text-xs text-slate-500 font-mono"><%= String.slice(disc.timestamp, 0, 10) %></span>
                <%= if disc.status == :observation or disc.status == :candidate_law do %>
                  <button 
                    phx-click="promote" 
                    phx-value-id={disc.id}
                    class="text-xs bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-1.5 px-3 rounded cursor-pointer transition-colors"
                  >
                    Promote Law
                  </button>
                <% else %>
                  <span class="text-xs text-slate-500 font-semibold font-mono">Promoted</span>
                <% end %>
              </div>
            </div>

            <!-- Decomposed Confidence Indices -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs font-mono bg-slate-950 p-3 rounded border border-slate-850">
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Simulation Conf</span>
                <span class="text-slate-200 font-bold"><%= Float.round((disc.confidence[:simulation] || 0.0) * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Operational Conf</span>
                <span class="text-slate-200 font-bold"><%= Float.round((disc.confidence[:operational] || 0.0) * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Theoretical Conf</span>
                <span class="text-slate-200 font-bold"><%= Float.round((disc.confidence[:theoretical] || 0.0) * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Consensus Conf</span>
                <span class="text-slate-200 font-bold"><%= Float.round((disc.confidence[:consensus] || 0.0) * 100, 0) %>%</span>
              </div>
            </div>

            <!-- Lineage & Falsification Tracking -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
              <div class="flex flex-col gap-2">
                <span class="text-[10px] uppercase text-slate-500 font-semibold font-mono">Discovery Lineage</span>
                <div class="flex flex-col gap-1 text-[11px] text-slate-400">
                  <div>
                    <span class="text-slate-500 font-semibold">Influences:</span>
                    <%= if Enum.empty?(disc.influences || []) do %>
                      <span class="font-mono text-slate-600">None</span>
                    <% else %>
                      <%= Enum.join(disc.influences, ", ") %>
                    <% end %>
                  </div>
                  <div>
                    <span class="text-slate-500 font-semibold">Influenced By:</span>
                    <%= if Enum.empty?(disc.influenced_by || []) do %>
                      <span class="font-mono text-slate-600">None</span>
                    <% else %>
                      <%= Enum.join(disc.influenced_by, ", ") %>
                    <% end %>
                  </div>
                </div>
              </div>

              <div class="flex flex-col gap-2 font-mono">
                <span class="text-[10px] uppercase text-slate-500 font-semibold">Falsification Tracking</span>
                <div class="grid grid-cols-3 gap-2 text-[11px] text-slate-400">
                  <div>
                    <span>Attempts:</span>
                    <strong class="text-slate-300 block"><%= disc.falsification_attempts %></strong>
                  </div>
                  <div>
                    <span>Survived:</span>
                    <strong class="text-emerald-400 block"><%= disc.survived_challenges %></strong>
                  </div>
                  <div>
                    <span>Failed:</span>
                    <strong class="text-rose-400 block"><%= disc.successful_challenges %></strong>
                  </div>
                </div>
              </div>
            </div>

            <div class="flex gap-4 text-[10px] text-slate-500 mt-2 font-mono border-t border-slate-850 pt-2">
              <span>Worlds Evidence: <%= disc.worlds_evidence %></span>
              <span>Runs Evidence: <%= disc.operational_runs_evidence %></span>
              <span>Aggregate Confidence: <%= Float.round(Discovery.get_aggregate_confidence(disc) * 100, 1) %>%</span>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("promote", %{"id" => id}, socket) do
    discoveries = socket.assigns.discoveries
    disc = Enum.find(discoveries, & &1.id == id)

    case Discovery.promote(disc) do
      {:ok, promoted} ->
        new_list = Enum.map(discoveries, fn d -> if d.id == id, do: promoted, else: d end)
        Discovery.write_all(new_list)
        
        {:noreply, 
         socket
         |> put_flash(:info, "Successfully promoted #{disc.name} to #{promoted.status}!")
         |> assign(discoveries: new_list)}

      {:error, :threshold_not_met} ->
        {:noreply, 
         socket 
         |> put_flash(:error, "Failed to promote #{disc.name}: Evidence thresholds not met (Worlds > 100/500, Confidence > 60%/75%).")}
    end
  end
end
