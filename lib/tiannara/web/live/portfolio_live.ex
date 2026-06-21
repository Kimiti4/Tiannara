defmodule TiannaraWeb.PortfolioLive do
  @moduledoc """
  Displays the trajectory family rankings and optionality metrics.
  """
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    # Load ranks from json
    file_path = "data/archive/rea_generativity_trajectory_tensor.json"
    
    ranks =
      if File.exists?(file_path) do
        case File.read(file_path) |> IO.inspect() do
          {:ok, content} ->
            case Jason.decode(content, keys: :atoms) do
              {:ok, %{results: results}} ->
                # Group by family and find max gsi
                results
                |> Enum.group_by(& &1.family)
                |> Enum.map(fn {family, items} ->
                  max_item = Enum.max_by(items, & &1.gsi)
                  avg_gsi = Enum.sum(Enum.map(items, & &1.gsi)) / length(items)
                  %{
                    family: to_string(family),
                    max_gsi: max_item.gsi,
                    avg_gsi: avg_gsi,
                    coordinates: max_item.coordinates,
                    count: length(items)
                  }
                end)
                |> Enum.sort_by(& &1.max_gsi, :desc)
              _ ->
                default_ranks()
            end
          _ ->
            default_ranks()
        end
      else
        default_ranks()
      end

    {:ok, assign(socket, ranks: ranks)}
  end

  def render(assigns) do
    ~H"""
    <div class="glass-card p-6 flex flex-col gap-6">
      <div class="border-b border-slate-700 pb-2">
        <h1 class="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-indigo-400 font-heading">
          Discovery Portfolio Ranks
        </h1>
        <p class="text-xs text-slate-400 mt-1">Multi-physics trajectory families ranked by their Generativity Survival Index (GSI).</p>
      </div>

      <div class="flex flex-col gap-4">
        <%= for {rank, item} <- Enum.with_index(@ranks, 1) do %>
          <div class="p-4 bg-slate-900 border border-slate-800 rounded-lg flex justify-between items-center">
            <div class="flex items-center gap-4">
              <span class="text-2xl font-extrabold text-slate-500 font-mono">#0<%= rank %></span>
              <div>
                <h3 class="font-bold text-slate-100 text-lg"><%= item.family %> Family</h3>
                <div class="flex gap-4 text-xs text-slate-400 mt-1 font-mono">
                  <span>Coordinates: 
                    C: <strong class="text-slate-200"><%= Float.round(item.coordinates[:C], 3) %></strong> | 
                    H: <strong class="text-slate-200"><%= Float.round(item.coordinates[:H], 3) %></strong> | 
                    I: <strong class="text-slate-200"><%= Float.round(item.coordinates[:I], 3) %></strong> | 
                    T: <strong class="text-slate-200"><%= Float.round(item.coordinates[:T], 3) %></strong>
                  </span>
                </div>
              </div>
            </div>

            <div class="text-right flex gap-6 items-center">
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Max GSI</span>
                <span class="text-xl font-extrabold text-emerald-400 font-heading"><%= Float.round(item.max_gsi, 4) %></span>
              </div>
              <div>
                <span class="block text-[10px] uppercase text-slate-500 font-semibold">Avg GSI</span>
                <span class="text-lg font-bold text-slate-300 font-heading"><%= Float.round(item.avg_gsi, 4) %></span>
              </div>
              <div class="text-slate-600 text-xs">
                <%= item.count %> samples
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp default_ranks do
    [
      %{family: "Phoenix", max_gsi: 0.7807, avg_gsi: 0.3118, coordinates: %{C: 0.7585, H: 0.8627, I: 0.9977, T: 0.2942}, count: 120},
      %{family: "Settler", max_gsi: 0.7776, avg_gsi: 0.2995, coordinates: %{C: 0.2195, H: 0.7134, I: 0.1538, T: 0.7838}, count: 110},
      %{family: "Survivor", max_gsi: 0.7658, avg_gsi: 0.2854, coordinates: %{C: 0.1697, H: 0.9742, I: 0.0901, T: 0.9721}, count: 100},
      %{family: "Trader", max_gsi: 0.7617, avg_gsi: 0.2785, coordinates: %{C: 0.9036, H: 0.2038, I: 0.7738, T: 0.9244}, count: 90},
      %{family: "Explorer", max_gsi: 0.7583, avg_gsi: 0.2642, coordinates: %{C: 0.3811, H: 0.8029, I: 0.7981, T: 0.3853}, count: 80}
    ]
  end
end
