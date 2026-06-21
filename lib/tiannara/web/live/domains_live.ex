defmodule TiannaraWeb.DomainsLive do
  @moduledoc """
  Displays the 20 Tiannara Research Domains with dynamic portfolio vectors and composite Knowledge Capital.
  """
  use Phoenix.LiveView

  alias Tiannara.Domains.Registry, as: DomReg

  def mount(_params, _session, socket) do
    domains = DomReg.all()

    # Precompute portfolio vectors and knowledge capital to keep render clean
    domain_data = Enum.map(domains, fn dom ->
      vector = DomReg.get_portfolio_vector(dom.id)
      capital = DomReg.get_knowledge_capital(dom.id)
      %{
        dom: dom,
        vector: vector,
        capital: capital
      }
    end)

    {:ok, assign(socket, domain_data: domain_data)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2 flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <h1 class="text-2xl font-bold text-indigo-400 font-heading">Research Domains Registry</h1>
          <p class="text-xs text-slate-400 mt-1">First-class scientific research lenses measuring discovery yields and cross-domain innovation.</p>
        </div>
        <div class="text-xs text-slate-500 font-mono">
          Total Portfolios: <strong class="text-slate-300">20</strong>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <%= for item <- @domain_data do %>
          <% dom = item.dom %>
          <% vec = item.vector %>
          <div class="p-5 bg-slate-900/50 border border-slate-800 rounded-xl hover:border-indigo-500/25 transition-all flex flex-col justify-between gap-4">
            <div>
              <div class="flex justify-between items-center mb-1">
                <h3 class="font-bold text-slate-200 text-base font-heading">
                  <a href={"/domain/#{dom.id}"} class="hover:text-indigo-400 transition-colors">
                    <%= dom.name %>
                  </a>
                </h3>
                <span class={"text-[9px] px-1.5 py-0.5 rounded font-mono font-semibold uppercase " <> 
                  if(dom.status == :active, do: "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20", else: "bg-slate-800 text-slate-500 border border-slate-750")
                }>
                  <%= dom.status %>
                </span>
              </div>
              <p class="text-xs text-slate-400 leading-normal min-h-[36px]"><%= dom.description %></p>
            </div>

            <!-- Dynamic Portfolio Metrics -->
            <div class="grid grid-cols-3 gap-2 text-center text-xs font-mono bg-slate-950 p-2.5 rounded border border-slate-900">
              <div>
                <span class="block text-[8px] text-slate-500 uppercase font-semibold">Discovery Pwr</span>
                <span class="text-slate-200 font-bold"><%= Float.round(vec.discovery_power, 0) %></span>
              </div>
              <div>
                <span class="block text-[8px] text-slate-500 uppercase font-semibold">Intervention</span>
                <span class="text-emerald-400 font-bold"><%= Float.round(vec.intervention_power * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[8px] text-slate-500 uppercase font-semibold">Transferability</span>
                <span class="text-blue-400 font-bold"><%= Float.round(vec.transferability * 100, 0) %>%</span>
              </div>
            </div>

            <!-- Extra Metrics & Composite Cap -->
            <div class="flex justify-between items-center text-[10px] font-mono border-t border-slate-850 pt-2 text-slate-500">
              <div>
                Unresolved Unknowns: <strong class="text-rose-400"><%= Float.round(vec.research_debt, 0) %></strong>
              </div>
              <div class="flex items-center gap-1">
                <span>Knowledge Capital:</span>
                <strong class="text-indigo-400 font-bold text-xs bg-indigo-500/10 px-1.5 py-0.5 rounded border border-indigo-500/20"><%= item.capital %></strong>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
