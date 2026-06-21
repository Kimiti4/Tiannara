defmodule TiannaraWeb.WorldsLive do
  @moduledoc """
  Displays the active civilization worlds intelligence feed.
  """
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    worlds = [
      %{
        id: "world_a",
        name: "World A (Baseline)",
        dcr: 1.0,
        fri: 0.672,
        iri: 0.738,
        tps: 0.262,
        trh: 11,
        ee: 0.000000,
        status: :active
      },
      %{
        id: "world_b",
        name: "World B (Fetishist)",
        dcr: 1.0,
        fri: 0.528,
        iri: 0.838,
        tps: 0.162,
        trh: 2,
        ee: 0.000000,
        status: :active
      },
      %{
        id: "world_c",
        name: "World C (Cyber-Anneal)",
        dcr: 1.0,
        fri: 0.730,
        iri: 0.802,
        tps: 0.198,
        trh: 1,
        ee: 0.001952,
        status: :active
      },
      %{
        id: "world_d",
        name: "World D (Open-Loop)",
        dcr: 1.0,
        fri: 0.490,
        iri: 0.702,
        tps: 0.298,
        trh: 1,
        ee: 0.000346,
        status: :active
      }
    ]
    {:ok, assign(socket, worlds: worlds)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
          World Intelligence Feed
        </h1>
        <p class="text-xs text-slate-400 mt-1">Active simulated civilization timelines modulated by REA-7O Metaplastic Governance.</p>
      </div>

      <div class="grid grid-cols-1 grid-cols-2 gap-6">
        <%= for world <- @worlds do %>
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-3">
            <div class="flex justify-between items-center border-b border-slate-800 pb-2">
              <h3 class="font-bold text-slate-100 text-lg"><%= world.name %></h3>
              <span class="text-xs px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-semibold uppercase">
                <%= world.status %>
              </span>
            </div>

            <div class="grid grid-cols-3 gap-4 text-xs font-mono">
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Survival (DCR)</span>
                <span class="text-slate-200 font-bold"><%= Float.round(world.dcr, 2) %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Functional Retention (FRI)</span>
                <span class="text-slate-200 font-bold"><%= Float.round(world.fri, 3) %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Identity Similarity (IRI)</span>
                <span class="text-slate-200 font-bold"><%= Float.round(world.iri, 3) %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Path Speed (TPS)</span>
                <span class="text-slate-200 font-bold"><%= Float.round(world.tps, 3) %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Recovery Time (TRH)</span>
                <span class="text-slate-200 font-bold"><%= world.trh %> epochs</span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Explo Efficiency (EE)</span>
                <span class="text-slate-200 font-bold"><%= Float.round(world.ee, 6) %></span>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
