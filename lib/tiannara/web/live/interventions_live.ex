defmodule TiannaraWeb.InterventionsLive do
  @moduledoc """
  Displays and manages scientific and architectural interventions.
  """
  use Phoenix.LiveView

  alias Tiannara.REA.Intervention

  def mount(_params, _session, socket) do
    interventions = Intervention.all()
    {:ok, assign(socket, interventions: interventions, proposal_text: "", expected_effect: "", origin_discovery_id: "")}
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 grid-cols-3 gap-6">
      <div class="glass-card p-6 flex flex-col gap-4 col-span-2">
        <div class="border-b border-slate-700 pb-2">
          <h1 class="text-2xl font-bold text-blue-400 font-heading">Intervention Registry</h1>
          <p class="text-xs text-slate-400 mt-1">Actions taken to modulate adaptation constraints and their measured operational outcomes.</p>
        </div>

        <div class="flex flex-col gap-4">
          <%= for int <- @interventions do %>
            <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-center gap-4">
              <div>
                <h3 class="font-bold text-slate-100 text-lg"><%= int.proposal_text %></h3>
                <span class="text-xs text-slate-400 block mt-1">
                  Expected Effect: <strong class="text-slate-300"><%= int.expected_effect %></strong>
                </span>
                <div class="flex gap-4 text-[10px] text-slate-500 mt-2 font-mono">
                  <span>Origin: <%= int.origin_discovery_id || "None" %></span>
                  <span>Confidence: <%= Float.round((int.confidence || 0.0) * 100, 0) %>%</span>
                </div>
              </div>

              <div class="text-right flex flex-col gap-1 items-end">
                <span class={"text-xs px-2 py-0.5 rounded font-semibold uppercase " <>
                  case int.status do
                    :completed -> "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20"
                    :active -> "bg-blue-500/10 text-blue-400 border border-blue-500/20"
                    :proposed -> "bg-indigo-500/10 text-indigo-400 border border-indigo-500/20"
                    _ -> "bg-slate-500/10 text-slate-400 border border-slate-500/20"
                  end
                }>
                  <%= int.status %>
                </span>
                <%= if int.actual_effect do %>
                  <span class="text-sm text-emerald-400 font-mono font-bold"><%= int.actual_effect %></span>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Add New Intervention Form -->
      <div class="glass-card p-6 flex flex-col gap-4">
        <h2 class="text-xl font-bold text-slate-100 font-heading">Propose Intervention</h2>
        <form phx-submit="save" class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Proposal / Action Text</label>
            <input type="text" name="proposal_text" value={@proposal_text} placeholder="e.g., Modulate Specialist Context Retention to 55%" required 
              class="p-2.5 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none focus:border-blue-500"/>
          </div>

          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Expected Operational Effect</label>
            <input type="text" name="expected_effect" value={@expected_effect} placeholder="e.g., DVR +12%" required 
              class="p-2.5 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none focus:border-blue-500"/>
          </div>

          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Associated Discovery ID</label>
            <input type="text" name="origin_discovery_id" value={@origin_discovery_id} placeholder="e.g., structured_forgetting" 
              class="p-2.5 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none focus:border-blue-500"/>
          </div>

          <button type="submit" class="mt-2 bg-blue-600 hover:bg-blue-500 text-white font-bold py-2 px-4 rounded text-sm cursor-pointer transition-colors">
            Register Intervention
          </button>
        </form>
      </div>
    </div>
    """
  end

  def handle_event("save", params, socket) do
    %{"proposal_text" => txt, "expected_effect" => exp, "origin_discovery_id" => disc_id} = params

    intervention = %Intervention{
      id: "int_" <> UUID.uuid4(),
      origin_discovery_id: disc_id,
      origin_law_id: disc_id,
      origin_theory_id: "general_theory",
      proposal_text: txt,
      confidence: 0.80,
      expected_effect: exp,
      actual_effect: nil,
      status: :proposed
    }

    case Intervention.save(intervention) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Intervention proposed successfully!")
         |> assign(interventions: Intervention.all(), proposal_text: "", expected_effect: "", origin_discovery_id: "")}
      _ ->
        {:noreply, put_flash(socket, :error, "Failed to propose.")}
    end
  end
end
