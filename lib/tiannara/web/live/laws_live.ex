defmodule TiannaraWeb.LawsLive do
  @moduledoc """
  Displays the Law Registry.
  """
  use Phoenix.LiveView

  alias Tiannara.Discoveries.Discovery

  def mount(_params, _session, socket) do
    laws = 
      Discovery.all()
      |> Enum.filter(fn d -> d.status in [:candidate_law, :supported_law, :validated] end)

    {:ok, assign(socket, laws: laws)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-blue-400 font-heading">Law Registry</h1>
        <p class="text-xs text-slate-400 mt-1">Formalized systemic principles backed by simulated and operational runs evidence.</p>
      </div>

      <div class="flex flex-col gap-4">
        <%= for law <- @laws do %>
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg">
            <div class="flex justify-between items-center">
              <div class="flex items-center gap-2">
                <h3 class="font-bold text-slate-100 text-lg"><%= law.name %></h3>
                <span class={"text-xs px-2 py-0.5 rounded font-semibold uppercase " <>
                  case law.status do
                    :validated -> "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                    :supported_law -> "bg-blue-500/10 text-blue-400 border border-blue-500/20"
                    _ -> "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20"
                  end
                }>
                  <%= law.status %>
                </span>
              </div>
              <span class="text-xs text-slate-500 font-mono">Confidence: <%= Float.round(law.confidence * 100, 1) %>%</span>
            </div>

            <p class="text-sm text-slate-300 mt-2 font-mono bg-slate-950 p-3 rounded border border-slate-800"><%= law.claim %></p>

            <div class="flex justify-between items-center mt-3 text-xs text-slate-500">
              <div class="flex gap-4">
                <span>Worlds Evidence: <strong class="text-slate-300"><%= law.worlds_evidence %></strong></span>
                <span>Operational Runs: <strong class="text-slate-300"><%= law.operational_runs_evidence %></strong></span>
              </div>
              <div class="flex gap-4">
                <span>Sci Impact: <%= Float.round(law.scientific_impact * 100, 0) %>%</span>
                <span>Op Impact: <%= Float.round(law.operational_impact * 100, 0) %>%</span>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
