defmodule TiannaraWeb.TheoriesLive do
  @moduledoc """
  Displays the Theories Registry with Theory Health indicators.
  """
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    theories = [
      %{
        id: "uncertainty_weighted_governance",
        name: "Uncertainty-Weighted Governance",
        hypothesis: "The optimal institution allocates control dynamically according to uncertainty, shifting authority from strict managerial protocols to metaplastic governors as environmental unpredictability rises.",
        laws: [],
        supports: ["REA-7O Crucible", "REA-7P Closure", "Governance Genome Switch", "Graduated Trust"],
        architectural_impact: ["REA-2 promotion logic", "Proposal gating", "Constitutional control bounds"],
        status: :active,
        health: %{
          evidence_strength: 0.88,
          contradiction_pressure: 0.05,
          operational_support: 0.15,
          research_debt: "Low"
        }
      },
      %{
        id: "adaptive_memory_ecology",
        name: "Adaptive Memory Ecology",
        hypothesis: "Peak generativity occurs at intermediate levels of retention because structured forgetting allows possibility spaces to adapt.",
        laws: ["structured_forgetting"],
        supports: ["Generativity Physics"],
        architectural_impact: ["Decay rates"],
        status: :active,
        health: %{
          evidence_strength: 0.82,
          contradiction_pressure: 0.12,
          operational_support: 0.10,
          research_debt: "Medium"
        }
      },
      %{
        id: "regenerative_governance",
        name: "Regenerative Governance",
        hypothesis: "Civilization structures regenerate adaptively when topological network redundancy is kept above the recovery threshold.",
        laws: ["scp_retention_boundary"],
        supports: ["Constitutional Navigation"],
        architectural_impact: ["Path limits"],
        status: :hypothetical,
        health: %{
          evidence_strength: 0.90,
          contradiction_pressure: 0.08,
          operational_support: 0.20,
          research_debt: "Low"
        }
      }
    ]
    {:ok, assign(socket, theories: theories)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-indigo-400 font-heading">Theory Explorer</h1>
        <p class="text-xs text-slate-400 mt-1">High-level meta-hypotheses synthesizing multiple physical and architectural laws.</p>
      </div>

      <div class="flex flex-col gap-6">
        <%= for th <- @theories do %>
          <div class="p-5 bg-slate-900 border border-slate-800 rounded-lg flex flex-col gap-4">
            <div class="flex justify-between items-center">
              <h3 class="font-bold text-slate-100 text-lg"><%= th.name %></h3>
              <span class={"text-xs px-2.5 py-1 rounded font-semibold uppercase " <>
                case th.status do
                  :active -> "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                  _ -> "bg-amber-500/10 text-amber-400 border border-amber-500/20"
                end
              }>
                <%= th.status %>
              </span>
            </div>

            <p class="text-sm text-slate-300 leading-relaxed font-mono bg-slate-950 p-3.5 rounded border border-slate-850"><%= th.hypothesis %></p>

            <!-- Health Indicator Section -->
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs font-mono bg-slate-900/60 p-3 rounded border border-slate-800">
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Evidence Strength</span>
                <span class="text-emerald-400 font-bold"><%= Float.round(th.health.evidence_strength * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Contradiction Pressure</span>
                <span class="text-rose-400 font-bold"><%= Float.round(th.health.contradiction_pressure * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Operational Support</span>
                <span class="text-slate-300 font-bold"><%= Float.round(th.health.operational_support * 100, 0) %>%</span>
              </div>
              <div>
                <span class="block text-[9px] uppercase text-slate-500 font-semibold">Research Debt</span>
                <span class="text-slate-300 font-bold"><%= th.health.research_debt %></span>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold mb-1">Supports Artifacts</span>
                <div class="flex flex-wrap gap-1.5">
                  <%= for sup <- th.supports do %>
                    <span class="bg-indigo-500/10 text-indigo-400 border border-indigo-500/10 px-2 py-0.5 rounded text-[10px]"><%= sup %></span>
                  <% end %>
                </div>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold mb-1">Architectural Impact</span>
                <div class="flex flex-wrap gap-1.5">
                  <%= for imp <- th.architectural_impact do %>
                    <span class="bg-blue-500/10 text-blue-400 border border-blue-500/10 px-2 py-0.5 rounded text-[10px]"><%= imp %></span>
                  <% end %>
                </div>
              </div>
            </div>

            <%= if not Enum.empty?(th.laws) do %>
              <div class="flex gap-2 items-center text-xs">
                <span class="text-slate-500 font-semibold">Supporting Laws:</span>
                <%= for law <- th.laws do %>
                  <span class="bg-slate-800 text-slate-300 px-2.5 py-0.5 rounded font-mono border border-slate-700"><%= law %></span>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
