defmodule TiannaraWeb.DomainDetailLive do
  @moduledoc """
  Detailed view of a single Domain Research lens, displaying programs, theories, laws, discoveries,
  unknowns, and suggested experiments mapped via the Knowledge Graph.
  """
  use Phoenix.LiveView

  alias Tiannara.Domains.{CanonicalRegistry, KnowledgeCapitalBoundary, PortfolioBoundary}
  alias Tiannara.KnowledgeGraph.Registry, as: KG
  alias Tiannara.Discoveries.Program
  alias Tiannara.Research.Director

  def mount(%{"name" => name}, _session, socket) do
    domain_id = String.to_atom(name)
    dom = CanonicalRegistry.get(domain_id)

    if dom do
      vector = PortfolioBoundary.get(domain_id)
      capital = KnowledgeCapitalBoundary.get(domain_id)
      
      # Query knowledge graph nodes matching this domain
      nodes = KG.all()
      theories = Enum.filter(nodes, fn n -> n.type == :theory and domain_id in n.domains end)
      laws = Enum.filter(nodes, fn n -> n.type == :law and domain_id in n.domains end)
      discoveries = Enum.filter(nodes, fn n -> n.type == :discovery and domain_id in n.domains end)
      
      # Query programs
      all_programs = Program.all()
      programs = Enum.filter(all_programs, & &1.id in (dom.program_ids || []))

      # Query recommended experiments
      experiments = 
        Director.recommend_experiments()
        |> Enum.filter(& &1.target_domain_id == domain_id)

      {:ok,
       assign(socket,
         dom: dom,
         vector: vector,
         capital: capital,
         programs: programs,
         theories: theories,
         laws: laws,
         discoveries: discoveries,
         experiments: experiments
       )}
    else
      {:ok, redirect(socket, to: "/domains")}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-6">
      <!-- Top Title Bar -->
      <div class="glass-card p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div class="flex items-center gap-2">
            <a href="/domains" class="text-xs text-indigo-400 hover:underline font-heading font-semibold">&larr; Back to Registry</a>
            <span class="text-slate-600 font-mono">|</span>
            <span class="text-[10px] font-bold font-mono px-2 py-0.5 rounded bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 uppercase">Domain Portfolio</span>
          </div>
          <h1 class="text-3xl font-extrabold text-slate-100 font-heading mt-2"><%= @dom.name %></h1>
          <p class="text-sm text-slate-400 mt-1"><%= @dom.description %></p>
        </div>
        <div class="text-right">
          <span class="text-xs text-slate-500 font-mono block">Knowledge Capital</span>
          <span class="text-2xl font-bold text-indigo-400 font-mono bg-indigo-500/10 border border-indigo-500/20 px-3 py-1 rounded block mt-1">
            <%= @capital %>
          </span>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
        <!-- Left Side: Knowledge Portfolio Vector & Stats -->
        <div class="flex flex-col gap-6">
          <div class="glass-card p-6 flex flex-col gap-4">
            <h3 class="text-sm font-bold text-slate-300 font-heading border-b border-slate-800 pb-2">Knowledge Portfolio Vector</h3>
            
            <div class="flex flex-col gap-3 font-mono text-xs">
              <div class="flex justify-between items-center p-2.5 bg-slate-950 rounded border border-slate-900">
                <span class="text-slate-500">Discovery Power</span>
                <strong class="text-slate-200 text-sm"><%= Float.round(@vector.discovery_power, 0) %></strong>
              </div>
              <div class="flex justify-between items-center p-2.5 bg-slate-950 rounded border border-slate-900">
                <span class="text-slate-500">Intervention Power</span>
                <strong class="text-emerald-400 text-sm"><%= Float.round(@vector.intervention_power * 100, 0) %>%</strong>
              </div>
              <div class="flex justify-between items-center p-2.5 bg-slate-950 rounded border border-slate-900">
                <span class="text-slate-500">Transferability Rate</span>
                <strong class="text-blue-400 text-sm"><%= Float.round(@vector.transferability * 100, 0) %>%</strong>
              </div>
              <div class="flex justify-between items-center p-2.5 bg-slate-950 rounded border border-slate-900">
                <span class="text-slate-500">Uncertainty Bound</span>
                <strong class="text-amber-400 text-sm"><%= Float.round(@vector.uncertainty * 100, 0) %>%</strong>
              </div>
              <div class="flex justify-between items-center p-2.5 bg-slate-950 rounded border border-slate-900">
                <span class="text-slate-500">Research Debt</span>
                <strong class="text-rose-400 text-sm"><%= Float.round(@vector.research_debt, 0) %></strong>
              </div>
              <div class="flex justify-between items-center p-2.5 bg-slate-950 rounded border border-slate-900">
                <span class="text-slate-500">Validation Depth</span>
                <strong class="text-purple-400 text-sm"><%= Float.round(@vector.validation_depth * 100, 0) %>%</strong>
              </div>
            </div>
          </div>

          <!-- Discovered Laws & Discoveries List -->
          <div class="glass-card p-6 flex flex-col gap-4">
            <h3 class="text-sm font-bold text-slate-300 font-heading border-b border-slate-800 pb-2">Active Laws & Discoveries</h3>
            <%= if Enum.empty?(@laws) and Enum.empty?(@discoveries) do %>
              <p class="text-xs text-slate-500 italic">No validated laws or discoveries currently mapped to this lens.</p>
            <% else %>
              <div class="flex flex-col gap-3">
                <%= for law <- @laws do %>
                  <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-1.5">
                    <div class="flex justify-between items-center text-xs">
                      <strong class="text-slate-200"><%= law.name %></strong>
                      <span class="text-[9px] px-1 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-mono">LAW</span>
                    </div>
                    <p class="text-[11px] text-slate-400"><%= law.description %></p>
                  </div>
                <% end %>

                <%= for disc <- @discoveries do %>
                  <div class="p-3 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-1.5">
                    <div class="flex justify-between items-center text-xs">
                      <strong class="text-slate-200"><%= disc.name %></strong>
                      <span class="text-[9px] px-1 rounded bg-purple-500/10 text-purple-400 border border-purple-500/20 font-mono">DISCOVERY</span>
                    </div>
                    <p class="text-[11px] text-slate-400"><%= disc.description %></p>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>

        <!-- Right Side: Programs, Theories, and Recommendations -->
        <div class="lg:col-span-2 flex flex-col gap-6">
          <!-- Active Programs -->
          <div class="glass-card p-6 flex flex-col gap-4">
            <h3 class="text-sm font-bold text-slate-300 font-heading border-b border-slate-800 pb-2">Research Programs</h3>
            <%= if Enum.empty?(@programs) do %>
              <p class="text-xs text-slate-500 italic">No research programs seeded for this domain lens.</p>
            <% else %>
              <div class="flex flex-col gap-4">
                <%= for prog <- @programs do %>
                  <div class="p-4 bg-slate-900/40 border border-slate-800 rounded-lg flex flex-col gap-2">
                    <div class="flex justify-between items-center">
                      <h4 class="font-bold text-slate-200 text-sm font-heading"><%= prog.name %></h4>
                      <span class="text-[10px] text-slate-500 font-mono">Status: <%= prog.status %></span>
                    </div>
                    <p class="text-xs text-slate-400"><strong class="text-slate-300">Goal:</strong> <%= prog.goal %></p>
                    <p class="text-xs text-slate-400"><strong class="text-slate-300">Objective:</strong> <%= prog.objective %></p>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Active Theories -->
          <div class="glass-card p-6 flex flex-col gap-4">
            <h3 class="text-sm font-bold text-slate-300 font-heading border-b border-slate-800 pb-2">Active Theories</h3>
            <%= if Enum.empty?(@theories) do %>
              <p class="text-xs text-slate-500 italic">No theories actively mapped to this domain lens.</p>
            <% else %>
              <div class="flex flex-col gap-4">
                <%= for th <- @theories do %>
                  <div class="p-4 bg-slate-900/40 border border-slate-800 rounded-lg flex flex-col gap-2">
                    <h4 class="font-bold text-slate-200 text-sm font-heading"><%= th.name %></h4>
                    <p class="text-xs text-slate-300 font-mono bg-slate-950 p-2.5 rounded border border-slate-900 leading-relaxed"><%= th.description %></p>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <!-- Recommended Transfer Experiments -->
          <div class="glass-card p-6 flex flex-col gap-4" style="background: radial-gradient(circle at 100% 0%, hsla(270, 91%, 65%, 0.04) 0%, transparent 100%); border-color: hsla(270, 91%, 65%, 0.15);">
            <div class="flex justify-between items-center border-b border-slate-800 pb-2">
              <h3 class="text-sm font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400 font-heading">Recommended Transfer Experiments</h3>
              <span class="text-[10px] font-mono text-purple-400 font-semibold px-2 py-0.5 rounded bg-purple-500/10 border border-purple-500/20">Director recommendations</span>
            </div>

            <%= if Enum.empty?(@experiments) do %>
              <p class="text-xs text-slate-500 italic">No recommendations mapped. Domain maturity is stable.</p>
            <% else %>
              <div class="flex flex-col gap-4">
                <%= for exp <- @experiments do %>
                  <div class="p-4 bg-slate-950/60 border border-purple-500/15 rounded-lg flex flex-col gap-2">
                    <div class="flex justify-between items-center">
                      <span class="text-xs font-bold text-purple-400 font-mono"><%= exp.experiment_name %></span>
                      <span class="text-[9px] px-1.5 py-0.5 rounded bg-purple-500/20 text-purple-300 border border-purple-500/30 uppercase font-mono font-semibold"><%= exp.type %></span>
                    </div>
                    <p class="text-xs text-slate-300 leading-normal"><%= exp.reason_explanation %></p>
                    <div class="grid grid-cols-3 gap-2 text-[10px] font-mono text-slate-500 pt-2 border-t border-slate-900/60">
                      <span>Info Gain: <strong class="text-slate-300"><%= Float.round(exp.expected_information_gain * 100, 0) %>%</strong></span>
                      <span>Uncertainty Reduc: <strong class="text-slate-300"><%= Float.round(exp.expected_uncertainty_reduction * 100, 0) %>%</strong></span>
                      <span>Est DVR Gain: <strong class="text-emerald-400">+<%= Float.round(exp.expected_dvr_gain * 100, 0) %>%</strong></span>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
