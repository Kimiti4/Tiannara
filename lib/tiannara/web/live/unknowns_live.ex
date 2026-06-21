defmodule TiannaraWeb.UnknownsLive do
  @moduledoc """
  Displays and registers known unknowns.
  """
  use Phoenix.LiveView

  alias Tiannara.Discoveries.Unknown

  def mount(_params, _session, socket) do
    unknowns = Unknown.all()
    {:ok, assign(socket, unknowns: unknowns, question: "", confidence: "low", importance: "medium", blocking_phase: "")}
  end

  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 grid-cols-3 gap-6">
      <div class="glass-card p-6 flex flex-col gap-4 col-span-2">
        <div class="border-b border-slate-700 pb-2">
          <h1 class="text-2xl font-bold text-amber-400 font-heading">Known Unknowns</h1>
          <p class="text-xs text-slate-400 mt-1">Gaps in scientific knowledge that limit system predictability and run optimization.</p>
        </div>

        <div class="flex flex-col gap-4">
          <%= for un <- @unknowns do %>
            <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-center">
              <div>
                <span class="text-xs text-amber-400 font-mono font-bold">[Blocking: <%= un.blocking_phase || "None" %>]</span>
                <p class="text-sm text-slate-100 font-semibold mt-1"><%= un.question %></p>
                <div class="flex gap-4 text-[10px] text-slate-500 mt-2 font-mono">
                  <span>Confidence: <strong class="text-slate-400"><%= un.confidence %></strong></span>
                  <span>Importance: <strong class="text-slate-400"><%= un.importance %></strong></span>
                </div>
              </div>
              <div>
                <span class="text-xs px-2.5 py-1 rounded bg-amber-500/10 text-amber-400 border border-amber-500/20 font-semibold uppercase">
                  <%= un.importance %> Priority
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Add New Unknown Form -->
      <div class="glass-card p-6 flex flex-col gap-4">
        <h2 class="text-xl font-bold text-slate-100 font-heading">Submit Research Debt</h2>
        <form phx-submit="save" class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Question / Gap Description</label>
            <input type="text" name="question" value={@question} placeholder="e.g., What is the critical threshold for identity drift?" required 
              class="p-2.5 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none focus:border-blue-500"/>
          </div>

          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Current Confidence</label>
            <select name="confidence" class="p-2 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none">
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
            </select>
          </div>

          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Importance</label>
            <select name="importance" class="p-2 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none">
              <option value="low">Low</option>
              <option value="medium">Medium</option>
              <option value="high">High</option>
            </select>
          </div>

          <div class="flex flex-col gap-1">
            <label class="text-xs text-slate-400 font-semibold">Blocking Phase / Milestone</label>
            <input type="text" name="blocking_phase" value={@blocking_phase} placeholder="e.g., Phase 11.7" 
              class="p-2.5 bg-slate-900 border border-slate-700 rounded text-slate-100 text-sm focus:outline-none focus:border-blue-500"/>
          </div>

          <button type="submit" class="mt-2 bg-amber-600 hover:bg-amber-500 text-white font-bold py-2 px-4 rounded text-sm cursor-pointer transition-colors">
            Record Unknown
          </button>
        </form>
      </div>
    </div>
    """
  end

  def handle_event("save", params, socket) do
    %{"question" => q, "confidence" => c, "importance" => imp, "blocking_phase" => bp} = params

    unknown = %Unknown{
      id: "un_" <> UUID.uuid4(),
      question: q,
      confidence: String.to_atom(c),
      importance: String.to_atom(imp),
      blocking_phase: bp
    }

    case Unknown.save(unknown) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Successfully recorded unknown!")
         |> assign(unknowns: Unknown.all(), question: "", blocking_phase: "")}
      _ ->
        {:noreply, put_flash(socket, :error, "Failed to save.")}
    end
  end
end
