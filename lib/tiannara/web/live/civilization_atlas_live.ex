defmodule TiannaraWeb.CivilizationAtlasLive do
  @moduledoc """
  The Civilization Atlas visualizes evidence flows from Principles down to Outcomes and processes
  domain-specific questions. Exposes both the query dashboard and the /knowledge-flow visualization.
  """
  use Phoenix.LiveView

  alias Tiannara.Domains.{CanonicalRegistry, PortfolioBoundary}
  alias Tiannara.KnowledgeGraph.Registry, as: KG

  def mount(_params, _session, socket) do
    domains = CanonicalRegistry.all()
    nodes = KG.all()
    discoveries = Enum.filter(nodes, & &1.type == :discovery)
    laws = Enum.filter(nodes, & &1.type == :law)
    theories = Enum.filter(nodes, & &1.type == :theory)
    interventions = Enum.filter(nodes, & &1.type == :intervention)
    outcomes = Enum.filter(nodes, & &1.type == :outcome)

    {:ok,
     assign(socket,
       domains: domains,
       nodes: nodes,
       discoveries: discoveries,
       laws: laws,
       theories: theories,
       interventions: interventions,
       outcomes: outcomes,
       selected_domain: nil,
       selected_discovery: List.first(discoveries),
       query_results: nil,
       query_question: nil,
       tab: :atlas
     )}
  end

  def handle_params(_params, uri, socket) do
    tab = if String.contains?(uri, "knowledge-flow"), do: :knowledge_flow, else: :atlas
    {:noreply, assign(socket, tab: tab)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <!-- Header -->
      <div class="border-b border-slate-700 pb-3 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
            Civilization Knowledge Atlas
          </h1>
          <p class="text-xs text-slate-400 mt-1">Cross-domain validation, evidence flow pathways, and dynamic knowledge mappings.</p>
        </div>

        <!-- Tab Selector -->
        <div class="flex bg-slate-900 p-1 rounded-lg border border-slate-800 text-xs font-mono">
          <a href="/civilization-atlas" class={"px-3 py-1.5 rounded transition-all " <> if(@tab == :atlas, do: "bg-indigo-600 text-white font-bold", else: "text-slate-400 hover:text-slate-200")}>
            Domain Queries
          </a>
          <a href="/civilization-atlas/knowledge-flow" class={"px-3 py-1.5 rounded transition-all " <> if(@tab == :knowledge_flow, do: "bg-indigo-600 text-white font-bold", else: "text-slate-400 hover:text-slate-200")}>
            Knowledge Flow Visualizer
          </a>
        </div>
      </div>

      <%= if @tab == :atlas do %>
        <!-- TAB 1: DOMAIN QUERIES -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
          
          <!-- Query Selection List -->
          <div class="flex flex-col gap-4">
            <h3 class="text-sm font-bold text-slate-300 font-heading">Interactive Knowledge Inquiries</h3>
            <div class="flex flex-col gap-2 font-mono text-xs">
              <button phx-click="run_query" phx-value-qid="rob" class="text-left p-3 rounded-lg border border-slate-800 bg-slate-900/40 hover:border-indigo-500/20 text-slate-300 transition-all cursor-pointer">
                Which discoveries influenced robotics?
              </button>
              <button phx-click="run_query" phx-value-qid="med" class="text-left p-3 rounded-lg border border-slate-800 bg-slate-900/40 hover:border-indigo-500/20 text-slate-300 transition-all cursor-pointer">
                Which laws support medicine?
              </button>
              <button phx-click="run_query" phx-value-qid="eng" class="text-left p-3 rounded-lg border border-slate-800 bg-slate-900/40 hover:border-indigo-500/20 text-slate-300 transition-all cursor-pointer">
                Which constitutions maximize engineering resilience?
              </button>
              <button phx-click="run_query" phx-value-qid="ene" class="text-left p-3 rounded-lg border border-slate-800 bg-slate-900/40 hover:border-indigo-500/20 text-slate-300 transition-all cursor-pointer">
                Which worlds produced discoveries relevant to energy?
              </button>
            </div>

            <!-- Domain filter selector -->
            <div class="border-t border-slate-850 pt-4 flex flex-col gap-2">
              <span class="text-xs font-bold text-slate-300 font-heading">Filter Atlas by Domain Lens</span>
              <div class="grid grid-cols-2 gap-2 text-[10px] font-mono">
                <%= for dom <- @domains do %>
                  <button phx-click="select_domain" phx-value-id={dom.id} class={"px-2.5 py-1.5 rounded border text-left cursor-pointer transition-all " <>
                    if(to_string(@selected_domain) == to_string(dom.id), do: "bg-indigo-600/20 text-indigo-300 border-indigo-500/40 font-bold", else: "bg-slate-900/20 text-slate-400 border-slate-800")
                  }>
                    <%= dom.name %>
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Query Outputs & Projections -->
          <div class="lg:col-span-2 flex flex-col gap-6">
            <%= if @query_question do %>
              <!-- Inquiry Result Card -->
              <div class="p-5 bg-slate-950 border border-indigo-500/20 rounded-xl flex flex-col gap-4">
                <div class="border-b border-slate-900 pb-2">
                  <span class="text-[9px] uppercase font-bold text-indigo-400 font-mono">Inquiry Result</span>
                  <h4 class="text-sm font-bold text-slate-200 font-heading mt-1"><%= @query_question %></h4>
                </div>

                <div class="flex flex-col gap-3">
                  <%= if Enum.empty?(@query_results) do %>
                    <p class="text-xs text-slate-500 italic">No nodes matching evidence criteria.</p>
                  <% else %>
                    <%= for res <- @query_results do %>
                      <div class="p-3 bg-slate-900/50 border border-slate-800 rounded-lg text-xs leading-relaxed text-slate-300">
                        <div class="flex justify-between items-center mb-1">
                          <strong class="text-slate-200 font-heading"><%= res.name %></strong>
                          <span class="text-[9px] px-1.5 py-0.25 rounded font-mono bg-slate-800 text-slate-400 uppercase"><%= res.type %></span>
                        </div>
                        <p class="text-slate-400 text-[11px]"><%= res.description %></p>
                        <div class="mt-2 text-[9px] text-slate-500 font-mono">
                          Domains: <%= Enum.join(res.domains, ", ") %>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            <% end %>

            <!-- Selected Domain View -->
            <%= if @selected_domain do %>
              <% dom_data = Enum.find(@domains, & &1.id == @selected_domain) %>
              <% _vector = PortfolioBoundary.get(@selected_domain) %>
              <%= if dom_data do %>
                <div class="p-6 bg-slate-900/30 border border-slate-800 rounded-xl flex flex-col gap-5">
                  <div class="border-b border-slate-800 pb-2 flex justify-between items-center">
                    <div>
                      <h3 class="text-lg font-bold text-slate-200 font-heading"><%= dom_data.name %> Knowledge View</h3>
                      <p class="text-xs text-slate-400 mt-0.5"><%= dom_data.description %></p>
                    </div>
                    <a href={"/domain/#{dom_data.id}"} class="text-xs text-indigo-400 hover:underline">View Portfolio Detail &rarr;</a>
                  </div>

                  <!-- Dynamic Graph filtering -->
                  <% d_nodes = Enum.filter(@nodes, & @selected_domain in &1.domains) %>
                  <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div class="p-3 bg-slate-950 border border-slate-900 rounded-lg text-xs">
                      <span class="text-[9px] uppercase font-bold text-slate-500 font-mono block mb-1">Validated Discoveries</span>
                      <strong class="text-slate-200 text-base font-mono"><%= Enum.count(Enum.filter(d_nodes, & &1.type == :discovery)) %></strong>
                    </div>
                    <div class="p-3 bg-slate-950 border border-slate-900 rounded-lg text-xs">
                      <span class="text-[9px] uppercase font-bold text-slate-500 font-mono block mb-1">Active Theories</span>
                      <strong class="text-slate-200 text-base font-mono"><%= Enum.count(Enum.filter(d_nodes, & &1.type == :theory)) %></strong>
                    </div>
                    <div class="p-3 bg-slate-950 border border-slate-900 rounded-lg text-xs">
                      <span class="text-[9px] uppercase font-bold text-slate-500 font-mono block mb-1">Interventions Mapped</span>
                      <strong class="text-emerald-400 text-base font-mono"><%= Enum.count(Enum.filter(d_nodes, & &1.type == :intervention)) %></strong>
                    </div>
                  </div>

                  <div class="flex flex-col gap-3 mt-1">
                    <span class="text-xs font-bold text-slate-300 font-heading">Applicable Knowledge Nodes</span>
                    <%= for node <- d_nodes do %>
                      <div class="p-3 bg-slate-900/60 border border-slate-850 rounded-lg text-xs flex justify-between items-center">
                        <div>
                          <strong class="text-slate-200"><%= node.name %></strong>
                          <p class="text-[11px] text-slate-400 mt-0.5"><%= node.description %></p>
                        </div>
                        <span class="text-[9px] font-mono px-2 py-0.5 rounded bg-slate-800 text-slate-400 uppercase font-semibold"><%= node.type %></span>
                      </div>
                    <% end %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>

      <% else %>
        <!-- TAB 2: KNOWLEDGE FLOW VISUALIZER -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 items-start">
          
          <!-- Left side: Select Discovery to map flow -->
          <div class="flex flex-col gap-4">
            <h3 class="text-sm font-bold text-slate-300 font-heading">Select Discovery to Trace Flow</h3>
            <div class="flex flex-col gap-2">
              <%= for disc <- @discoveries do %>
                <button 
                  phx-click="select_discovery" 
                  phx-value-id={disc.id} 
                  class={"p-3 rounded-lg border text-left cursor-pointer transition-all " <>
                    if(to_string(@selected_discovery.id) == to_string(disc.id), do: "bg-indigo-600/10 border-indigo-500/40 font-bold", else: "bg-slate-900/40 border-slate-800")
                  }
                >
                  <div class="flex justify-between items-center mb-1 text-xs">
                    <span class="text-slate-200"><%= disc.name %></span>
                    <span class="text-[9px] font-mono text-purple-400 bg-purple-500/10 px-1.5 py-0.25 rounded border border-purple-500/20 uppercase">DISC</span>
                  </div>
                  <p class="text-[10px] text-slate-400 line-clamp-1"><%= disc.description %></p>
                </button>
              <% end %>

              <%= for law <- @laws do %>
                <button 
                  phx-click="select_discovery" 
                  phx-value-id={law.id} 
                  class={"p-3 rounded-lg border text-left cursor-pointer transition-all " <>
                    if(to_string(@selected_discovery.id) == to_string(law.id), do: "bg-indigo-600/10 border-indigo-500/40 font-bold", else: "bg-slate-900/40 border-slate-800")
                  }
                >
                  <div class="flex justify-between items-center mb-1 text-xs">
                    <span class="text-slate-200"><%= law.name %></span>
                    <span class="text-[9px] font-mono text-emerald-400 bg-emerald-500/10 px-1.5 py-0.25 rounded border border-emerald-500/20 uppercase">LAW</span>
                  </div>
                  <p class="text-[10px] text-slate-400 line-clamp-1"><%= law.description %></p>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Flow Chart cascade visualization -->
          <div class="lg:col-span-2 flex flex-col gap-6">
            <%= if @selected_discovery do %>
              <% 
                # Collect Impacted domains
                impacted_domains = Enum.map(@selected_discovery.domains || [], &CanonicalRegistry.get/1) |> Enum.reject(&is_nil/1)
                
                # Fetch children interventions
                disc_id_str = to_string(@selected_discovery.id)
                child_interventions = Enum.filter(@interventions, fn i -> 
                  disc_id_str in Enum.map(i.parents || [], &to_string/1)
                end)

                # Fetch downstream outcomes
                int_ids = Enum.map(child_interventions, &to_string(&1.id))
                outcomes_produced = Enum.filter(@outcomes, fn o -> 
                  Enum.any?(o.parents || [], &(to_string(&1) in int_ids))
                end)
              %>

              <div class="p-6 bg-slate-950 border border-slate-850 rounded-xl flex flex-col gap-8">
                <!-- Node Header Info -->
                <div class="border-b border-slate-900 pb-3 flex justify-between items-start">
                  <div>
                    <span class="text-[9px] uppercase font-bold text-indigo-400 font-mono">Cascade Root</span>
                    <h2 class="text-lg font-bold text-slate-100 font-heading mt-1"><%= @selected_discovery.name %></h2>
                    <p class="text-xs text-slate-400"><%= @selected_discovery.description %></p>
                  </div>
                  <span class="text-[10px] font-mono text-slate-500">Source: Replay Tensor</span>
                </div>

                <!-- Step 1: Discovery Block -->
                <div class="flex flex-col md:flex-row items-center gap-4">
                  <div class="p-4 bg-purple-500/10 border border-purple-500/30 rounded-lg text-center w-full md:w-1/3">
                    <span class="text-[8px] uppercase font-bold text-purple-400 font-mono block">1. Discovery</span>
                    <span class="text-xs text-slate-200 font-bold block mt-1"><%= @selected_discovery.name %></span>
                  </div>
                  
                  <div class="text-slate-500 text-lg font-bold rotate-90 md:rotate-0">&rarr;</div>

                  <!-- Step 2: Domains Impacted -->
                  <div class="p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg w-full md:w-2/3 flex flex-col gap-2">
                    <span class="text-[8px] uppercase font-bold text-blue-400 font-mono block text-center md:text-left">2. Domains Impacted</span>
                    <div class="flex flex-wrap gap-1.5 justify-center md:justify-start">
                      <%= for dom <- impacted_domains do %>
                        <span class="bg-slate-900 text-slate-300 border border-slate-800 px-2 py-0.5 rounded text-[10px] font-mono"><%= dom.name %></span>
                      <% end %>
                    </div>
                  </div>
                </div>

                <div class="flex justify-center text-slate-500 text-lg font-bold rotate-90">&rarr;</div>

                <!-- Step 3: Interventions Generated -->
                <div class="flex flex-col md:flex-row items-center gap-4">
                  <div class="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-lg w-full md:w-2/3 flex flex-col gap-2">
                    <span class="text-[8px] uppercase font-bold text-emerald-400 font-mono block text-center md:text-left">3. Interventions Generated</span>
                    <%= if Enum.empty?(child_interventions) do %>
                      <span class="text-xs text-slate-500 italic font-mono block">None mapped. Evolving context.</span>
                    <% else %>
                      <%= for int <- child_interventions do %>
                        <div class="p-2 bg-slate-900/40 rounded border border-slate-800 text-[11px] text-slate-300">
                          <strong><%= int.name %></strong>
                          <p class="text-[10px] text-slate-400 mt-0.5"><%= int.description %></p>
                        </div>
                      <% end %>
                    <% end %>
                  </div>

                  <div class="text-slate-500 text-lg font-bold rotate-90 md:rotate-0">&rarr;</div>

                  <!-- Step 4: Outcomes Produced -->
                  <div class="p-4 bg-amber-500/10 border border-amber-500/30 rounded-lg w-full md:w-1/3 flex flex-col gap-2 text-center">
                    <span class="text-[8px] uppercase font-bold text-amber-400 font-mono block">4. Outcomes Produced</span>
                    <%= if Enum.empty?(outcomes_produced) do %>
                      <span class="text-xs text-slate-500 italic font-mono block">No outcomes evaluated.</span>
                    <% else %>
                      <%= for out <- outcomes_produced do %>
                        <strong class="text-amber-400 text-xs font-mono block"><%= out.name %></strong>
                        <span class="text-[9px] text-slate-400 block"><%= out.description %></span>
                      <% end %>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("select_domain", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_domain: String.to_atom(id))}
  end

  def handle_event("select_discovery", %{"id" => id}, socket) do
    nodes = socket.assigns.nodes
    disc = Enum.find(nodes, & to_string(&1.id) == id)
    {:noreply, assign(socket, selected_discovery: disc)}
  end

  def handle_event("run_query", %{"qid" => qid}, socket) do
    nodes = socket.assigns.nodes
    
    {question, results} = 
      case qid do
        "rob" -> 
          {"Which discoveries influenced robotics?",
           Enum.filter(nodes, fn n -> n.type == :discovery and :robotics in n.domains end)}
        "med" -> 
          {"Which laws support medicine?",
           Enum.filter(nodes, fn n -> n.type == :law and :medicine in n.domains end)}
        "eng" -> 
          {"Which constitutions maximize engineering resilience?",
           Enum.filter(nodes, fn n -> n.type == :law and :engineering in n.domains end)}
        "ene" -> 
          {"Which worlds produced discoveries relevant to energy?",
           Enum.filter(nodes, fn n -> n.type in [:discovery, :law] and :energy in n.domains end)}
        _ -> 
          {nil, nil}
      end

    {:noreply, assign(socket, query_question: question, query_results: results)}
  end
end
