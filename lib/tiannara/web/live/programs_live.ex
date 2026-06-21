defmodule TiannaraWeb.ProgramsLive do
  @moduledoc """
  Displays scientific Research Programs in Tiannara.
  """
  use Phoenix.LiveView

  alias Tiannara.Discoveries.Program

  def mount(_params, _session, socket) do
    programs = Program.all()
    {:ok, assign(socket, programs: programs)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
          Research Programs
        </h1>
        <p class="text-xs text-slate-400 mt-1">High-level research strategies organizing theories, hypotheses, and experiments.</p>
      </div>

      <div class="flex flex-col gap-6">
        <%= for prog <- @programs do %>
          <div class="p-6 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-4">
            <div class="flex justify-between items-start">
              <div>
                <h2 class="text-lg font-bold text-slate-100 font-heading"><%= prog.name %></h2>
                <p class="text-xs text-indigo-400 font-mono mt-1">Goal: <%= prog.goal %></p>
                <p class="text-xs text-slate-400 mt-1">Objective: <%= prog.objective %></p>
              </div>
              <span class={"text-xs px-2.5 py-1 rounded font-semibold uppercase " <>
                case prog.status do
                  :active -> "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                  _ -> "bg-slate-500/10 text-slate-400 border border-slate-500/20"
                end
              }>
                <%= prog.status %>
              </span>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
              <div class="p-3 bg-slate-950 border border-slate-800 rounded-lg">
                <span class="block text-[10px] uppercase text-slate-500 font-semibold mb-2">Hypotheses</span>
                <%= if Enum.empty?(prog.hypotheses) do %>
                  <span class="text-slate-600 font-mono italic">None</span>
                <% else %>
                  <ul class="list-disc list-inside text-slate-300 flex flex-col gap-1">
                    <%= for hyp <- prog.hypotheses do %>
                      <li><%= hyp %></li>
                    <% end %>
                  </ul>
                <% end %>
              </div>

              <div class="p-3 bg-slate-950 border border-slate-800 rounded-lg">
                <span class="block text-[10px] uppercase text-slate-500 font-semibold mb-2">Connected Knowledge Objects</span>
                <div class="flex flex-wrap gap-2">
                  <%= for th <- prog.theories || [] do %>
                    <span class="bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 px-2 py-0.5 rounded font-mono text-[10px]">Theory: <%= th %></span>
                  <% end %>
                  <%= for law <- prog.laws || [] do %>
                    <span class="bg-blue-500/10 text-blue-400 border border-blue-500/20 px-2 py-0.5 rounded font-mono text-[10px]">Law: <%= law %></span>
                  <% end %>
                  <%= for disc <- prog.discoveries || [] do %>
                    <span class="bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 px-2 py-0.5 rounded font-mono text-[10px]">Discovery: <%= disc %></span>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="flex justify-between items-center text-[10px] text-slate-500 border-t border-slate-850 pt-2 font-mono">
              <div class="flex gap-4">
                <span>Interventions: <strong class="text-slate-400"><%= length(prog.interventions || []) %></strong></span>
                <span>Unknowns: <strong class="text-slate-400"><%= length(prog.unknowns || []) %></strong></span>
              </div>
              <div>
                <span>Experiments: <%= Enum.join(prog.experiments || [], ", ") %></span>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
