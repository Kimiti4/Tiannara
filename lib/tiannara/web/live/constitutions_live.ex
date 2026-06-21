defmodule TiannaraWeb.ConstitutionsLive do
  @moduledoc """
  Constitutional Observatory displaying active constraint genomes.
  """
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    constitutions = [
      %{
        id: "con_1",
        family: "Phoenix",
        gamma: 0.932,
        rho: 3.35,
        alpha_gain: 0.24,
        tau: 0.374,
        resilience: 0.78,
        description: "Metaplastic constraint governor developed in REA-7O. Dynamically shifts constraints to lower thermodynamic cost."
      },
      %{
        id: "con_2",
        family: "Settler",
        gamma: 0.985,
        rho: 5.00,
        alpha_gain: 0.50,
        tau: 1.000,
        resilience: 0.72,
        description: "Fetishist hardcoded regime focusing strictly on local node restoration without global path optimization."
      }
    ]
    {:ok, assign(socket, constitutions: constitutions)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
          Constitutional Observatory
        </h1>
        <p class="text-xs text-slate-400 mt-1">Evolving thermodynamic constraint genomes (persistence, plasticity, and boundary coefficients).</p>
      </div>

      <div class="flex flex-col gap-4">
        <%= for con <- @constitutions do %>
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-3">
            <div class="flex justify-between items-center">
              <div>
                <h3 class="font-bold text-slate-100 text-lg"><%= con.family %> Governor</h3>
                <p class="text-xs text-slate-400 mt-1"><%= con.description %></p>
              </div>
              <div class="text-right">
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Resilience Score</span>
                <span class="text-xl font-extrabold text-emerald-400 font-heading"><%= con.resilience %></span>
              </div>
            </div>

            <div class="grid grid-cols-4 gap-4 mt-2 text-xs font-mono bg-slate-950 p-3 rounded border border-slate-800">
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Gamma (Persistence)</span>
                <span class="text-slate-200 font-bold"><%= con.gamma %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Rho (Threshold)</span>
                <span class="text-slate-200 font-bold"><%= con.rho %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Alpha Gain</span>
                <span class="text-slate-200 font-bold"><%= con.alpha_gain %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Tau (Plasticity)</span>
                <span class="text-slate-200 font-bold"><%= con.tau %></span>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
