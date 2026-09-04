defmodule TiannaraWeb.ResearchMapLive do
  @moduledoc """
  Displays the Scientific Atlas of Tiannara, projecting the research hierarchy dynamically from the Knowledge Graph.
  """
  use Phoenix.LiveView

  alias Tiannara.KnowledgeGraph.Registry, as: KG
  alias Tiannara.Domains.CanonicalRegistry
  alias Tiannara.Discoveries.Discovery

  def mount(_params, _session, socket) do
    nodes = KG.all()
    domains = CanonicalRegistry.all()
    principles = Enum.filter(nodes, & &1.type == :principle)
    orbits = Discovery.load_orbits()

    {:ok,
     assign(socket,
       nodes: nodes,
       domains: domains,
       principles: principles,
       orbits: orbits
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
      
      <!-- Left Column: Scientific Research Atlas (dynamic graph projection) -->
      <div class="lg:col-span-2 glass-card p-6 flex flex-col gap-6">
        <div class="border-b border-slate-700 pb-2">
          <h1 class="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
            Scientific Research Atlas
          </h1>
          <p class="text-xs text-slate-400 mt-1">Unified view of scientific principles, theories, and laws dynamically projected from the Knowledge Graph.</p>
        </div>

        <div class="flex flex-col gap-6">
          <%= for principle <- @principles do %>
            <div class="p-6 bg-slate-900/60 border border-slate-800 rounded-xl flex flex-col gap-4">
              <!-- Principles Layer -->
              <div class="flex items-center gap-2">
                <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Principle</span>
                <h2 class="text-base font-bold text-slate-100 font-heading"><%= principle.name %></h2>
              </div>
              <p class="text-xs text-slate-400 pl-4 border-l border-slate-800"><%= principle.description %></p>

              <!-- Mapped Domains Lenses -->
              <div class="flex flex-wrap gap-1.5 pl-4 py-1">
                <span class="text-[9px] uppercase font-bold text-slate-500 font-mono self-center mr-1">Domain Lenses:</span>
                <%= for dom_id <- principle.domains do %>
                  <% dom = Enum.find(@domains, & &1.id == dom_id) %>
                  <%= if dom do %>
                    <a href={"/domain/#{dom.id}"} class="bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 border border-blue-500/10 px-2 py-0.5 rounded text-[10px] font-mono transition-colors">
                      <%= dom.name %>
                    </a>
                  <% end %>
                <% end %>
              </div>

              <!-- Theories Layer (downstream of principle) -->
              <% theories = Enum.filter(@nodes, fn n -> n.type == :theory and to_string(principle.id) in (n.parents || []) end) %>
              <div class="ml-6 pl-4 border-l border-slate-800 flex flex-col gap-6">
                <%= for th <- theories do %>
                  <div class="flex flex-col gap-3">
                    <div class="flex items-center gap-2">
                      <span class="text-[10px] font-bold font-mono px-1.5 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/10 uppercase">Theory</span>
                      <h3 class="font-bold text-slate-200 text-sm"><%= th.name %></h3>
                    </div>
                    <p class="text-xs text-slate-300 leading-normal pl-4"><%= th.description %></p>

                    <!-- Laws / Discoveries Layer (downstream of theory) -->
                    <% laws = Enum.filter(@nodes, fn n -> n.type in [:law, :discovery] and to_string(th.id) in (n.parents || []) end) %>
                    <div class="ml-6 pl-4 border-l border-slate-850 flex flex-col gap-4">
                      <%= for law <- laws do %>
                        <div class="flex flex-col gap-2">
                          <div class="flex items-center gap-2">
                            <span class={"text-[9px] font-mono px-1.5 py-0.5 rounded uppercase " <>
                              if(law.type == :law, do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/10", else: "bg-amber-500/10 text-amber-400 border border-amber-500/10")
                            }>
                              <%= law.type %>
                            </span>
                            <h4 class="font-bold text-slate-350 text-xs"><%= law.name %></h4>
                          </div>
                          <p class="text-xs text-slate-400 pl-4"><%= law.description %></p>
                        </div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Right Column: Orbit Geometry Atlas Summary & Verdict -->
      <div class="flex flex-col gap-6">
        <%= if @orbits do %>
          <div class="glass-card p-6 flex flex-col gap-4 border border-purple-500/10" style="background: radial-gradient(circle at 100% 0%, hsla(270, 91%, 65%, 0.04) 0%, transparent 100%);">
            <div class="border-b border-slate-800 pb-2">
              <span class="text-[9px] font-bold font-mono px-1.5 py-0.5 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 uppercase">Phase 11.8</span>
              <h2 class="text-lg font-bold text-slate-100 font-heading mt-1">Orbit Geometry Atlas</h2>
              <p class="text-[11px] text-slate-400 mt-0.5">Empirical trajectories classification results.</p>
            </div>

            <!-- Falsification Conclusion -->
            <div class="p-3 bg-slate-900/60 border border-slate-850 rounded-lg text-xs leading-relaxed text-slate-300">
              <span class="text-[9px] font-bold text-amber-400 uppercase font-mono block mb-1">Scientific Verdict (Choice B)</span>
              <p>Phoenix & Settler trajectories converge onto identical orbit classes. Navigator family acts as a search heuristic; the underlying <strong>Orbit Geometry</strong> is the primary causal driver.</p>
            </div>

            <!-- Discovered classes list -->
            <div class="flex flex-col gap-3">
              <span class="text-[10px] uppercase font-bold text-slate-500 font-mono tracking-wider">Discovered Classes</span>
              <%= for cluster <- @orbits.orbit_atlas do %>
                <div class="p-3 bg-slate-900/40 border border-slate-800 rounded-lg flex flex-col gap-2 hover:border-purple-500/15 transition-all">
                  <div class="flex justify-between items-center text-xs">
                    <span class="font-bold text-slate-200"><%= cluster.archetype %></span>
                    <span class="text-[10px] text-purple-400 font-mono bg-purple-500/10 px-1.5 py-0.25 rounded border border-purple-500/20">Class <%= cluster.cluster_id %></span>
                  </div>
                  <div class="grid grid-cols-2 gap-x-2 gap-y-1 font-mono text-[10px] text-slate-400">
                    <span>GSI: <strong><%= Float.round(cluster.mean_gsi, 4) %></strong></span>
                    <span>Return: <strong><%= Float.round(cluster.mean_return_time, 2) %></strong></span>
                    <span>Duty: <strong><%= Float.round(cluster.mean_duty_cycle, 2) %></strong></span>
                    <span>Identity: <strong class="text-purple-300"><%= Float.round(cluster.mean_identity_persistence, 4) %></strong></span>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Candidate Laws -->
            <div class="flex flex-col gap-2 border-t border-slate-800 pt-3">
              <span class="text-[10px] uppercase font-bold text-slate-500 font-mono tracking-wider">Candidate Laws</span>
              <%= for law <- @orbits.candidate_laws do %>
                <div class="p-2 bg-slate-900/50 border border-emerald-500/10 rounded text-[11px] font-mono text-slate-300">
                  <%= law %>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
