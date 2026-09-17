defmodule ReplayStore.ReplayCache do
  use GenServer

  @hot_max 100
  @warm_max 500

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def put(key, value) do
    GenServer.cast(__MODULE__, {:put, key, value})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def init(_opts) do
    {:ok, %{hot: %{}, warm: %{}, cold: %{}, hits: 0, misses: 0, access_log: %{}}}
  end

  @impl true
  def handle_call(
        {:get, key},
        _from,
        %{hot: h, warm: w, cold: c, hits: hits, misses: misses, access_log: log} = state
      ) do
    cond do
      Map.has_key?(h, key) ->
        updated = log_access(log, key)

        {:reply, {:ok, :hot, h[key]},
         %{state | hits: hits + 1, access_log: updated, hot: promote(h, w, c, key)}}

      Map.has_key?(w, key) ->
        updated = log_access(log, key)
        value = w[key]

        {:reply, {:ok, :warm, value},
         %{
           state
           | hits: hits + 1,
             access_log: updated,
             warm: Map.delete(w, key),
             hot: Map.put(h, key, value) |> trim(:hot, @hot_max)
         }}

      Map.has_key?(c, key) ->
        updated = log_access(log, key)
        value = c[key]

        {:reply, {:ok, :cold, value},
         %{
           state
           | hits: hits + 1,
             access_log: updated,
             cold: Map.delete(c, key),
             warm: Map.put(w, key, value) |> trim(:warm, @warm_max)
         }}

      true ->
        {:reply, {:miss, :not_found}, %{state | misses: misses + 1}}
    end
  end

  @impl true
  def handle_call(:stats, _from, %{hits: hits, misses: misses, hot: h, warm: w, cold: c} = state) do
    total = hits + misses
    hit_rate = if total > 0, do: Float.round(hits / total * 100, 2), else: 0.0

    {:reply,
     %{
       hits: hits,
       misses: misses,
       total: total,
       hit_rate: hit_rate,
       hot_size: map_size(h),
       warm_size: map_size(w),
       cold_size: map_size(c)
     }, state}
  end

  @impl true
  def handle_cast({:put, key, value}, %{hot: h} = state) do
    {:noreply, %{state | hot: Map.put(h, key, value) |> trim(:hot, @hot_max)}}
  end

  defp trim(map, _tier, max) when map_size(map) <= max, do: map

  defp trim(map, _tier, max) do
    map
    |> Enum.sort_by(fn {_, v} -> v[:accessed_at] || 0 end, :asc)
    |> Enum.drop(max)
    |> Map.new()
  end

  defp promote(hot, warm, cold, key) do
    value = Map.get(warm, key) || Map.get(cold, key)

    if value do
      Map.put(hot, key, value)
    else
      hot
    end
  end

  defp log_access(log, key) do
    Map.put(log, key, DateTime.utc_now())
    |> then(fn l -> if map_size(l) > 1000, do: Enum.take(l, 500) |> Map.new(), else: l end)
  end
end
